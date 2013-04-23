=head1 NAME

XML::Easy::Element - abstract form of XML element

=head1 SYNOPSIS

	use XML::Easy::Element;

	$element = XML::Easy::Element->new("a",
			{ href => "#there" }, $content);

	$type_name = $element->type_name;
	$attributes = $element->attributes;
	$href = $element->attribute("href");
	$content = $element->content_object;

=head1 DESCRIPTION

An object of this class represents an XML element, a node in the tree
making up an XML document.  This is in an abstract form, intended
for general manipulation.  It is completely isolated from the textual
representation of XML, and holds only the meaningful content of the
element.  The data in an element object cannot be modified: different
data requires the creation of a new object.

The properties of an XML element are of three kinds.  Firstly, the element
has exactly one type, which is referred to by a name.  Secondly, the
element has a set of zero or more attributes.  Each attribute consists of
a name, which is unique among the attributes of the element, and a value,
which is a string of characters.  Finally, the element has content, which
is a sequence of zero or more characters and (recursively) elements,
interspersed in any fashion.

The element type name and attribute names all follow the XML syntax
for names.  This allows the use of a wide set of Unicode characters,
with some restrictions.  Attribute values and character content can use
almost all Unicode characters, with only a few characters (such as most
of the ASCII control characters) prohibited by the specification from
being directly represented in XML.

This class is not meant to be subclassed.  XML elements are unextendable,
dumb data.  Element objects are better processed using the functions in
L<XML::Easy::NodeBasics> than using the methods of this class.

=cut

package XML::Easy::Element;

{ use 5.008; }
use warnings;
use strict;

use XML::Easy::Content 0.007 ();

our $VERSION = "0.009";

eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load("XML::Easy", $VERSION) unless defined &new;
};

if($@ eq "") {
	close(DATA);
} else {
	(my $filename = __FILE__) =~ tr# -~##cd;
	local $/ = undef;
	my $pp_code = "#line 83 \"$filename\"\n".<DATA>;
	close(DATA);
	{
		local $SIG{__DIE__};
		eval $pp_code;
	}
	die $@ if $@ ne "";
}

*content = \&content_twine;

1;

__DATA__

# Note perl bug: a bug in perl 5.8.{0..6} screws up __PACKAGE__ (used below)
# for the eval.  Explicit package declaration here fixes it.
package XML::Easy::Element;

use Params::Classify 0.000 qw(is_string is_ref);
use XML::Easy::Classify 0.001 qw(check_xml_attributes check_xml_content_object);
use XML::Easy::Syntax 0.000 qw($xml10_name_rx);

BEGIN {
	if(eval { local $SIG{__DIE__};
		require Internals;
		exists &Internals::SetReadOnly;
	}) {
		*_set_readonly = \&Internals::SetReadOnly;
	} else {
		*_set_readonly = sub { };
	}
}

sub _throw_data_error($) {
	my($msg) = @_;
	die "invalid XML data: $msg\n";
}

=head1 CONSTRUCTOR

=over

=item XML::Easy::Element->new(TYPE_NAME, ATTRIBUTES, CONTENT)

Constructs and returns a new element object with the specified properties.
I<TYPE_NAME> must be a string.  I<ATTRIBUTES> must be a reference
to a hash in the same form that is returned by the accessor method
C<attributes> (below).  I<CONTENT> must be a reference to either an
L<XML::Easy::Content> object or a twine array
(see L<XML::Easy::NodeBasics/Twine>).
All are checked for validity, against
the XML 1.0 specification, and the function C<die>s if any are invalid.

=cut

sub new {
	my($class, $type_name, $attrs, $content) = @_;
	_throw_data_error("element type name isn't a string")
		unless is_string($type_name);
	{
		no warnings "utf8";
		_throw_data_error("illegal element type name")
			unless $type_name =~ /\A$xml10_name_rx\z/o;
	}
	_throw_data_error("attribute hash isn't a hash")
		unless is_ref($attrs, "HASH");
	$attrs = { %$attrs };
	_set_readonly(\$_) foreach values %$attrs;
	_set_readonly($attrs);
	check_xml_attributes($attrs);
	if(is_ref($content, "ARRAY")) {
		$content = XML::Easy::Content->new($content);
	} else {
		check_xml_content_object($content);
	}
	my $self = bless([ $type_name, $attrs, $content ], __PACKAGE__);
	_set_readonly(\$_) foreach @$self;
	_set_readonly($self);
	return $self;
}

=back

=head1 METHODS

=over

=item $element->type_name

Returns the element type name, as a string.

=cut

sub type_name { $_[0]->[0] }

=item $element->attributes

Returns a reference to a hash encapsulating the element's attributes.
In the hash, each key is an attribute name, and the corresponding value
is the attribute's value as a string.

The returned hash must not be subsequently modified.  If possible, it
will be marked as read-only in order to prevent modification.  As a side
effect, the read-only-ness may make lookup of any non-existent attribute
generate an exception rather than returning C<undef>.

=cut

sub attributes { $_[0]->[1] }

=item $element->attribute(NAME)

Looks up a specific attribute of the element.
The supplied I<NAME> must be a string containing a valid attribute name.
If there is an attribute by that name then its value is returned,
as a string.  If there is no such attribute then C<undef> is returned.

=cut

sub attribute {
	_throw_data_error("attribute name isn't a string")
		unless is_string($_[1]);
	{
		no warnings "utf8";
		_throw_data_error("illegal attribute name")
			unless $_[1] =~ /\A$xml10_name_rx\z/o;
	}
	return exists($_[0]->[1]->{$_[1]}) ? $_[0]->[1]->{$_[1]} : undef;
}

=item $element->content_object

Returns a reference to an L<XML::Easy::Content> object encapsulating
the element's content.

=cut

sub content_object { $_[0]->[2] }

=item $element->content_twine

Returns a reference to a twine array (see L<XML::Easy::NodeBasics/Twine>)
listing the element's content.

The returned array must not be subsequently modified.  If possible,
it will be marked as read-only in order to prevent modification.

=cut

sub content_twine {
	my $content = $_[0]->[2];
	check_xml_content_object($content);
	return $content->twine;
}

=item $element->content

Deprecated alias for the L</content_twine> method.

=back

=head1 SEE ALSO

L<XML::Easy::Content>,
L<XML::Easy::NodeBasics>

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
