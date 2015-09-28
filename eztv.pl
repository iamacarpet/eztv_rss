#!/usr/bin/perl -w
use strict;
use FCGI;
use LWP::Simple;
use CGI::Simple;
use HTML::Entities;
use Date::Manip;
use URI::Escape;
use DBI;
use MIME::Base64;

my $handling_request = 0;
my $exit_requested = 0;
my $count=0;

sub sig_handler {
    #$exit_requested = 1;
    #exit(0) if !$handling_request;
	exit(0);
}
$SIG{USR1} = \&sig_handler;
$SIG{TERM} = \&sig_handler;
#$SIG{PIPE} = 'IGNORE';

Date_Init("TZ=EST");

=for suggestions 

=cut


my $dbi=DBI->connect(
                    "dbi:mysql:dbname;host=localhost",
                    "dbuser",
                    "dbpass",
                    {   
                        RaiseError => 1,
                        PrintWarn=>1
                    });


my $browser = LWP::UserAgent->new;
$browser->timeout(10);
$browser->agent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:33.0) Gecko/20100101 Firefox/33.0');

my $url = 'https://eztv.ag/search/';
my $main_url = 'https://eztv.ag/page_%num%';
my $tvnews_url = 'https://eztv.ag/tvnews/';
my %month = (
    'January'       => "01",
    'February'      => "02",
    'March'         => "03",
    'April'         => "04",
    'May'           => "05",
    'June'          => "06",
    'July'          => "07",
    'August'        => "08",
    'September'     => "09",
    'October'       => "10",
    'November'      => "11",
    'December'      => "12");
        

my $request = FCGI::Request();

while ($count<50 && ($handling_request = ($request->Accept() >= 0))) {
    $count++;
    &do_request;

    $handling_request = 0;
    last if $exit_requested;
    exit if $ENV{'SCRIPT_FILENAME'} && -M $ENV{SCRIPT_FILENAME} < 0; # Autorestart
}

