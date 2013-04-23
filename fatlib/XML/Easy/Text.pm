=head1 NAME

XML::Easy::Text - XML parsing and serialisation

=head1 SYNOPSIS

	use XML::Easy::Text qw(
		xml10_read_content_object xml10_read_element
		xml10_read_document xml10_read_extparsedent_object
	);

	$content = xml10_read_content_object($text);
	$element = xml10_read_element($text);
	$element = xml10_read_document($text);
	$content = xml10_read_extparsedent_object($text);

	use XML::Easy::Text qw(
		xml10_write_content xml10_write_element
		xml10_write_document xml10_write_extparsedent
	);

	$text = xml10_write_content($content);
	$text = xml10_write_element($element);
	$text = xml10_write_document($element, "UTF-8");
	$text = xml10_write_extparsedent($content, "UTF-8");

=head1 DESCRIPTION

This module supplies functions that parse and serialise XML data
according to the XML 1.0 specification.

This module is oriented towards the use of XML to represent data
for interchange purposes, rather than the use of XML as markup of
principally textual data.  It does not perform any schema processing,
and does not interpret DTDs or any other kind of schema.  It adheres
strictly to the XML specification, in all its awkward details, except
for the aforementioned DTDs.

XML data in memory is represented using a tree of
L<XML::Easy::Content> and L<XML::Easy::Element>
objects.  Such a tree encapsulates all the structure and data content
of an XML element or document, without any irrelevant detail resulting
from the textual syntax.
These node trees are readily manipulated by the functions
in L<XML::Easy::NodeBasics>.

The functions of this module are implemented
in C for performance, with a pure Perl backup version (which has good
performance compared to other pure Perl parsers) for systems that can't
handle XS modules.

=cut

package XML::Easy::Text;

{ use 5.008; }
use warnings;
use strict;

use XML::Easy::Content 0.007 ();
use XML::Easy::Element 0.007 ();

our $VERSION = "0.009";

use parent "Exporter";
our @EXPORT_OK = qw(
	xml10_read_content_object xml10_read_content_twine
	xml10_read_content
	xml10_read_element
	xml10_read_document
	xml10_read_extparsedent_object xml10_read_extparsedent_twine
	xml10_read_extparsedent
	xml10_write_content xml10_write_element
	xml10_write_document xml10_write_extparsedent
);

eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load("XML::Easy", $VERSION)
		unless defined &xml10_write_document;
};

if($@ eq "") {
	close(DATA);
} else {
	(my $filename = __FILE__) =~ tr# -~##cd;
	local $/ = undef;
	my $pp_code = "#line 98 \"$filename\"\n".<DATA>;
	close(DATA);
	{
		local $SIG{__DIE__};
		eval $pp_code;
	}
	die $@ if $@ ne "";
}

*xml10_read_content = \&xml10_read_content_twine;
*xml10_read_extparsedent = \&xml10_read_extparsedent_twine;

1;

__DATA__

use Params::Classify 0.000 qw(is_string is_ref is_strictly_blessed);
use XML::Easy::Syntax 0.001 qw(
	$xml10_char_rx $xml10_chardata_rx $xml10_comment_rx $xml10_encname_rx
	$xml10_eq_rx $xml10_miscseq_rx $xml10_name_rx $xml10_pi_rx
	$xml10_prolog_xdtd_rx $xml10_s_rx $xml10_textdecl_rx
);

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

sub _throw_syntax_error($) {
	my($rtext) = @_;
	die "XML syntax error\n";
}

sub _throw_wfc_error($) {
	my($msg) = @_;
	die "XML constraint error: $msg\n";
}

sub _throw_data_error($) {
	my($msg) = @_;
	die "invalid XML data: $msg\n";
}

=head1 FUNCTIONS

All functions C<die> on error.

=head2 Parsing

These function take textual XML and extract the abstract XML content.
In the terminology of the XML specification, they constitute a
non-validating processor: they check for well-formedness of the XML,
but not for adherence of the content to any schema.

