#!/usr/bin/perl -w
use strict; use FCGI;
use LWP::Simple;
use CGI::Simple;

my $handling_request = 0;
my $exit_requested = 0;
my $count=0;

sub sig_handler {
	exit(0);
}
$SIG{USR1} = \&sig_handler;
$SIG{TERM} = \&sig_handler;
#$SIG{PIPE} = 'IGNORE';


my $browser = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
$browser->timeout(10);
$browser->agent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:33.0) Gecko/20100101 Firefox/33.0');
my $url = 'https://eztv.ag/';

my $request = FCGI::Request();

while ($count<50 && ($handling_request = ($request->Accept() >= 0))) {
    $count++;
    &do_request;
}

sub do_request()
{
my $cgi= new CGI::Simple;

print <<EOF;
Content-Type: text/html

<html>
<head>
    <title>Alternative Eztv RSS Page (show list)</title> 
	<style>
		table { width: 500px; }
		td.show { width: 400px; }
		div.page
		{
			border:1px solid black;
			background:#eee;
			margin:10px;
			padding:10px;
		}
		table, tr, td, th
		{
			padding:1px 5px;
			border-collapse: collapse;
			font-size:12px;
		}

	</style>
</head>
<body>
<div class="page">
<h1>Main Page RSS Feed (latest releases)</h1>
<table border="1">
<tr>
<th>Show</th>
<th>Rss link</th>
<th>Html link</th>
</tr>
<tr>
	<td class="show">Latest releases (all)</td>
	<td><a href=\"/eztv/eztv.pl?id=\"><img src=\"/images/rss.png\" alt=\"rss link\" /></td>
	<td><a href=\"/eztv/eztv.pl?id=&format=html&name=Latest%20Releases\">HTML</td>
	
</tr>

<tr>
	<td class="show">Eztv TVNews RSS</td>
	<td><a href=\"/eztv/eztv.pl?id=tvnews\"><img src=\"/images/rss.png\" alt=\"rss link\" /></td>
	<td><a href=\"/eztv/eztv.pl?id=tvnews&format=html&name=TvNews\">HTML</td>
	
</tr>
</table>


<h1>Alternative eztv RSS feed by shows.</h1>
<table border="1">
<tr>
<th>Show</th>
<th>Rss link</th>
<th>Html link</th>
</tr>
EOF

my $response = $browser->get ( $url);

if($response->is_success &&  $response->content =~ /name="SearchString">(.*?)<\/select>/s)
{

    my $options = $1;
    #print "Result: ".$response->content;
    while($options =~ /<option value="(.*?)">(.*?)<\/option>/gs)
    {
	if($1 ne "")
	{
		print "<tr>
			<td class=\"show\">$2</td> 
			<td><a href=\"/eztv/eztv.pl?id=$1\"><img src=\"/images/rss.png\" alt=\"rss link\" /></td>
			<td><a href=\"/eztv/eztv.pl?id=$1&format=html&name=$2\">HTML</td>
		</tr>\n";

	}
    }
}
else
{
        print "<li>ERROR fetching $url <li>\n";
}
print "</table></div></body></html>\n";
}

exit(0);


