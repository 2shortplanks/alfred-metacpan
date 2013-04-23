=head1 NAME

XML::Easy::Classify - classification of XML-related items

=head1 SYNOPSIS

	use XML::Easy::Classify qw(
		is_xml_name check_xml_name
		is_xml_encname check_xml_encname
		is_xml_chardata check_xml_chardata
		is_xml_attributes check_xml_attributes
		is_xml_content_object check_xml_content_object
		is_xml_content_twine check_xml_content_twine
		is_xml_content check_xml_content
		is_xml_element check_xml_element
	);

	if(is_xml_name($arg)) { ...
	check_xml_name($arg);
	if(is_xml_encname($arg)) { ...
	check_xml_encname($arg);
	if(is_xml_chardata($arg)) { ...
	check_xml_chardata($arg);

	if(is_xml_attributes($arg)) { ...
	check_xml_attributes($arg);

	if(is_xml_content_object($arg)) { ...
	check_xml_content_object($arg);
	if(is_xml_content_twine($arg)) { ...
	check_xml_content_twine($arg);
	if(is_xml_content($arg)) { ...
	check_xml_content($arg);

	if(is_xml_element($arg)) { ...
	check_xml_element($arg);

=head1 DESCRIPTION

This module provides various type-testing functions, relating to data
types used in the L<XML::Easy> ensemble.  These are mainly intended to be
used to enforce validity of data being processed by XML-related functions.

There are two flavours of function in this module.  Functions of the first
flavour only provide type classification, to allow code to discriminate
between argument types.  Functions of the second flavour package up the
most common type of type discrimination: checking that an argument is
of an expected type.  The functions come in matched pairs.

=cut

package XML::Easy::Classify;

{ use 5.008; }
use warnings;
use strict;

use Params::Classify 0.000 qw(is_string is_ref is_strictly_blessed);
use XML::Easy::Syntax 0.000
	qw($xml10_char_rx $xml10_name_rx $xml10_encname_rx);

our $VERSION = "0.009";

use parent "Exporter";
our @EXPORT_OK = qw(
	is_xml_name check_xml_name
	is_xml_encname check_xml_encname
	is_xml_chardata check_xml_chardata
	is_xml_attributes check_xml_attributes
	is_xml_content_object check_xml_content_object
	is_xml_content_twine check_xml_content_twine
	is_xml_content_array
	is_xml_content check_xml_content
	is_xml_element check_xml_element
);

sub _throw_data_error($) {
	my($msg) = @_;
	die "invalid XML data: $msg\n";
}

=head1 FUNCTIONS

Each of these functions takes one scalar argument (I<ARG>) to be tested.
Any scalar value is acceptable for the argument to be tested.  Each C<is_>
function returns a simple truth value result, which is true iff I<ARG>
is of the type being checked for.  Each C<check_> function will return
normally if the argument is of the type being checked for, or will C<die>
if it is not.

=over

=item is_xml_name(ARG)

=item check_xml_name(ARG)

Check whether I<ARG> is a plain string satisfying the XML name syntax.
(Such names are used to identify element types, attributes, entities,
and other things in XML.)

=cut

sub is_xml_name($) {
	no warnings "utf8";
	return is_string($_[0]) && $_[0] =~ /\A$xml10_name_rx\z/o;
}

sub check_xml_name($) {
	_throw_data_error("name isn't a string") unless is_string($_[0]);
	no warnings "utf8";
	_throw_data_error("illegal name")
		unless $_[0] =~ /\A$xml10_name_rx\z/o;
}

=item is_xml_encname(ARG)

=item check_xml_encname(ARG)

Check whether I<ARG> is a plain string satisfying the XML character
encoding name syntax.

=cut

sub is_xml_encname($) {
	no warnings "utf8";
	return is_string($_[0]) && $_[0] =~ /\A$xml10_encname_rx\z/o;
}

sub check_xml_encname($) {
	_throw_data_error("encoding name isn't a string")
		unless is_string($_[0]);
	no warnings "utf8";
	_throw_data_error("illegal encoding name")
		unless $_[0] =~ /\A$xml10_encname_rx\z/o;
}

=item is_xml_chardata(ARG)

=item check_xml_chardata(ARG)

Check whether I<ARG> is a plain string consisting of a sequence of
characters that are acceptable to XML.  Such a string is valid as data
in an XML element (where it may be intermingled with subelements) or as
the value of an element attribute.

=cut

sub is_xml_chardata($) {
	no warnings "utf8";
	return is_string($_[0]) && $_[0] =~ /\A$xml10_char_rx*\z/o;
}

sub check_xml_chardata($) {
	_throw_data_error("character data isn't a string")
		unless is_string($_[0]);
	no warnings "utf8";
	_throw_data_error("character data contains illegal character")
		unless $_[0] =~ /\A$xml10_char_rx*\z/o;
}

=item is_xml_attributes(ARG)

=item check_xml_attributes(ARG)

Check whether I<ARG> is a reference to a hash that is well-formed as
an XML element attribute set.  To be well-formed, each key in the hash
must be an XML name string, and each value must be an XML character
data string.

=cut

sub is_xml_attributes($) {
	return undef unless is_ref($_[0], "HASH");
	my $attrs = $_[0];
	foreach(keys %$attrs) {
		return undef unless
			is_xml_name($_) && is_xml_chardata($attrs->{$_});
	}
	return 1;
}

sub check_xml_attributes($) {
	_throw_data_error("attribute hash isn't a hash")
		unless is_ref($_[0], "HASH");
	foreach(sort keys %{$_[0]}) {
		no warnings "utf8";
		_throw_data_error("illegal attribute name")
			unless /\A$xml10_name_rx\z/o;
		check_xml_chardata($_[0]->{$_});
	}
}

=item is_xml_content_object(ARG)

=item check_xml_content_object(ARG)

Check whether I<ARG> is a reference to an L<XML::Easy::Content>
object, and thus represents a chunk of XML content.

=cut

sub is_xml_content_object($) {
	return is_strictly_blessed($_[0], "XML::Easy::Content");
}

sub check_xml_content_object($) {
	_throw_data_error("content data isn't a content chunk")
		unless &is_xml_content_object;
}

=item is_xml_content_twine(ARG)

=item check_xml_content_twine(ARG)

Check whether I<ARG> is a reference to a twine array
(see L<XML::Easy::NodeBasics/Twine>),
and thus represents a chunk of XML content.

=cut

sub is_xml_element($);

sub is_xml_content_twine($) {
	return undef unless is_ref($_[0], "ARRAY");
	my $twine = $_[0];
	return undef unless @$twine % 2 == 1;
	for(my $i = $#$twine; ; $i--) {
		return undef unless is_xml_chardata($twine->[$i]);
		last if $i-- == 0;
		return undef unless is_xml_element($twine->[$i]);
	}
	return 1;
}

sub check_xml_element($);

sub check_xml_content_twine($) {
	_throw_data_error("content array isn't an array")
		unless is_ref($_[0], "ARRAY");
	my $twine = $_[0];
	_throw_data_error("content array has even length")
		unless @$twine % 2 == 1;
	for(my $i = 0; ; $i++) {
		check_xml_chardata($twine->[$i]);
		last if ++$i == @$twine;
		check_xml_element($twine->[$i]);
	}
}

=item is_xml_content_array(ARG)

Deprecated alias for L</is_xml_content_twine>.

=cut

*is_xml_content_array = \&is_xml_content_twine;

=item is_xml_content(ARG)

=item check_xml_content(ARG)

Check whether I<ARG> is a reference to either an L<XML::Easy::Content>
object or a twine array (see L<XML::Easy::NodeBasics/Twine>),
and thus represents a chunk of XML content.

=cut

sub is_xml_content($) {
	return &is_xml_content_object || &is_xml_content_twine;
}

sub check_xml_content($) {
	if(is_ref($_[0], "ARRAY")) {
		&check_xml_content_twine;
	} else {
		&check_xml_content_object;
	}
}

=item is_xml_element(ARG)

=item check_xml_element(ARG)

Check whether I<ARG> is a reference to an L<XML::Easy::Element>
object, and thus represents an XML element.

=cut

sub is_xml_element($) { is_strictly_blessed($_[0], "XML::Easy::Element") }

sub check_xml_element($) {
	_throw_data_error("element data isn't an element")
		unless &is_xml_element;
}

=back

=head1 SEE ALSO

L<Params::Classify>,
L<XML::Easy::NodeBasics>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