The inputs (to be parsed) for these functions are always character
strings.  XML text is frequently encoded using UTF-8, or some other
Unicode encoding, so that it can contain characters from the full
Unicode repertoire.  In that case, something must perform UTF-8 decoding
(or decoding of some other character encoding) to convert the octets of
a file to the characters on which these functions operate.  A Perl I/O
layer can do the job (see L<perlio>), or it can be performed explicitly
using the C<decode> function in the L<Encode> module.

=cut

my %predecl_entity = (
	lt => "<",
	gt => ">",
	amp => "&",
	quot => '"',
	apos => "'",
);

sub _parse_reference($) {
	my($rtext) = @_;
	if($$rtext =~ /\G&#x([0-9A-Fa-f]+);/gc) {
		my $v = $1;
		_throw_wfc_error("invalid character in character reference")
			unless $v =~ /\A0*(.{1,6})\z/s;
		no warnings "utf8";
		my $c = chr(hex($v));
		_throw_wfc_error("invalid character in character reference")
			unless $c =~ /\A$xml10_char_rx\z/o;
		return $c;
	} elsif($$rtext =~ /\G&#([0-9]+);/gc) {
		my $v = $1;
		_throw_wfc_error("invalid character in character reference")
			unless $v =~ /\A0*(.{1,7})\z/s;
		no warnings "utf8";
		my $c = chr($v);
		_throw_wfc_error("invalid character in character reference")
			unless $c =~ /\A$xml10_char_rx\z/o;
		return $c;
	} elsif($$rtext =~ /\G&($xml10_name_rx);/ogc) {
		my $c = $predecl_entity{$1};
		_throw_wfc_error("reference to undeclared entity")
			unless defined $c;
		return $c;
	} else { _throw_syntax_error($rtext) }
}

