# eztv RSS Feed Generator

This script is designed to parse the eztv website and generate RSS feeds for automatic download via an RSS Downloader.

## Features

  * Drop in Place Install
  * MySQL Cache Backend

## Installation

To install the script, create a new database and MySQL user.

Create a new database for that user and run the ezrss.sql script against it to create the table structure.

Edit eztv.pl and change to include your MySQL details.

__Tip:__ For best performance make sure your webserver is configured to run this as FastCGI or performance will be horrible!
    
## Usage

Visit the eztv_list.pl script in your browser and you will get a list of shows
From there it will give you links to RSS feeds for individual shows.

If you visit eztv.pl with no options on the URL, you will get the first 5 pages of new releases as displayed on the eztv homepage.

## Documentation

You shouldn't need any - Good luck ;).

## Open Source Projects Used

This code is based on the origional work from here: http://tfeserver.be/downloadhtml/eztv_scripts/

## License

The GPL version 3, read it at [http://www.gnu.org/licenses/gpl.txt](http://www.gnu.org/licenses/gpl.txt)

##Contributing

Any help is always welcome, please contact sam [at] infitialis.com and we can discuss any help you would like to give.