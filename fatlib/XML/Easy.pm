=head1 NAME

XML::Easy - XML processing with a clean interface

=head1 SYNOPSIS

	use XML::Easy::NodeBasics qw(xml_element xml_e_attribute);
	use XML::Easy::Text
		qw(xml10_read_document xml10_write_document);

	$element = xml_element("a", { href => "there" }, "there");
	$element = xml10_read_document('<a href="there">there</a>');

	$href = xml_e_attribute($element, "href");
	$text = xml10_write_document($element);

	# see specific modules for many more functions

=head1 DESCRIPTION

L<XML::Easy> is a collection of modules relating to the processing,
parsing, and serialisation of XML data.  It is oriented towards the
use of XML to represent data for interchange purposes, rather than the
use of XML as markup of principally textual data.  It does not perform
any schema processing, and does not interpret DTDs or any other kind
of schema.  It adheres strictly to the XML specification, in all its
awkward details, except for the aforementioned DTDs.

L<XML::Easy> strictly separates the in-program manipulation of XML
data from the processing of the textual form of XML.  This shields
the XML user from the inconvenient and obscure aspects of XML syntax.
XML data nodes are mainly processed in a clean functional style, using
the L<XML::Easy::NodeBasics> module.  In the (very likely) event that
an application requires some more purpose-specific XML data processing
facilities, they are readily built on top of L<XML::Easy::NodeBasics>,
retaining the abstraction from textual XML.

When XML must be handled in textual form, for input and output,
the L<XML::Easy::Text> module supplies a parser and a serialiser.
The interfaces here, too, are functional in nature.

There are other modules for some ancillary aspects of XML processing.

=head1 MODULES

The modules in the L<XML::Easy> distribution are:

=over

=item L<XML::Easy>

This document.  For historical reasons, this can also be loaded as
a module, and (though it is deprecated) some of the functions from
L<XML::Easy::Text> can be imported from here.

=item L<XML::Easy::Classify>

This module provides various type-testing functions, relating to data
types used in the L<XML::Easy> ensemble.  These are mainly intended to be
used to enforce validity of data being processed by XML-related functions.

=item L<XML::Easy::Content>

=item L<XML::Easy::Element>

These are classes used to represent XML data for general manipulation.
Objects of these classes hold the meaningful content of the data,
independent of textual representation.  The data in these nodes cannot
be modified: different data requires new nodes.

=item L<XML::Easy::NodeBasics>

This module supplies functions concerned with the creation, examination,
and other manipulation of XML data nodes (content chunks and elements).
The nodes are dumb data objects, best manipulated using plain functions
such as the ones in this module.

=item L<XML::Easy::Syntax>

This module supplies Perl regular expressions describing the grammar of 
XML 1.0.  This is intended to support doing irregular things with XML,
rather than for normal parsing.

=item L<XML::Easy::Text>

This module supplies functions that parse and serialise XML data as text
according to the XML 1.0 specification.

=back

=head1 OTHER DISTRIBUTIONS

Other CPAN distributions that work with L<XML::Easy> are:

=over

=item L<Test::XML::Easy>

A testing tool, providing L<Test::More>-style functions that check
whether XML nodes are as expected.

=item L<XML::Easy::ProceduralWriter>

Provides a way to construct XML data nodes by procedural code.
Some programmers will find this more comfortable than the functional
style offered by L<XML::Easy::NodeBasics>.

=item L<XML::Easy::SimpleSchemaUtil>

Helps to parse things that are encoded in XML in common ways.

=item C<XML::Easy::Transform::>

This namespace exists to contain modules that perform transformations
on XML documents, or parts thereof, in the form of L<XML::Easy::Element>
and L<XML::Easy::Content> nodes.

=back

=cut

package XML::Easy;

{ use 5.008; }
use warnings;
use strict;

our $VERSION = "0.009";

use parent "Exporter";
our @EXPORT_OK = qw(
	xml10_read_content xml10_read_element
	xml10_read_document xml10_read_extparsedent
	xml10_write_content xml10_write_element
	xml10_write_document xml10_write_extparsedent
);

require XML::Easy::Text;
XML::Easy::Text->VERSION($VERSION);
XML::Easy::Text->import(@EXPORT_OK);

=head1 SEE ALSO

L<XML::Easy::Classify>,
L<XML::Easy::NodeBasics>,
L<XML::Easy::Syntax>,
L<XML::Easy::Text>,
L<http://www.w3.org/TR/REC-xml/>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2008, 2009 PhotoBox Ltd

Copyright (C) 2009, 2010, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