sub _parse_attvalue($) {
	my($rtext) = @_;
	$$rtext =~ /\G(["'])/gc or _throw_syntax_error($rtext);
	my $q = $1;
	my $value = "";
	while(1) {
		if($$rtext =~ /\G$q/gc) {
			last;
		} elsif($$rtext =~ /\G(?:\x{d}\x{a}?|[\x{9}\x{a}])/gc) {
			$value .= " ";
		} elsif($$rtext =~ /\G(["']
				     |(?:(?![<&"'\x{9}\x{a}\x{d}])
					 $xml10_char_rx)+)/xogc) {
			$value .= $1;
		} elsif($$rtext =~ /\G(?=&)/gc) {
			$value .= _parse_reference($rtext);
		} else { _throw_syntax_error($rtext) }
	}
	return $value;
}

sub _parse_element($);

sub _parse_twine($) {
	my($rtext) = @_;
	my @twine = ("");
	while(1) {
		# Note perl bug: in some versions of perl, including 5.8.8
		# and 5.10.0, the "+" in the character-data regexp acts
		# as "{1,32767}", and so won't match longer sequences
		# of characters.  (In some perl versions this behaviour
		# varies according to the encoding of the input string.)
		# Therefore, immediately after matching character data,
		# it is *not* guaranteed that the next thing cannot
		# be more valid character data.  For this reason it is
		# vitally important that the control flow in that case
		# try the same regexp again.
		if($$rtext =~ /\G((?:(?![<&])$xml10_char_rx)+)/ogc) {
			my $value = $1;
			# Due to the perl bug noted above, it is
			# necessary to backtrace a bit in some cases,
			# where significant subsequences of characters
			# might be split across the end of a match.
			pos($$rtext) -= length($1)
				if $value =~ s/(?!\A)(\x{d}|\]\]?)\z//;
			_throw_syntax_error($rtext) if $value =~ /\]\]>/;
			$value =~ s/\x{d}\x{a}?/\x{a}/g;
			$twine[-1] .= $value;
		} elsif($$rtext =~ m#\G(?=<[^/?!])#gc) {
			push @twine, _parse_element($rtext), "";
		} elsif($$rtext =~ /\G(?=&)/gc) {
			$twine[-1] .= _parse_reference($rtext);
		} elsif($$rtext =~ /\G<!\[CDATA\[($xml10_char_rx*?)\]\]>/ogc) {
			my $value = $1;
			$value =~ s/\x{d}\x{a}?/\x{a}/g;
			$twine[-1] .= $value;
		} elsif($$rtext =~ /\G(?:$xml10_pi_rx|$xml10_comment_rx)/ogc) {
			# no content
		} else {
			return \@twine;
		}
	}
}

sub _parse_contentobject($) {
	return XML::Easy::Content->new(_parse_twine($_[0]));
}

my $empty_contentobject = XML::Easy::Content->new([""]);

sub _parse_element($) {
	my($rtext) = @_;
	$$rtext =~ /\G<($xml10_name_rx)/ogc or _throw_syntax_error($rtext);
	my $ename = $1;
	my %attrs;
	while($$rtext =~ /\G$xml10_s_rx/ogc) {
		last unless $$rtext =~ /\G($xml10_name_rx)$xml10_eq_rx/ogc;
		_throw_wfc_error("duplicate attribute") if exists $attrs{$1};
		$attrs{$1} = _parse_attvalue($rtext);
	}
	$$rtext =~ m#\G(/)?>#gc or _throw_syntax_error($rtext);
	my $content;
	if(defined $1) {
		$content = $empty_contentobject;
	} else {
		$content = _parse_contentobject($rtext);
		$$rtext =~ m#\G</($xml10_name_rx)$xml10_s_rx?>#gc
			or _throw_syntax_error($rtext);
		_throw_wfc_error("mismatched tags") unless $1 eq $ename;
	}
	return XML::Easy::Element->new($ename, \%attrs, $content);
}

=over

=item xml10_read_content_object(TEXT)

I<TEXT> must be a character string.  It is parsed against the B<content>
production of the XML 1.0 grammar; i.e., as a sequence of the kind of
matter that can appear between the start-tag and end-tag of an element.
Returns a reference to an L<XML::Easy::Content> object.

Normally one would not want to use this function directly, but prefer the
higher-level C<xml10_read_document> function.  This function exists for
the construction of custom XML parsers in situations that don't match
the full XML grammar.

=cut

sub xml10_read_content_object($) {
	_throw_data_error("text isn't a string") unless is_string($_[0]);
	my($text) = @_;
	my $content = _parse_contentobject(\$text);
	$text =~ /\G\z/gc or _throw_syntax_error(\$text);
	return $content;
}

=item xml10_read_content_twine(TEXT)

Performs the same parsing job as L</xml10_read_content_object>,
but returns the resulting content chunk in the form of twine
(see L<XML::Easy::NodeBasics/Twine>) rather than a content object.

The returned array must not be subsequently modified.  If possible,
it will be marked as read-only in order to prevent modification.

=cut

sub xml10_read_content_twine($) {
	_throw_data_error("text isn't a string") unless is_string($_[0]);
	my($text) = @_;
	my $twine = _parse_twine(\$text);
	$text =~ /\G\z/gc or _throw_syntax_error(\$text);
	_set_readonly(\$_) foreach @$twine;
	_set_readonly($twine);
	return $twine;
}

=item xml10_read_content(TEXT)

Deprecated alias for L</xml10_read_content_twine>.

=item xml10_read_element(TEXT)

I<TEXT> must be a character string.  It is parsed against the B<element>
production of the XML 1.0 grammar; i.e., as an item bracketed by tags
and containing content that may recursively include other elements.
Returns a reference to an L<XML::Easy::Element> object.

Normally one would not want to use this function directly, but prefer the
higher-level C<xml10_read_document> function.  This function exists for
the construction of custom XML parsers in situations that don't match
the full XML grammar.

=cut

sub xml10_read_element($) {
	_throw_data_error("text isn't a string") unless is_string($_[0]);
	my($text) = @_;
	my $element = _parse_element(\$text);
	$text =~ /\G\z/gc or _throw_syntax_error(\$text);
	return $element;
}

=item xml10_read_document(TEXT)

I<TEXT> must be a character string.  It is parsed against the B<document>
production of the XML 1.0 grammar; i.e., as a root element (possibly
containing subelements) optionally preceded and followed by non-content
matter, possibly headed by an XML declaration.  (A document type
declaration is I<not> accepted; this module does not process schemata.)
Returns a reference to an L<XML::Easy::Element> object which represents
the root element.  Nothing is returned relating to the XML declaration
or other non-content matter.

This is the most likely function to use to process incoming XML data.
Beware that the encoding declaration in the XML declaration, if any, does
not affect the interpretation of the input as a sequence of characters.

=cut

sub xml10_read_document($) {
	_throw_data_error("text isn't a string") unless is_string($_[0]);
	my($text) = @_;
	$text =~ /\A$xml10_prolog_xdtd_rx/ogc or _throw_syntax_error(\$text);
	my $element = _parse_element(\$text);
	$text =~ /\G$xml10_miscseq_rx\z/ogc or _throw_syntax_error(\$text);
	return $element;
}

=item xml10_read_extparsedent_object(TEXT)

I<TEXT> must be a character string.  It is parsed against the
B<extParsedEnt> production of the XML 1.0 grammar; i.e., as a sequence
of content (containing character data and subelements), possibly
headed by a text declaration (which is similar to, but not the same
as, an XML declaration).
Returns a reference to an L<XML::Easy::Content> object.

This is a relatively obscure part of the XML grammar, used when a
subpart of a document is stored in a separate file.  You're more likely
to require the C<xml10_read_document> function.

=cut

sub xml10_read_extparsedent_object($) {
	_throw_data_error("text isn't a string") unless is_string($_[0]);
	my($text) = @_;
	$text =~ /\A$xml10_textdecl_rx/gc;
	my $content = _parse_contentobject(\$text);
	$text =~ /\G\z/gc or _throw_syntax_error(\$text);
	return $content;
}

=item xml10_read_extparsedent_twine(TEXT)

Performs the same parsing job as L</xml10_read_extparsedent_object>,
but returns the resulting content chunk in the form of twine
(see L<XML::Easy::NodeBasics/Twine>) rather than a content object.

The returned array must not be subsequently modified.  If possible,
it will be marked as read-only in order to prevent modification.

=cut

sub xml10_read_extparsedent_twine($) {
	_throw_data_error("text isn't a string") unless is_string($_[0]);
	my($text) = @_;
	$text =~ /\A$xml10_textdecl_rx/gc;
	my $twine = _parse_twine(\$text);
	$text =~ /\G\z/gc or _throw_syntax_error(\$text);
	_set_readonly(\$_) foreach @$twine;
	_set_readonly($twine);
	return $twine;
}

=item xml10_read_extparsedent(TEXT)

Deprecated alias for L</xml10_read_extparsedent_twine>.

=back

=head2 Serialisation

These function take abstract XML data and serialise it as textual XML.
They do not perform indentation, default attribute suppression, or any
other schema-dependent processing.

The outputs of these functions are always character strings.  XML text
is frequently encoded using UTF-8, or some other Unicode encoding,
so that it can contain characters from the full Unicode repertoire.
In that case, something must perform UTF-8 encoding (or encoding of some
other character encoding) to convert the characters generated by these
functions to the octets of a file.  A Perl I/O layer can do the job
(see L<perlio>), or it can be performed explicitly using the C<encode>
function in the L<Encode> module.

=cut

sub _serialise_chardata($$) {
	my($rtext, $str) = @_;
	_throw_data_error("character data isn't a string")
		unless is_string($str);
	no warnings "utf8";
	while($str !~ /\G\z/gc) {
		# Note perl bug: in some versions of perl, including 5.8.8
		# and 5.10.0, the "+" in the plain-character regexp acts
		# as "{1,32767}", and so won't match longer sequences
		# of characters.  (In some perl versions this behaviour
		# varies according to the encoding of the input string.)
		# Therefore, immediately after matching character data,
		# it is *not* guaranteed that the next thing cannot
		# be more valid plain characters.  For this reason it is
		# vitally important that the control flow in that case
		# try the same regexp again.
		if($str =~ /\G((?:(?![\x{d}<&]|(?<=\]\])>)$xml10_char_rx)+)
				/xgc) {
			# Note perl bug: directly appending $1 to
			# $$rtext in this statement tickles a bug
			# in perl 5.8.0 that causes UTF-8 lossage.
			# The apparently-redundant stringification of
			# $1 works around it.
			$$rtext .= "$1";
		} elsif($str =~ /\G([\x{d}<&>])/gc) {
			$$rtext .= sprintf("&#x%02x;", ord($1));
		} else {
			_throw_data_error(
				"character data contains illegal character");
		}
	}
}

