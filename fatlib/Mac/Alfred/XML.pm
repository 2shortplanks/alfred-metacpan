package Mac::Alfred::XML;
use base qw(Exporter);

use strict;
use warnings;

use XML::Easy::Text qw(xml10_write_document);
use XML::Easy::NodeBasics qw(xe);

use Carp qw(croak);
use Scalar::Util qw(blessed);
use overload;

our @EXPORT_OK;

=head1 NAME

=head1 NAME

Mac::Alfred::XML - create XML for Alfred 2 Workflow Script Filters

=head1 SYNOPSIS

    # simple
    use Mac::Alfred::XML qw(alfred_xml_bytes);
    print alfred_xml_bytes("rod","jane","freddy");

    # complex
    print alfred_xml_bytes([ unique => 1 ], {
       title => "Data::Dumper"
       subtitle => "",
       args => "",
    },
    );

=head1 DESCRIPTION

Creates XML suitable for output from a script filter in Alfred 2.

=head2 Functions

Exported on demand or may be called fully qualified.

=over

=item alfred_xml_bytes( ... )

This takes a list of items that will be rendered out as a byte string containing
XML in alfred's 

This either takes a plain string (in which case it will be used as both
the C<title> and the C<uid>) or a

=over

=item title

The title (the big text) that Alfred will display for this element.  Required.

=item subtitle

The subtitle (the small text under the big text) that Alfred will display
for this element.  Optional.

=item type

=item arg

=item autocomplete

Autocomplete text for this element.  

=item uid

The unique identifier for this element.  If not supplied then the title will
be used.

The uid is used for learning;  Once a user has picked an element next time
the element will be displayed higher in the list.   If you do not want this
behaviour then you should use the 

=back

=cut

sub alfred_xml_bytes { return xml10_write_document(alfred_xml(@_)); }
push @EXPORT_OK, 'alfred_xml_bytes';

=item alfred_xml( ... )

Takes the same arguements as C<alfred_xml_bytes> but returns an
XML::Easy::Element instead of bytes.

=cut

# NOTE: You may be confused why I'm 'needlessly' writing '"$_->{title}"' rather
# than just '$_->{title}' - it's to force stringification of overloaded objects
# being passed in, which XML::Easy won't accept

my $buster = 0;

sub alfred_xml {
    my @args = @_;

    my $unique;

    my $count = 0;
    my @items;
    foreach (@args) {
        # automatically promote things into hashrefs if needed
        $_ = { title => $_ } if !ref || overload::Overloaded($_);

        # check that title makes sense
        croak "argument $count passed was not a hashref or scalar" unless ref eq "HASH";
        croak "Missing 'title' key in argument $count" unless exists $_->{title};
        croak "Zero length 'title' in argument $count" unless length $_->{title};

        # the uid is required, but if one wasn't passed, use the title
        my $uid = (exists $_->{uid} && length $_->{uid}) ? "$_->{uid}" : "$_->{title}";

        # if they passed learning is false, append a unique value to the end
        # of the uuid so alfred can't learn (and re-order) the return values
        if ($unique) {
            $uid .= "-learning-buster-".time."-".$$."-".$buster++;
        }

        # work out what the icon is
        my $icon;
        if (length $_->{icon}) {
            if (!ref $icon) {
                $icon = xe("icon",$_->{icon});
            } else {
                croak "argument $count icon not a plain scalar nor hashref"
                    unless ref $_->{icon} eq "HASH";
                croak "argument $count icon missing 'type' key"
                    unless exists $_->{icon}{type};
                croak "argument $count icon missing 'value' key"
                    unless exists $_->{icon}{value};

                $icon = xe(
                    "icon",
                    { type => "$_->{icon}{type}" },
                    "$_->{icon}{value}",
                );
            }
        }

        # build the XML
        push @items, xe(
            "item",
            {
                uid  => $uid,

                # add the type, arg and autocomplete if they were passed
                ((exists $_->{type})         ? ( type          => "$_->{type}" )         : ()),
                ((exists $_->{arg})          ? ( arg           => "$_->{arg}" )          : ()),
                ((exists $_->{autocomplete}) ? ( autocomplete  => "$_->{autocomplete}" ) : ()),

                # if they passed a valid argument, and it's false or equal to
                # the string "no" (in any case) then emit valid="no", otherwise
                # leave it to the default to be true
                ((exists $_->{valid} && (!$_->{valid} || lc $_->{valid} eq "no"))
                    ? ( valid => "no" ) : ()
                ),
            },
            xe("title", "$_->{title}"),

            # add the subtitle and icon if they exist
            (exists $_->{subtitle} ? xe("subtitle", "$_->{subtitle}") : ()),
            ($icon ? $icon : ()),
        );

        $count++;
    }

    return xe("items",@items);
}
push @EXPORT_OK, 'alfred_xml';

1;

__END__

=back

=head2 How to create Aldred distributions?

One of the problem you have if you install this module is that if you attempt to
distribute your workflow then this library (and its dependancies any other
modules you use) won't be availble on the other computer.  What you need to do
is make sure all the dependancies are shipped within the workflow directory.

So, how do I do this?  First I extract the contents of the C<Script:> section
out into its own file in the workflow folder (I normally call this
C<myscript.pl>)

I then use App::FatPacker to create a C<fatlib> directory containing all the
dependancies with this script:

    # This packages the dependancies we need for the module intofatlib.  It
    # requires App::FatPacker from the CPAN.  It won't work for XS dependancies
    # but that's a bad idea anyway, since they'll probably break next time Apple
    # upgrades its perl
    rm -r fatlib
    fatpack trace --to=/tmp/trace myscript.pl
    fatpack packlists-for `cat /tmp/trace` >/tmp/packlists
    fatpack tree `cat /tmp/packlists`

    # note that some modules that contain XS with Pure Perl fallbacks (for
    # example XML::Easy and Params::Classify) end up in in fatlib/darwin-2level
    # we need to move them up a directory
    rsync -av fatlib/darwin-2level/ fatlib/
    rm -r fatlib/darwin-2level

Then in the C<Script:> section I put this:

    use lib "fatlib";
    do "./myscript.pl";

You can use this same aproach if you use a perlbrew perl and don't normally use
the system perl for anything (which is a really good idea.)  Simply debug your
C<myscript.pl> from the command line using your perlbrew perl and use the same
perl to create the fatlib directory containing the dependancies.

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

Copyright Mark Fowler 2013.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Alfred itself is copyright Running with Crayons Ltd.  Neither Mark
Fowler nor this Perl library is associated with Alfred or
Running with Crayons Ltd.

=head1 BUGS

This module is based on the specification posted to the alfred forums at
L<http://www.alfredforum.com/topic/5-generating-feedback-in-workflows/> as of
2013-04-18.  This specification is evolving, so this software may become out of
date.

Bugs should be reported via this distribution's
CPAN RT queue.  This can be found at
L<https://rt.cpan.org/Dist/Display.html?Mac-Alfred-XML>

You can also address issues by forking this distribution
on github and sending pull requests.  It can be found at
L<http://github.com/2shortplanks/Mac-Alfred-XML>

=head1 SEE ALSO

L<XML::Easy>,
L<http://www.alfredforum.com/topic/5-generating-feedback-in-workflows/>

=cut