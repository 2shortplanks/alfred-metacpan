alfred-metacpan
===============

Search [MetaCPAN](http://metacpan.org/) from within
[Alfred](http://www.alfredapp.com/) with as-you-type autocompletion

![video of alfred-metacpan in use](https://dl.dropboxusercontent.com/u/301667/metacpansearchforalfred.gif)

Installation
------------

With Alfred 2 installed, simply [download the latest](https://dl.dropboxusercontent.com/u/301667/alfred-metacpan.alfredworkflow)
and double-click.  Creating and importing Alfred workflows requires the [Alfred Powerpack](http://www.alfredapp.com/powerpack/), a purchased add-on.

Contributing
------------

To run this script at the command line: `SEARCH_QUERY=LWP::UserAgent perl -I fatlib myscript.pl`

To package this workflow: `git archive HEAD --format=zip > alfred-metacpan.alfredworkflow`

Once the package is created, you can double-click it to import it into Alfred.
