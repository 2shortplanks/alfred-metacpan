=head1 NAME

XML::Easy::Content - abstract form of XML content

=head1 SYNOPSIS

	use XML::Easy::Content;

	$content = XML::Easy::Content->new([
		"foo",
		$subelement,
		"bar",
	]);

	$twine = $content->twine;

=head1 DESCRIPTION

An object of this class represents a chunk of XML content, the kind
of matter that can be contained within an XML element.  This is in an
abstract form, intended for general manipulation.  It is completely
isolated from the textual representation of XML, and holds only the
meaningful content of the chunk.  The data in a content object cannot
be modified: different data requires the creation of a new object.

An XML content chunk consists of a sequence of zero or more characters
and XML elements, interspersed in any fashion.  Character content can
use almost all Unicode characters, with only a few characters (such as
most of the ASCII control characters) prohibited by the specification
from being directly represented in XML.  Each XML element in a content
chunk itself recursively contains a chunk of content, in addition to
having attached metadata.

This class is not meant to be subclassed.  XML content is unextendable,
dumb data.  Content objects are better processed using the functions in
L<XML::Easy::NodeBasics> than using the methods of this class.

=cut

package XML::Easy::Content;

{ use 5.008; }
use warnings;
use strict;

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
	my $pp_code = "#line 75 \"$filename\"\n".<DATA>;
	close(DATA);
	{
		local $SIG{__DIE__};
		eval $pp_code;
	}
	die $@ if $@ ne "";
}

*content = \&twine;

1;

__DATA__

# Note perl bug: a bug in perl 5.8.{0..6} screws up __PACKAGE__ (used below)
# for the eval.  Explicit package declaration here fixes it.
package XML::Easy::Content;

use Params::Classify 0.000 qw(is_ref);
use XML::Easy::Classify qw(check_xml_content_twine);

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

=item XML::Easy::Content->new(TWINE)

Constructs and returns a new content chunk object with the specified
content.
I<TWINE> must be a reference to an array listing the chunk's
content in twine form (see L<XML::Easy::NodeBasics/Twine>).
The content is checked for validity, against the XML 1.0
specification, and the function C<die>s if it is invalid.

=cut

sub new {
	my($class, $twine) = @_;
	_throw_data_error("content array isn't an array")
		unless is_ref($twine, "ARRAY");
	$twine = [ @$twine ];
	_set_readonly(\$_) foreach @$twine;
	_set_readonly($twine);
	check_xml_content_twine($twine);
	my $self = bless([ $twine ], __PACKAGE__);
	_set_readonly(\$_) foreach @$self;
	_set_readonly($self);
	return $self;
}

=back

=head1 METHODS

=over

=item $content->twine

Returns a reference to an array listing the chunk's
content in twine form (see L<XML::Easy::NodeBasics/Twine>).

The returned array must not be subsequently modified.  If possible,
it will be marked as read-only in order to prevent modification.

=cut

sub twine { $_[0]->[0] }

=item $content->content

Deprecated alias for the L</twine> method.

=back

=head1 SEE ALSO

L<XML::Easy::Element>,
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