sub _serialise_element($$);

sub _serialise_twine($$) {
	my($rtext, $twine) = @_;
	_throw_data_error("content array isn't an array")
		unless is_ref($twine, "ARRAY");
	_throw_data_error("content array has even length")
		unless @$twine % 2 == 1;
	_serialise_chardata($rtext, $twine->[0]);
	my $ncont = @$twine;
	for(my $i = 1; $i != $ncont; ) {
		_serialise_element($rtext, $twine->[$i++]);
		_serialise_chardata($rtext, $twine->[$i++]);
	}
}

sub _serialise_contentobject($$) {
	my($rtext, $content) = @_;
	_throw_data_error("content data isn't a content chunk")
		unless is_strictly_blessed($content, "XML::Easy::Content");
	_serialise_twine($rtext, $content->twine);
}

sub _serialise_eithercontent($$) {
	if(is_ref($_[1], "ARRAY")) {
		goto &_serialise_twine;
	} else {
		goto &_serialise_contentobject;
	}
}

sub _serialise_attvalue($$) {
	my($rtext, $str) = @_;
	_throw_data_error("character data isn't a string")
		unless is_string($str);
	no warnings "utf8";
	while($str !~ /\G\z/gc) {
		# Note perl bug: in some versions of perl, including 5.8.8
		# and 5.10.0, the "+" in the plain-character regexp acts
		# as "{1,32767}", and so won't match longer sequences
		# of characters.  (In some perl versions this behaviour
		# varies according to the encoding of the input string.)
		# Therefore, immediately after matching character data,
		# it is *not* guaranteed that the next thing cannot
		# be more valid plain characters.  For this reason it is
		# vitally important that the control flow in that case
		# try the same regexp again.
		if($str =~ /\G((?:(?![\x{9}\x{a}\x{d}"<&])$xml10_char_rx)+)
				/xgc) {
			# Note perl bug: directly appending $1 to
			# $$rtext in this statement tickles a bug
			# in perl 5.8.0 that causes UTF-8 lossage.
			# The apparently-redundant stringification of
			# $1 works around it.
			$$rtext .= "$1";
		} elsif($str =~ /\G([\x{9}\x{a}\x{d}"<&])/gc) {
			$$rtext .= sprintf("&#x%02x;", ord($1));
		} else {
			_throw_data_error(
				"character data contains illegal character");
		}
	}
}

sub _serialise_element($$) {
	my($rtext, $elem) = @_;
	_throw_data_error("element data isn't an element")
		unless is_strictly_blessed($elem, "XML::Easy::Element");
	my $type_name = $elem->type_name;
	_throw_data_error("element type name isn't a string")
		unless is_string($type_name);
	{
		no warnings "utf8";
		_throw_data_error("illegal element type name")
			unless $type_name =~ /\A$xml10_name_rx\z/o;
	}
	$$rtext .= "<".$type_name;
	my $attributes = $elem->attributes;
	_throw_data_error("attribute hash isn't a hash")
		unless is_ref($attributes, "HASH");
	foreach(sort keys %$attributes) {
		{
			no warnings "utf8";
			_throw_data_error("illegal attribute name")
				unless /\A$xml10_name_rx\z/o;
		}
		$$rtext .= " ".$_."=\"";
		_serialise_attvalue($rtext, $attributes->{$_});
		$$rtext .= "\"";
	}
	my $twine = $elem->content_twine;
	if(is_ref($twine, "ARRAY") && @$twine == 1 &&
			is_string($twine->[0]) && $twine->[0] eq "") {
		$$rtext .= "/>";
	} else {
		$$rtext .= ">";
		_serialise_twine($rtext, $twine);
		$$rtext .= "</".$type_name.">";
	}
}

=over

=item xml10_write_content(CONTENT)

I<CONTENT> must be a reference to either an L<XML::Easy::Content>
object or a twine array (see L<XML::Easy::NodeBasics/Twine>).
The XML 1.0 textual representation of that content is returned.

=cut

sub xml10_write_content($) {
	my($content) = @_;
	my $text = "";
	_serialise_eithercontent(\$text, $content);
	return $text;
}

=item xml10_write_element(ELEMENT)

I<ELEMENT> must be a reference to an L<XML::Easy::Element> object.
The XML 1.0 textual representation of that element is returned.

=cut

sub xml10_write_element($) {
	my($elem) = @_;
	my $text = "";
	_serialise_element(\$text, $elem);
	return $text;
}

=item xml10_write_document(ELEMENT[, ENCODING])

I<ELEMENT> must be a reference to an L<XML::Easy::Element> object.
The XML 1.0 textual form of a document with that element as the root
element is returned.  The document includes an XML declaration.
If I<ENCODING> is supplied, it must be a valid character encoding
name, and the XML declaration specifies it in an encoding declaration.
(The returned string consists of unencoded characters regardless of the
encoding specified.)

=cut

sub xml10_write_document($;$) {
	my($elem, $encname) = @_;
	my $text = "<?xml version=\"1.0\"";
	if(defined $encname) {
		_throw_data_error("encoding name isn't a string")
			unless is_string($encname);
		{
			no warnings "utf8";
			_throw_data_error("illegal encoding name")
				unless $encname =~ /\A$xml10_encname_rx\z/;
		}
		$text .= " encoding=\"".$encname."\"";
	}
	$text .= " standalone=\"yes\"?>\n";
	_serialise_element(\$text, $elem);
	$text .= "\n";
	return $text;
}

=item xml10_write_extparsedent(CONTENT[, ENCODING])

I<CONTENT> must be a reference to either an L<XML::Easy::Content>
object or a twine array (see L<XML::Easy::NodeBasics/Twine>).
The XML 1.0 textual form of an external
parsed entity encapsulating that content is returned.  If I<ENCODING> is
supplied, it must be a valid character encoding name, and the returned
entity includes a text declaration that specifies the encoding name in
an encoding declaration.  (The returned string consists of unencoded
characters regardless of the encoding specified.)

=cut

sub xml10_write_extparsedent($;$) {
	my($content, $encname) = @_;
	my $text = "";
	if(defined $encname) {
		_throw_data_error("encoding name isn't a string")
			unless is_string($encname);
		{
			no warnings "utf8";
			_throw_data_error("illegal encoding name")
				unless $encname =~ /\A$xml10_encname_rx\z/;
		}
		$text .= "<?xml encoding=\"".$encname."\"?>";
	}
	_serialise_eithercontent(\$text, $content);
	return $text;
}

=back

=head1 SEE ALSO

L<XML::Easy::NodeBasics>,
L<XML::Easy::Syntax>,
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
