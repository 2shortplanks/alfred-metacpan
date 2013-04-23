=head1 NAME

XML::Easy::NodeBasics - basic manipulation of XML data nodes

=head1 SYNOPSIS

	use XML::Easy::NodeBasics qw(xml_content_object xml_element);

	$content = xml_content_object("this", "&", "that");
	$content = xml_content_object(@sublems);

	$element = xml_element("a", { href => "there" }, "there");
	$element = xml_element("div", @subelems);

	use XML::Easy::NodeBasics
		qw(xml_c_content_object xml_c_content_twine);

	$content = xml_c_content_object($content);
	$twine = xml_c_content_twine($content);

	use XML::Easy::NodeBasics qw(
		xml_e_type_name
		xml_e_attributes xml_e_attribute
		xml_e_content_object
	);

	$type_name = xml_e_type_name($element);
	$attributes = xml_e_attributes($element);
	$href = xml_e_attribute($element, "href");
	$content = xml_e_content_object($element);

	use XML::Easy::NodeBasics qw(
		xml_c_equal xml_e_equal
		xml_c_unequal xml_e_unequal
	);

	if(xml_c_equal($content0, $content1)) { ...
	if(xml_e_equal($element0, $element1)) { ...
	if(xml_c_unequal($content0, $content1)) { ...
	if(xml_e_unequal($element0, $element1)) { ...

=head1 DESCRIPTION

This module supplies functions concerned with the creation, examination,
and other manipulation of XML data nodes (content chunks and elements).
The nodes are dumb data objects, best manipulated using plain functions
such as the ones in this module.

The nodes are objects of the classes L<XML::Easy::Content> and
L<XML::Easy::Element>.  The data contained within an existing node
cannot be modified.  This means that references to nodes can be copied
and passed around arbitrarily, without worrying about who might write to
them, or deep versus shallow copying.  As a result, tasks that you might
think of as "modifying an XML node" actually involve creating a new node.

The node classes do not have any interesting object-oriented behaviour,
and their minimalistic methods are not meant to be called directly.
Instead, node creation and examination should be performed using the
functions of this module.

=head2 Twine

For the purposes of examining what is contained within a chunk of
content, there is a standard representation of content known as "twine".
(It's stronger than a string, and has an alternating structure as will
be described.)

A piece of twine is a reference to an array with an odd number of members.
The first and last members, and all members in between with an even index,
are strings giving the chunk's character data.  Each member with an odd
index is a reference to an L<XML::Easy::Element> object, representing
an XML element contained directly within the chunk.  Any of the strings
may be empty, if the chunk has no character data between subelements or
at the start or end of the chunk.

When not looking inside a content chunk, it is preferred to represent
it in encapsulated form as an L<XML::Easy::Content> object.

=cut

package XML::Easy::NodeBasics;

{ use 5.008; }
use warnings;
use strict;

use Params::Classify 0.000 qw(is_string is_ref);
use XML::Easy::Classify 0.001 qw(
	is_xml_name check_xml_chardata check_xml_attributes
	is_xml_content_object check_xml_content_object
	is_xml_element check_xml_element
);
use XML::Easy::Content 0.007 ();
use XML::Easy::Element 0.007 ();

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

our $VERSION = "0.009";

use parent "Exporter";
our @EXPORT_OK = qw(
	xml_content_object xc xml_content_twine xct xml_content xml_element xe
	xml_c_content_object xc_cont xml_c_content_twine xc_twine xml_c_content
	xml_e_type_name xe_type
	xml_e_attributes xe_attrs xml_e_attribute xe_attr
	xml_e_content_object xe_cont xml_e_content_twine xe_twine xml_e_content
	xml_c_equal xc_eq xml_e_equal xe_eq
	xml_c_unequal xc_ne xml_e_unequal xe_ne
);

sub _throw_data_error($) {
	my($msg) = @_;
	die "invalid XML data: $msg\n";
}

=head1 FUNCTIONS

Each function has two names.  There is a longer descriptive name, and
a shorter name to spare screen space and the programmer's fingers.

=head2 Construction

The construction functions each accept any number of items of XML content.
These items may be supplied in any of several forms.  Content item
types may be mixed arbitrarily, in any sequence.  The permitted forms
of content item are:

=over

=item character data

A plain string of characters that are acceptable to XML.

=item element

A reference to an L<XML::Easy::Element> object representing an XML
element.

=item content object

A reference to an L<XML::Easy::Content> object representing a chunk of
XML content.

=item twine array

A reference to a L<twine|/Twine> array listing a chunk of XML content.

=back

The construction functions are:

=over

=item xml_content_object(ITEM ...)

=item xc(ITEM ...)

Constructs and returns a XML content object based on a list of
constituents.  Any number of I<ITEM>s (zero or more) may be supplied; each
one must be a content item of a permitted type.  All the constituents
are checked for validity, against the XML 1.0 specification, and the
function C<die>s if any are invalid.

All the supplied content items are concatenated to form a single chunk.
The function returns a reference to an L<XML::Easy::Content> object.

=cut

sub xml_content_twine(@);

sub xml_content_object(@) { XML::Easy::Content->new(&xml_content_twine) }

*xc = \&xml_content_object;

=item xml_content_twine(ITEM ...)

=item xct(ITEM ...)

Performs the same construction job as L</xml_content_object>, but returns
the resulting content chunk in the form of L<twine|/Twine> rather than
a content object.

The returned array must not be subsequently modified.  If possible,
it will be marked as read-only in order to prevent modification.

=cut

sub xml_content_twine(@) {
	my @content = ("");
	foreach(@_) {
		if(is_string($_)) {
			check_xml_chardata($_);
			$content[-1] .= $_;
		} elsif(is_xml_element($_)) {
			push @content, $_, "";
		} elsif(is_xml_content_object($_)) {
			my $twine = $_->twine;
			$content[-1] .= $twine->[0];
			push @content, @{$twine}[1 .. $#$twine];
		} elsif(is_ref($_, "ARRAY")) {
			my $twine = XML::Easy::Content->new($_)->twine;
			$content[-1] .= $twine->[0];
			push @content, @{$twine}[1 .. $#$twine];
		} else {
			_throw_data_error("invalid content item");
		}
	}
	_set_readonly(\$_) foreach @content;
	_set_readonly(\@content);
	return \@content;
}

*xct = \&xml_content_twine;

=item xml_content(ITEM ...)

Deprecated alias for L</xml_content_twine>.

=cut

*xml_content = \&xml_content_twine;

=item xml_element(TYPE_NAME, ITEM ...)

=item xe(TYPE_NAME, ITEM ...)

Constructs and returns an L<XML::Easy::Element> object, representing an
XML element, based on a list of consitutents.  I<TYPE_NAME> must be a
string, and gives the name of the element's type.  Any number of I<ITEM>s
(zero or more) may be supplied; each one must be either a content item
of a permitted type or a reference to a hash of attributes.  All the
constituents are checked for validity, against the XML 1.0 specification,
and the function C<die>s if any are invalid.

All the attributes supplied are gathered together to form the element's
attribute set.  It is an error if an attribute name has been used more
than once (even if the same value was given each time).  All the supplied
content items are concatenated to form the element's content.
The function returns a reference to an L<XML::Easy::Element> object.

=cut

sub xml_element($@) {
	my $type_name = shift(@_);
	XML::Easy::Element->new($type_name, {}, [""])
		unless is_xml_name($type_name);
	my %attrs;
	for(my $i = 0; $i != @_; ) {
		my $item = $_[$i];
		if(is_ref($item, "HASH")) {
			while(my($k, $v) = each(%$item)) {
				_throw_data_error("duplicate attribute name")
					if exists $attrs{$k};
				$attrs{$k} = $v;
			}
			splice @_, $i, 1, ();
		} else {
			$i++;
		}
	}
	check_xml_attributes(\%attrs);
	return XML::Easy::Element->new($type_name, \%attrs,
					&xml_content_object);
}

*xe = \&xml_element;

=back

=head2 Examination of content chunks

=over

=item xml_c_content_object(CONTENT)

=item xc_cont(CONTENT)

I<CONTENT> must be a reference to either an L<XML::Easy::Content>
object or a L<twine|/Twine> array.
Returns a reference to an L<XML::Easy::Content> object encapsulating
the content.

=cut

sub xml_c_content_object($) {
	if(is_ref($_[0], "ARRAY")) {
		return XML::Easy::Content->new($_[0]);
	} else {
		&check_xml_content_object;
		return $_[0];
	}
}

*xc_cont = \&xml_c_content_object;

=item xml_c_content_twine(CONTENT)

=item xc_twine(CONTENT)

I<CONTENT> must be a reference to either an L<XML::Easy::Content>
object or a L<twine|/Twine> array.
Returns a reference to a L<twine|/Twine> array listing the content.

The returned array must not be subsequently modified.  If possible,
it will be marked as read-only in order to prevent modification.

=cut

sub xml_c_content_twine($) { xml_c_content_object($_[0])->twine }

*xc_twine = \&xml_c_content_twine;

=item xml_c_content(CONTENT)

Deprecated alias for L</xml_c_content_twine>.

=cut

*xml_c_content = \&xml_c_content_twine;

=back

=head2 Examination of elements

=over

=item xml_e_type_name(ELEMENT)

=item xe_type(ELEMENT)

I<ELEMENT> must be a reference to an L<XML::Easy::Element> object.
Returns the element's type's name, as a string.

=cut

sub xml_e_type_name($) {
	&check_xml_element;
	return $_[0]->type_name;
}

*xe_type = \&xml_e_type_name;

=item xml_e_attributes(ELEMENT)

=item xe_attrs(ELEMENT)

I<ELEMENT> must be a reference to an L<XML::Easy::Element> object.
Returns a reference to a hash encapsulating
the element's attributes.  In the hash, each key is an attribute name,
and the corresponding value is the attribute's value as a string.

The returned hash must not be subsequently modified.  If possible, it
will be marked as read-only in order to prevent modification.  As a side
effect, the read-only-ness may make lookup of any non-existent attribute
generate an exception rather than returning C<undef>.

=cut

sub xml_e_attributes($) {
	&check_xml_element;
	return $_[0]->attributes;
}

*xe_attrs = \&xml_e_attributes;

=item xml_e_attribute(ELEMENT, NAME)

=item xe_attr(ELEMENT, NAME)

I<ELEMENT> must be a reference to an L<XML::Easy::Element> object.
Looks up a specific attribute of the
element, by a name supplied as a string.  If there is an attribute by
that name then its value is returned, as a string.  If there is no such
attribute then C<undef> is returned.

=cut

sub xml_e_attribute($$) {
	check_xml_element($_[0]);
	return $_[0]->attribute($_[1]);
}

*xe_attr = \&xml_e_attribute;

=item xml_e_content_object(ELEMENT)

=item xe_cont(ELEMENT)

I<ELEMENT> must be a reference to an L<XML::Easy::Element> object.
Returns a reference to an L<XML::Easy::Content> object encapsulating
the element's content.

=cut

sub xml_e_content_object($) {
	&check_xml_element;
	return $_[0]->content_object;
}

*xe_cont = \&xml_e_content_object;

=item xml_e_content_twine(ELEMENT)

=item xe_twine(ELEMENT)

I<ELEMENT> must be a reference to an L<XML::Easy::Element> object.
Returns a reference to a L<twine|/Twine> array listing the element's content.

The returned array must not be subsequently modified.  If possible,
it will be marked as read-only in order to prevent modification.

=cut

sub xml_e_content_twine($) {
	&check_xml_element;
	return $_[0]->content_twine;
}

*xe_twine = \&xml_e_content_twine;

=item xml_e_content(ELEMENT)

Deprecated alias for L</xml_e_content_twine>.

=cut

*xml_e_content = \&xml_e_content_twine;

=back

=head2 Comparison

=over

=item xml_c_equal(A, B)

=item xc_eq(A, B)

I<A> and I<B> must each be a reference to either an L<XML::Easy::Content>
object or a L<twine|/Twine> array.
Returns true if they represent exactly the same content,
and false if they do not.

=cut

sub _xe_eq($$);

sub _xct_eq($$) {
	my($a, $b) = @_;
	return !!1 if $a == $b;
	return !!0 unless @$a == @$b;
	for(my $i = $#$a; $i >= 0; $i -= 2) {
		return !!0 unless $a->[$i] eq $b->[$i];
	}
	for(my $i = $#$a-1; $i >= 0; $i -= 2) {
		return !!0 unless _xe_eq($a->[$i], $b->[$i]);
	}
	return !!1;
}

sub xml_c_equal($$) {
	return _xct_eq(xml_c_content_twine($_[0]), xml_c_content_twine($_[1]));
}

*xc_eq = \&xml_c_equal;

=item xml_e_equal(A, B)

=item xe_eq(A, B)

I<A> and I<B> must each be a reference to an L<XML::Easy::Element> object.
Returns true if they represent exactly the same element,
and false if they do not.

=cut

sub _xe_eq($$) {
	my($a, $b) = @_;
	return !!1 if $a == $b;
	return !!0 unless $a->type_name eq $b->type_name;
	my $aattr = $a->attributes;
	my $battr = $b->attributes;
	foreach(keys %$aattr) {
		return !!0 unless exists($battr->{$_}) &&
					$aattr->{$_} eq $battr->{$_};
	}
	foreach(keys %$battr) {
		return !!0 unless exists $aattr->{$_};
	}
	return _xct_eq($a->content_twine, $b->content_twine);
}

sub xml_e_equal($$) {
	check_xml_element($_[0]);
	check_xml_element($_[1]);
	return &_xe_eq;
}

*xe_eq = \&xml_e_equal;

=item xml_c_unequal(A, B)

=item xc_ne(A, B)

I<A> and I<B> must each be a reference to either an L<XML::Easy::Content>
object or a L<twine|/Twine> array.
Returns true if they do not represent exactly the same content,
and false if they do.

=cut

sub xml_c_unequal($$) { !&xml_c_equal }

*xc_ne = \&xml_c_unequal;

=item xml_e_unequal(A, B)

=item xe_ne(A, B)

I<A> and I<B> must each be a reference to an L<XML::Easy::Element> object.
Returns true if they do not represent exactly the same element,
and false if they do.

=cut

sub xml_e_unequal($$) { !&xml_e_equal }

*xe_ne = \&xml_e_unequal;

=back

=head1 SEE ALSO

L<XML::Easy::Classify>,
L<XML::Easy::Content>,
L<XML::Easy::Element>,
L<XML::Easy::ProceduralWriter>,
L<XML::Easy::SimpleSchemaUtil>,
L<XML::Easy::Text>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