sub do_request()
{
	my $cgi= new CGI::Simple;
	my $format = $cgi->url_param('format');
	my $name = $cgi->url_param('name');

	if($format && $format eq 'html'){
		if(!$name) { $name=""; }
		print "Content-Type: text/html

			<html>
			<head>
			<title>$name - alternative eztv RSS feed .</title>
			<style>
			div.page
			{
border:1px solid black;
background:#eee;
margin:10px;
padding:10px;
			}
		li
		{
			list-style: square inside;
			font-size:12px;
		}
		li.news 
		{
			margin-top:15px;
			font-size:14px;
		}
		</style>
			</head>
			<body>
			<div class=\"page\">
			<h1>$name - alternative eztv RSS feed .</h1>
			";
	}

	else
	{

		print "Content-Type: text/xml

<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
			<rss version=\"2.0\">
			<channel>
			<title>Dynamic rss from eztv.ag search</title>
			<link>http://tfeserver.be</link>
			<ttl>30</ttl>
			<description>EZTV RSS feed for selected show/news</description>
			";
	}

	my $id = $cgi->url_param('id');
	if($id)
	{
		$id=~ s/\W//g;
	}
	else
	{
		$id  = "";
	}

	my $content = "";
	my $sth = $dbi->prepare("select * from eztv where id=? and (now() < adddate(date_fetch, interval 30 minute))");
	$sth->execute($id);

	my $row = $sth->fetchrow_hashref;

	if(!$row)
	{

		my $response;
		if($id eq "")
		{
			for(my $i=0;$i<5;$i++){
				my $url = $main_url;
   				$url=~ s/%num%/$i/;
				$response = $browser->get( $url);
				if($response && $response->is_success){
					$content .= $response->content;
				}
			}
		}
		elsif($id eq "tvnews")
		{
			$response = $browser->get( $tvnews_url);
		}
		else
		{	
			$response = $browser->post ( $url,
					[
					'SearchString' => $id
					]);
		}
		if($response->is_success)
		{
			if($id ne ""){
				$content = $response->content;
			}
			
			$dbi->begin_work();
			my $sql_delete ="delete from eztv where id=?";
			my $sth_delete = $dbi->prepare($sql_delete);
			$sth_delete->execute($id);
			my $id2;
			if ($id eq ""){
				$id2 = 0;
			} else {
				$id2 = $id;
			}
			my $sql_insert = sprintf("insert into eztv (id, date_fetch, content) VALUES(%d, now(), '%s')", $id2, encode_base64($content));
			$dbi->do($sql_insert);
			$dbi->commit();
		} else {
			my $sth2 = $dbi->prepare("select * from eztv where id=?");
			$sth2->execute($id);

			my $row2 = $sth2->fetchrow_hashref;
			if ($row2){
				$content = decode_base64($$row2{'content'});
			}
		}
	}
	else
	{
		$content = decode_base64($$row{'content'});
	}


	if($content ne "")
	{
		$_ = $content;

		if($id eq "tvnews")
		{
			while(/class="tvnews_header".*?href="(.*?)".*?<b>(.*?)<\/b>.*?tvnews_content" align="left">(.*?)<\/td>/sg)
			{
				if($format && $format eq 'html')
				{
					my $title =$2;
					my $link = $1;
					$title =~ s/</&lt/g;
					$title =~ s/>/&gt/g;
					my $news_content =$3;
					$news_content =~ s/</&lt/g;
					$news_content =~ s/>/&gt/g;
					print "<li class=\"news\"><a href=\"$main_url$link\">$title</a> <br /><span class=\"news_content\">$news_content</span></li>\n";
				}
				else
				{
					my $link = $1;
					my $title =$2;
					my $desc = $3;
					$link = decode_entities($link);
					$link=~s/\/tvnews\///;
					print "<item>
						<title><![CDATA[$title]]></title>
						<link><![CDATA[$tvnews_url$link]]></link>
						<description><![CDATA[$desc]]></description>
						</item>";
				}
			}
		}
		else
		{
			my $last_added_on = "";
			my $last_added_on_html = "";
			while(/<tr(.*?)>(.*?)<\/tr>/sg)
			{
				my $tr_attr = $1;
				my $tr_data = $2;
				if($tr_attr !~ /name="hover"/)
				{
					if($tr_data =~ /Added on: <b>(.*?), (.*?), (.*?)</)
					{
						my ($c_day, $c_month, $c_year) = ($1, $2, $3);
						$last_added_on_html = "$c_day, $c_month, $c_year";
						$last_added_on = sprintf "%4d-%02d-%02d 00:00:00", $c_year, $month{$c_month}, $c_day;
						$last_added_on = UnixDate(ParseDate($last_added_on),"%a, %d %b %Y %H:%M:%S GMT" );
					}
				}
				if($tr_data =~ /class="epinfo">(.*?)<\/a>.*?href="(.*?)".*?<\/a>.*?href="(.*?)"/sg)
				{
					if($format && $format eq 'html')
					{
						print "<li>$last_added_on_html - $1 ( <a href=\"$2\">Torrent</a> )</li>\n";
					}
					else
					{
						my $title = $1;
						my $link1 = $2;
						my $link2 = $3;
						my $link;
						$link1 =~ s/&amp;/&/g;
						$link2 =~ s/&amp;/&/g;
						if ($link1 =~ /^magnet\:\?xt.*$/){
								$link = $link1;
						} else{
							if($link2 =~ /^magnet\:\?xt.*$/)
							{
								$link  = $link2;
							}
						}

						print "<item>
							<title><![CDATA[$title]]></title>
							<pubDate>$last_added_on</pubDate>
							<link><![CDATA[$link]]></link>
							<description><![CDATA[$title - $link]]></description>
							</item>";
					}
				}
			}
		}
		if($format && $format eq 'html')
		{
			print "</ul></li></div><p><a href=\"/cgi-bin/eztv_list.pl\">Back to eztv rss feeds</a></p></body></html>\n";
		}
		else
		{
			print "</channel></rss>\n";
		}
	}
	else
	{
		print "ERROR fetching $url - $id\n";
	}
	$request->Finish();
}


