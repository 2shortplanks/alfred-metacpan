=head1 NAME

XML::Easy::Syntax - excruciatingly correct XML syntax

=head1 SYNOPSIS

	use XML::Easy::Syntax qw($xml10_name_rx);
	if($name =~ /\A$xml10_name_rx\z/o) { ...
	# and many other regular expressions

=head1 DESCRIPTION

This module supplies Perl regular expressions describing the grammar of
XML 1.0.  This is intended to support doing irregular things with XML,
rather than for normal parsing.

These regular expressions encompass the entire XML grammar except for
document type declarations and DTDs.
This document assumes general familiarity with XML.

=cut

package XML::Easy::Syntax;

{ use 5.008; }
use warnings;
use strict;

our $VERSION = "0.009";

use parent "Exporter";
our @EXPORT_OK = qw(
	$xml10_char_rx $xml10_s_rx $xml10_eq_rx
	$xml10_namestartchar_rx $xml10_namechar_rx
	$xml10_name_rx $xml10_names_rx $xml10_nmtoken_rx $xml10_nmtokens_rx
	$xml10_charref_rx $xml10_entityref_rx $xml10_reference_rx
	$xml10_chardata_rx
	$xml10_cdata_rx $xml10_cdstart_rx $xml10_cdend_rx $xml10_cdsect_rx
	$xml10_attvalue_rx $xml10_attribute_rx
	$xml10_stag_rx $xml10_etag_rx $xml10_emptyelemtag_rx
	$xml10_comment_rx $xml10_pitarget_rx $xml10_pi_rx
	$xml10_content_rx $xml10_element_rx
	$xml10_versionnum_rx $xml10_versioninfo_rx
	$xml10_encname_rx $xml10_encodingdecl_rx
	$xml10_sddecl_rx $xml10_xmldecl_rx $xml10_textdecl_rx
	$xml10_misc_rx $xml10_miscseq_rx
	$xml10_prolog_xdtd_rx $xml10_document_xdtd_rx $xml10_extparsedent_rx
);

sub _charclass_regexp($) {
	my($class) = @_;
	$class =~ tr/ \t\n//d;
	return eval("qr/[$class]/");
}

=head1 REGULAR EXPRESSIONS

Each of these regular expressions corresponds precisely to one of
the productions in the EBNF grammar in the XML 1.0 specification.
Well-formedness constraints that are not expressed in the EBNF are
I<not> checked by the regular expressions; these are noted in the
documentation below.  The regular expressions do not include any anchors,
so to check whether an entire string matches a production you must supply
the anchors yourself.

=head2 Syntax pieces

=over

=item $xml10_char_rx

Any single character that is acceptable to XML 1.0.  This includes most
Unicode characters (up to codepoint 0x10ffff).  The excluded codepoints
are the sentinels 0xfffe and 0xffff, the surrogate blocks, and most of
the C0 control characters (0x00 to 0x1f, except for 0x09 (tab), 0x0a
(linefeed/newline), and 0x0d (carriage return)).

It is a rule of XML that all characters making up an XML document
must be in this permitted set.  The grammar productions can only match
sequences of acceptable characters.  This rule is enforced by the regular
expressions in this module.

Furthermore, it is a rule that the character data in a document cannot
even I<represent> a character outside the permitted set.  This is
expressed as a well-formedness constraint on character references.

=cut

our $xml10_char_rx = _charclass_regexp(q(
	\x{9}
	\x{a}
	\x{d}
	\x{20}-\x{d7ff}
	\x{e000}-\x{fffd}
	\x{10000}-\x{10ffff}
));

=item $xml10_s_rx

Any sequence of one or more acceptable whitespace characters.  The
whitespace characters, for this purpose, are tab, linefeed/newline,
carriage return, and space.  Non-ASCII whitespace characters, and the
more exotic ASCII whitespace characters, do not qualify.

=cut

our $xml10_s_rx = qr/[\x{9}\x{a}\x{d}\x{20}]+/;

=item $xml10_eq_rx

Equals sign, surrounded by optional whitespace.

=cut

our $xml10_eq_rx = qr/$xml10_s_rx?=$xml10_s_rx?/o;

=back

=head2 Names

=over

=item $xml10_namestartchar_rx

Any single character that is permitted at the start of a name.
The permitted characters are "B<_>", "B<:>", and letters (categorised
according to Unicode 2.0).

This production is not named in the XML specification.

=cut

our $xml10_namestartchar_rx = _charclass_regexp(q(
	\x{003a}
	\x{0041}-\x{005a}
	\x{005f}
	\x{0061}-\x{007a}
	\x{00c0}-\x{00d6}
	\x{00d8}-\x{00f6}
	\x{00f8}-\x{0131}
	\x{0134}-\x{013e}
	\x{0141}-\x{0148}
	\x{014a}-\x{017e}
	\x{0180}-\x{01c3}
	\x{01cd}-\x{01f0}
	\x{01f4}-\x{01f5}
	\x{01fa}-\x{0217}
	\x{0250}-\x{02a8}
	\x{02bb}-\x{02c1}
	\x{0386}
	\x{0388}-\x{038a}
	\x{038c}
	\x{038e}-\x{03a1}
	\x{03a3}-\x{03ce}
	\x{03d0}-\x{03d6}
	\x{03da}
	\x{03dc}
	\x{03de}
	\x{03e0}
	\x{03e2}-\x{03f3}
	\x{0401}-\x{040c}
	\x{040e}-\x{044f}
	\x{0451}-\x{045c}
	\x{045e}-\x{0481}
	\x{0490}-\x{04c4}
	\x{04c7}-\x{04c8}
	\x{04cb}-\x{04cc}
	\x{04d0}-\x{04eb}
	\x{04ee}-\x{04f5}
	\x{04f8}-\x{04f9}
	\x{0531}-\x{0556}
	\x{0559}
	\x{0561}-\x{0586}
	\x{05d0}-\x{05ea}
	\x{05f0}-\x{05f2}
	\x{0621}-\x{063a}
	\x{0641}-\x{064a}
	\x{0671}-\x{06b7}
	\x{06ba}-\x{06be}
	\x{06c0}-\x{06ce}
	\x{06d0}-\x{06d3}
	\x{06d5}
	\x{06e5}-\x{06e6}
	\x{0905}-\x{0939}
	\x{093d}
	\x{0958}-\x{0961}
	\x{0985}-\x{098c}
	\x{098f}-\x{0990}
	\x{0993}-\x{09a8}
	\x{09aa}-\x{09b0}
	\x{09b2}
	\x{09b6}-\x{09b9}
	\x{09dc}-\x{09dd}
	\x{09df}-\x{09e1}
	\x{09f0}-\x{09f1}
	\x{0a05}-\x{0a0a}
	\x{0a0f}-\x{0a10}
	\x{0a13}-\x{0a28}
	\x{0a2a}-\x{0a30}
	\x{0a32}-\x{0a33}
	\x{0a35}-\x{0a36}
	\x{0a38}-\x{0a39}
	\x{0a59}-\x{0a5c}
	\x{0a5e}
	\x{0a72}-\x{0a74}
	\x{0a85}-\x{0a8b}
	\x{0a8d}
	\x{0a8f}-\x{0a91}
	\x{0a93}-\x{0aa8}
	\x{0aaa}-\x{0ab0}
	\x{0ab2}-\x{0ab3}
	\x{0ab5}-\x{0ab9}
	\x{0abd}
	\x{0ae0}
	\x{0b05}-\x{0b0c}
	\x{0b0f}-\x{0b10}
	\x{0b13}-\x{0b28}
	\x{0b2a}-\x{0b30}
	\x{0b32}-\x{0b33}
	\x{0b36}-\x{0b39}
	\x{0b3d}
	\x{0b5c}-\x{0b5d}
	\x{0b5f}-\x{0b61}
	\x{0b85}-\x{0b8a}
	\x{0b8e}-\x{0b90}
	\x{0b92}-\x{0b95}
	\x{0b99}-\x{0b9a}
	\x{0b9c}
	\x{0b9e}-\x{0b9f}
	\x{0ba3}-\x{0ba4}
	\x{0ba8}-\x{0baa}
	\x{0bae}-\x{0bb5}
	\x{0bb7}-\x{0bb9}
	\x{0c05}-\x{0c0c}
	\x{0c0e}-\x{0c10}
	\x{0c12}-\x{0c28}
	\x{0c2a}-\x{0c33}
	\x{0c35}-\x{0c39}
	\x{0c60}-\x{0c61}
	\x{0c85}-\x{0c8c}
	\x{0c8e}-\x{0c90}
	\x{0c92}-\x{0ca8}
	\x{0caa}-\x{0cb3}
	\x{0cb5}-\x{0cb9}
	\x{0cde}
	\x{0ce0}-\x{0ce1}
	\x{0d05}-\x{0d0c}
	\x{0d0e}-\x{0d10}
	\x{0d12}-\x{0d28}
	\x{0d2a}-\x{0d39}
	\x{0d60}-\x{0d61}
	\x{0e01}-\x{0e2e}
	\x{0e30}
	\x{0e32}-\x{0e33}
	\x{0e40}-\x{0e45}
	\x{0e81}-\x{0e82}
	\x{0e84}
	\x{0e87}-\x{0e88}
	\x{0e8a}
	\x{0e8d}
	\x{0e94}-\x{0e97}
	\x{0e99}-\x{0e9f}
	\x{0ea1}-\x{0ea3}
	\x{0ea5}
	\x{0ea7}
	\x{0eaa}-\x{0eab}
	\x{0ead}-\x{0eae}
	\x{0eb0}
	\x{0eb2}-\x{0eb3}
	\x{0ebd}
	\x{0ec0}-\x{0ec4}
	\x{0f40}-\x{0f47}
	\x{0f49}-\x{0f69}
	\x{10a0}-\x{10c5}
	\x{10d0}-\x{10f6}
	\x{1100}
	\x{1102}-\x{1103}
	\x{1105}-\x{1107}
	\x{1109}
	\x{110b}-\x{110c}
	\x{110e}-\x{1112}
	\x{113c}
	\x{113e}
	\x{1140}
	\x{114c}
	\x{114e}
	\x{1150}
	\x{1154}-\x{1155}
	\x{1159}
	\x{115f}-\x{1161}
	\x{1163}
	\x{1165}
	\x{1167}
	\x{1169}
	\x{116d}-\x{116e}
	\x{1172}-\x{1173}
	\x{1175}
	\x{119e}
	\x{11a8}
	\x{11ab}
	\x{11ae}-\x{11af}
	\x{11b7}-\x{11b8}
	\x{11ba}
	\x{11bc}-\x{11c2}
	\x{11eb}
	\x{11f0}
	\x{11f9}
	\x{1e00}-\x{1e9b}
	\x{1ea0}-\x{1ef9}
	\x{1f00}-\x{1f15}
	\x{1f18}-\x{1f1d}
	\x{1f20}-\x{1f45}
	\x{1f48}-\x{1f4d}
	\x{1f50}-\x{1f57}
	\x{1f59}
	\x{1f5b}
	\x{1f5d}
	\x{1f5f}-\x{1f7d}
	\x{1f80}-\x{1fb4}
	\x{1fb6}-\x{1fbc}
	\x{1fbe}
	\x{1fc2}-\x{1fc4}
	\x{1fc6}-\x{1fcc}
	\x{1fd0}-\x{1fd3}
	\x{1fd6}-\x{1fdb}
	\x{1fe0}-\x{1fec}
	\x{1ff2}-\x{1ff4}
	\x{1ff6}-\x{1ffc}
	\x{2126}
	\x{212a}-\x{212b}
	\x{212e}
	\x{2180}-\x{2182}
	\x{3007}
	\x{3021}-\x{3029}
	\x{3041}-\x{3094}
	\x{30a1}-\x{30fa}
	\x{3105}-\x{312c}
	\x{4e00}-\x{9fa5}
	\x{ac00}-\x{d7a3}
));

=item $xml10_namechar_rx

Any single character that is permitted in a name other than at the start.
The permitted characters are "B<.>", "B<->", "B<_>", "B<:>", and letters,
digits, combining characters, and extenders (categorised according to
Unicode 2.0).

=cut

our $xml10_namechar_rx = _charclass_regexp(q(
	\x{002d}-\x{002e}
	\x{0030}-\x{003a}
	\x{0041}-\x{005a}
	\x{005f}
	\x{0061}-\x{007a}
	\x{00b7}
	\x{00c0}-\x{00d6}
	\x{00d8}-\x{00f6}
	\x{00f8}-\x{0131}
	\x{0134}-\x{013e}
	\x{0141}-\x{0148}
	\x{014a}-\x{017e}
	\x{0180}-\x{01c3}
	\x{01cd}-\x{01f0}
	\x{01f4}-\x{01f5}
	\x{01fa}-\x{0217}
	\x{0250}-\x{02a8}
	\x{02bb}-\x{02c1}
	\x{02d0}-\x{02d1}
	\x{0300}-\x{0345}
	\x{0360}-\x{0361}
	\x{0387}-\x{038a}
	\x{038c}
	\x{038e}-\x{03a1}
	\x{03a3}-\x{03ce}
	\x{03d0}-\x{03d6}
	\x{03da}
	\x{03dc}
	\x{03de}
	\x{03e0}
	\x{03e2}-\x{03f3}
	\x{0401}-\x{040c}
	\x{040e}-\x{044f}
	\x{0451}-\x{045c}
	\x{045e}-\x{0481}
	\x{0483}-\x{0486}
	\x{0490}-\x{04c4}
	\x{04c7}-\x{04c8}
	\x{04cb}-\x{04cc}
	\x{04d0}-\x{04eb}
	\x{04ee}-\x{04f5}
	\x{04f8}-\x{04f9}
	\x{0531}-\x{0556}
	\x{0559}
	\x{0561}-\x{0586}
	\x{0591}-\x{05a1}
	\x{05a3}-\x{05b9}
	\x{05bb}-\x{05bd}
	\x{05bf}
	\x{05c1}-\x{05c2}
	\x{05c4}
	\x{05d0}-\x{05ea}
	\x{05f0}-\x{05f2}
	\x{0621}-\x{063a}
	\x{0641}-\x{0652}
	\x{0660}-\x{0669}
	\x{0670}-\x{06b7}
	\x{06ba}-\x{06be}
	\x{06c0}-\x{06ce}
	\x{06d0}-\x{06d3}
	\x{06e5}-\x{06e8}
	\x{06ea}-\x{06ed}
	\x{06f0}-\x{06f9}
	\x{0901}-\x{0903}
	\x{0905}-\x{0939}
	\x{093e}-\x{094d}
	\x{0951}-\x{0954}
	\x{0958}-\x{0963}
	\x{0966}-\x{096f}
	\x{0981}-\x{0983}
	\x{0985}-\x{098c}
	\x{098f}-\x{0990}
	\x{0993}-\x{09a8}
	\x{09aa}-\x{09b0}
	\x{09b2}
	\x{09b6}-\x{09b9}
	\x{09bc}
	\x{09bf}-\x{09c4}
	\x{09c7}-\x{09c8}
	\x{09cb}-\x{09cd}
	\x{09d7}
	\x{09dc}-\x{09dd}
	\x{09df}-\x{09e3}
	\x{09e6}-\x{09f1}
	\x{0a02}
	\x{0a05}-\x{0a0a}
	\x{0a0f}-\x{0a10}
	\x{0a13}-\x{0a28}
	\x{0a2a}-\x{0a30}
	\x{0a32}-\x{0a33}
	\x{0a35}-\x{0a36}
	\x{0a38}-\x{0a39}
	\x{0a3c}
	\x{0a3f}-\x{0a42}
	\x{0a47}-\x{0a48}
	\x{0a4b}-\x{0a4d}
	\x{0a59}-\x{0a5c}
	\x{0a5e}
	\x{0a70}-\x{0a74}
	\x{0a81}-\x{0a83}
	\x{0a85}-\x{0a8b}
	\x{0a8d}
	\x{0a8f}-\x{0a91}
	\x{0a93}-\x{0aa8}
	\x{0aaa}-\x{0ab0}
	\x{0ab2}-\x{0ab3}
	\x{0ab5}-\x{0ab9}
	\x{0abd}-\x{0ac5}
	\x{0ac7}-\x{0ac9}
	\x{0acb}-\x{0acd}
	\x{0ae0}
	\x{0ae6}-\x{0aef}
	\x{0b01}-\x{0b03}
	\x{0b05}-\x{0b0c}
	\x{0b0f}-\x{0b10}
	\x{0b13}-\x{0b28}
	\x{0b2a}-\x{0b30}
	\x{0b32}-\x{0b33}
	\x{0b36}-\x{0b39}
	\x{0b3d}-\x{0b43}
	\x{0b47}-\x{0b48}
	\x{0b4b}-\x{0b4d}
	\x{0b56}-\x{0b57}
	\x{0b5c}-\x{0b5d}
	\x{0b5f}-\x{0b61}
	\x{0b66}-\x{0b6f}
	\x{0b82}-\x{0b83}
	\x{0b85}-\x{0b8a}
	\x{0b8e}-\x{0b90}
	\x{0b92}-\x{0b95}
	\x{0b99}-\x{0b9a}
	\x{0b9c}
	\x{0b9e}-\x{0b9f}
	\x{0ba3}-\x{0ba4}
	\x{0ba8}-\x{0baa}
	\x{0bae}-\x{0bb5}
	\x{0bb7}-\x{0bb9}
	\x{0bbe}-\x{0bc2}
	\x{0bc6}-\x{0bc8}
	\x{0bca}-\x{0bcd}
	\x{0bd7}
	\x{0be7}-\x{0bef}
	\x{0c01}-\x{0c03}
	\x{0c05}-\x{0c0c}
	\x{0c0e}-\x{0c10}
	\x{0c12}-\x{0c28}
	\x{0c2a}-\x{0c33}
	\x{0c35}-\x{0c39}
	\x{0c3e}-\x{0c44}
	\x{0c46}-\x{0c48}
	\x{0c4a}-\x{0c4d}
	\x{0c55}-\x{0c56}
	\x{0c60}-\x{0c61}
	\x{0c66}-\x{0c6f}
	\x{0c82}-\x{0c83}
	\x{0c85}-\x{0c8c}
	\x{0c8e}-\x{0c90}
	\x{0c92}-\x{0ca8}
	\x{0caa}-\x{0cb3}
	\x{0cb5}-\x{0cb9}
	\x{0cbe}-\x{0cc4}
	\x{0cc6}-\x{0cc8}
	\x{0cca}-\x{0ccd}
	\x{0cd5}-\x{0cd6}
	\x{0cde}
	\x{0ce0}-\x{0ce1}
	\x{0ce6}-\x{0cef}
	\x{0d02}-\x{0d03}
	\x{0d05}-\x{0d0c}
	\x{0d0e}-\x{0d10}
	\x{0d12}-\x{0d28}
	\x{0d2a}-\x{0d39}
	\x{0d3e}-\x{0d43}
	\x{0d46}-\x{0d48}
	\x{0d4a}-\x{0d4d}
	\x{0d57}
	\x{0d60}-\x{0d61}
	\x{0d66}-\x{0d6f}
	\x{0e01}-\x{0e2e}
	\x{0e32}-\x{0e3a}
	\x{0e46}-\x{0e4e}
	\x{0e50}-\x{0e59}
	\x{0e81}-\x{0e82}
	\x{0e84}
	\x{0e87}-\x{0e88}
	\x{0e8a}
	\x{0e8d}
	\x{0e94}-\x{0e97}
	\x{0e99}-\x{0e9f}
	\x{0ea1}-\x{0ea3}
	\x{0ea5}
	\x{0ea7}
	\x{0eaa}-\x{0eab}
	\x{0ead}-\x{0eae}
	\x{0eb2}-\x{0eb9}
	\x{0ebb}-\x{0ebd}
	\x{0ec0}-\x{0ec4}
	\x{0ec6}
	\x{0ec8}-\x{0ecd}
	\x{0ed0}-\x{0ed9}
	\x{0f18}-\x{0f19}
	\x{0f20}-\x{0f29}
	\x{0f35}
	\x{0f37}
	\x{0f39}
	\x{0f3f}-\x{0f47}
	\x{0f49}-\x{0f69}
	\x{0f71}-\x{0f84}
	\x{0f86}-\x{0f8b}
	\x{0f90}-\x{0f95}
	\x{0f97}
	\x{0f99}-\x{0fad}
	\x{0fb1}-\x{0fb7}
	\x{0fb9}
	\x{10a0}-\x{10c5}
	\x{10d0}-\x{10f6}
	\x{1100}
	\x{1102}-\x{1103}
	\x{1105}-\x{1107}
	\x{1109}
	\x{110b}-\x{110c}
	\x{110e}-\x{1112}
	\x{113c}
	\x{113e}
	\x{1140}
	\x{114c}
	\x{114e}
	\x{1150}
	\x{1154}-\x{1155}
	\x{1159}
	\x{115f}-\x{1161}
	\x{1163}
	\x{1165}
	\x{1167}
	\x{1169}
	\x{116d}-\x{116e}
	\x{1172}-\x{1173}
	\x{1175}
	\x{119e}
	\x{11a8}
	\x{11ab}
	\x{11ae}-\x{11af}
	\x{11b7}-\x{11b8}
	\x{11ba}
	\x{11bc}-\x{11c2}
	\x{11eb}
	\x{11f0}
	\x{11f9}
	\x{1e00}-\x{1e9b}
	\x{1ea0}-\x{1ef9}
	\x{1f00}-\x{1f15}
	\x{1f18}-\x{1f1d}
	\x{1f20}-\x{1f45}
	\x{1f48}-\x{1f4d}
	\x{1f50}-\x{1f57}
	\x{1f59}
	\x{1f5b}
	\x{1f5d}
	\x{1f5f}-\x{1f7d}
	\x{1f80}-\x{1fb4}
	\x{1fb6}-\x{1fbc}
	\x{1fbe}
	\x{1fc2}-\x{1fc4}
	\x{1fc6}-\x{1fcc}
	\x{1fd0}-\x{1fd3}
	\x{1fd6}-\x{1fdb}
	\x{1fe0}-\x{1fec}
	\x{1ff2}-\x{1ff4}
	\x{1ff6}-\x{1ffc}
	\x{20d0}-\x{20dc}
	\x{20e1}
	\x{2126}
	\x{212a}-\x{212b}
	\x{212e}
	\x{2180}-\x{2182}
	\x{3005}
	\x{3007}
	\x{3021}-\x{302f}
	\x{3031}-\x{3035}
	\x{3041}-\x{3094}
	\x{3099}-\x{309a}
	\x{309d}-\x{309e}
	\x{30a1}-\x{30fa}
	\x{30fc}-\x{30fe}
	\x{3105}-\x{312c}
	\x{4e00}-\x{9fa5}
	\x{ac00}-\x{d7a3}
));

=item $xml10_name_rx

A name, of the type used to identify element types, attributes, entities,
and other things in XML.

=cut

our $xml10_name_rx = qr/$xml10_namestartchar_rx$xml10_namechar_rx*/o;

=item $xml10_names_rx

A space-separated list of one or more names.

=cut

our $xml10_names_rx = qr/$xml10_name_rx(?:\x{20}$xml10_name_rx)*/o;

=item $xml10_nmtoken_rx

A name-like token, much like a name except that the first character is
no more restricted than the remaining characters.  These tokens play no
part in basic XML syntax, and in the specification are only used as part
of attribute typing.

=cut

our $xml10_nmtoken_rx = qr/$xml10_namechar_rx+/o;

=item $xml10_nmtokens_rx

A space-separated list of one or more name-like tokens.

=cut

our $xml10_nmtokens_rx = qr/$xml10_nmtoken_rx(?:\x{20}$xml10_nmtoken_rx)*/o;

=back

=head2 References

=over

=item $xml10_charref_rx

A numeric character reference (beginning with "B<&#>" and ending with
"B<;>").  There is a non-syntactic well-formedness constraint: the
codepoint is required to be within the Unicode range and to refer to an
acceptable character (as discussed at C<$xml10_char_rx>).

=cut

our $xml10_charref_rx = qr/&#(?:[0-9]+|x[0-9a-fA-F]+);/;

=item $xml10_entityref_rx

A general entity reference (beginning with "B<&>" and ending with "B<;>").
There are non-syntactic well-formedness constraints: the referenced entity
must be declared (possibly implicitly), must not be an unparsed entity,
must not contain a recursive reference to itself, and its replacement
text must itself be well-formed.

=cut

our $xml10_entityref_rx = qr/&$xml10_name_rx;/o;

=item $xml10_reference_rx

Either a character reference or an entity reference.  The well-formedness
constraints of both reference types (see above) apply.

=cut

our $xml10_reference_rx = qr/$xml10_entityref_rx|$xml10_charref_rx/o;

=back

=head2 Character data

=over

=item $xml10_chardata_rx

Ordinary literal character data.  This consists of zero or more acceptable
charaters, other than the metacharacters "B<< < >>" and "B<&>", and
not including "B<< ]]> >>" as a subsequence.  Such data stands for
itself when it appears between the start and end tags of an element,
where it can be interspersed with references, CDATA sections, comments,
and processing instructions.

In the XML grammar, character data is parsed, and taken literally,
I<after> line endings have been canonicalised (to the newline character).
Pre-canonicalisation character data, with variable line endings, will
still match this production but should not be interpreted literally.

Beware that a string that does not match this production might parse as
two adjacent strings each of which matches.  This can happen because
of the prohibition on "B<< ]]> >>" being embedded in character data,
while the characters of that sequence are acceptable individually.
The XML grammar does not allow two instances of this production to abut.

=cut

our $xml10_chardata_rx = qr/(?:
	\]?(?![<&\]])$xml10_char_rx
	|\]{2,}(?![<&\>\]])$xml10_char_rx
)*\]*/xo;

=item $xml10_cdata_rx

Literal character data in a CDATA section.  This consists of zero or
more acceptable charaters, not including "B<< ]]> >>" as a subsequence.
Unlike ordinary literal character data, the characters "B<< < >>" and
"B<&>" are not metacharacters here.  Such data stands for itself when
it appears within a CDATA section.

As with ordinary literal character data (see above), this data is meant
to be taken literally only after line endings have been canonicalised.
Also, as with ordinary literal character data, two instances of this
production should not abut.

=cut

our $xml10_cdata_rx = qr/(?:
	\]?(?!\])$xml10_char_rx
	|\]{2,}(?![\>\]])$xml10_char_rx
)*\]*/xo;

=item $xml10_cdstart_rx

=item $xml10_cdend_rx

The fixed strings "B<< <![CDATA[ >>" and "B<< ]]> >>" which begin and
finish a CDATA section.

=cut

our $xml10_cdstart_rx = qr/<!\[CDATA\[/;
our $xml10_cdend_rx = qr/\]\]>/;

=item $xml10_cdsect_rx

A CDATA section.  This consists of "B<< <![CDATA[ >>", literal character
data with metacharacters disabled, and "B<< ]]> >>".

=cut

# Note: using the $xml10_cdata_rx regexp (from above) here would be much
# less efficient than this use of (?>...).  It would also run into the
# perl bug described in L</BUGS>.

our $xml10_cdsect_rx = qr/(?><!\[CDATA\[$xml10_char_rx*?\]\]>)/o;

=back

=head2 Tags

=over

=item $xml10_attvalue_rx

A quoted attribute value.  This consists of acceptable characters
other than "B<< < >>", "B<&>", and the quote character, interspersed
with references, surrounded by matching "B<">" or "B<'>" quotes.
The well-formedness constraints of references apply, and additionally
the replacement text of any referenced entities must not contain any "B<<
< >>" characters, and it is not permitted to refer to external entities.

=cut

our $xml10_attvalue_rx = qr/"(?:(?![<&"])$xml10_char_rx|$xml10_reference_rx)*"
			   |'(?:(?![<&'])$xml10_char_rx|$xml10_reference_rx)*'
			   /xo;

=item $xml10_attribute_rx

A complete attribute, consisting of name, equals sign, and quoted value.
The well-formedness constraints of attribute values (pertaining to
references) apply.

=cut

our $xml10_attribute_rx = qr/$xml10_name_rx$xml10_eq_rx$xml10_attvalue_rx/o;

=item $xml10_stag_rx

A start-tag, used to begin an element.  This consists of "B<< < >>",
the element type name, whitespace-separated list of attributes, and "B<<
> >>".  The well-formedness constraints of attribute values (pertaining
to references) apply.  There is also a well-formedness constraint that
attribute names must be unique within the tag.

=cut

our $xml10_stag_rx = qr#<$xml10_name_rx
			(?:$xml10_s_rx$xml10_attribute_rx)*
			$xml10_s_rx?>#xo;

=item $xml10_etag_rx

An end-tag, used to finish an element.  This consists of "B<< </ >>",
the element type name, and "B<< > >>".

=cut

our $xml10_etag_rx = qr#</$xml10_name_rx$xml10_s_rx?>#o;

=item $xml10_emptyelemtag_rx

An empty-element tag, used to represent an element with no content.
This consists of "B<< < >>", the element type name, whitespace-separated
list of attributes, and "B<< /> >>".  The well-formedness constraints
of attribute values (pertaining to references) apply.  There is also a
well-formedness constraint that attribute names must be unique within
the tag.  (These are the same constraints as for start-tags.)

=cut

our $xml10_emptyelemtag_rx = qr#<$xml10_name_rx
				(?:$xml10_s_rx$xml10_attribute_rx)*
				$xml10_s_rx?/>#xo;

=back

=head2 Non-data content

=over

=item $xml10_comment_rx

A comment.  This does not contribute to the data content of an
XML document.  It consists of "B<< <!-- >>", zero or more acceptable
characters, and "B<< --> >>".  It is not permitted for the content to
include "B<-->" as a subsequence, nor for it to end with "B<->".

=cut

# Note perl bug: the theoretically-cleaner way of expressing this syntax,
# /<!--(?:-?(?!-)$xml10_char_rx)*-->/, runs into a problem where the
# "*" acts as "{0,32767}", discussed in L</BUGS>, and so fails to match
# longer comments.  The way that is used here, with a sufficiently simple
# expression inside the "*", doesn't run into that problem, but instead
# relies on the (?>...) together with the non-greedy quantifier for
# proper parsing.  It is important for this regexp to not suffer from
# this bug, because it is used in the pure-Perl parser.

our $xml10_comment_rx = qr/<!--(?>$xml10_char_rx*?--)>/o;

=item $xml10_pitarget_rx

A processing instruction target name.  This can be any name (the
C<$xml10_name_rx> production) except for "B<xml>" and its case variations.

=cut

our $xml10_pitarget_rx = qr/(?![Xx])$xml10_name_rx
			   |[Xx](?:(?![Mm])$xml10_namechar_rx+)?
			   |[Xx][Mm](?:(?![Ll])$xml10_namechar_rx+)?
			   |[Xx][Mm][Ll]$xml10_namechar_rx+
			   /xo;

=item $xml10_pi_rx

A processing instruction.  This consists of "B<< <? >>", a target name,
some content which can be almost any sequence of acceptable characters,
and "B<< ?> >>".  A processing instruction does not contribute to the data
content of an XML document, but is intended to carry metadata regarding
how to process it.  The instruction is addressed to a particular XML
processor, or type of processor, identified by the target name, and
the content of the instruction is expected to be meaningful only to
its target.

No one has ever come up with a good use for processing instructions.
They are best shunned.

=cut

our $xml10_pi_rx = qr/(?>
	<\?
	(?![Xx][Mm][Ll](?!$xml10_namechar_rx))$xml10_name_rx
	(?:$xml10_s_rx$xml10_char_rx*?)?
	\?>
)/xo;

=back

=head2 Recursive structure

=over

=item $xml10_content_rx

The matter contained within an element (between its start-tag and
end-tag).  This consists of stretches of ordinary literal character
data, interspersed with complete elements (recursively), references,
CDATA sections, processing instructions, and comments, in any order.
The well-formedness constraints of references and elements apply.

=cut

our $xml10_content_rx;
{
	use re "eval";
	$xml10_content_rx = qr/$xml10_chardata_rx(?:(?:
		(??{$XML::Easy::Syntax::xml10_element_rx})
		|$xml10_reference_rx|$xml10_cdsect_rx
		|$xml10_pi_rx|$xml10_comment_rx
	)$xml10_chardata_rx)*/xo;
}

=item $xml10_element_rx

A complete element.  This is either an empty-element tag, or a
sequence of start-tag, content, and end-tag.  The well-formedness
constraints regarding references and attribute uniqueness apply in the
empty-element tag or start-tag.  In the non-empty form, the content also
has well-formedness constraints regarding references and (recursively)
contained elements, and there is an additional constraint that the
element type name in the end-tag must match that in the start-tag.

=cut

our $xml10_element_rx = qr/$xml10_emptyelemtag_rx
			  |$xml10_stag_rx$xml10_content_rx$xml10_etag_rx
			  /xo;

=back

=head2 XML declarations

=over

=item $xml10_versionnum_rx

The version number of the XML specification.  This is the fixed string
"B<1.0>".

=cut

our $xml10_versionnum_rx = qr/1\.0/;

=item $xml10_versioninfo_rx

The version declaration part of an XML declaration.

=cut

our $xml10_versioninfo_rx = qr/${xml10_s_rx}version$xml10_eq_rx
			(?:'$xml10_versionnum_rx'|"$xml10_versionnum_rx")/xo;

=item $xml10_encname_rx

A character encoding name.  This must start with an ASCII letter, and
contain only ASCII letters and digits and "B<.>", "B<_>", and "B<->".

=cut

our $xml10_encname_rx = qr/[A-Za-z](?:[A-Za-z0-9._\-])*/;

=item $xml10_encodingdecl_rx

The encoding declaration part of an XML declaration.

=cut

our $xml10_encodingdecl_rx = qr/${xml10_s_rx}encoding$xml10_eq_rx
				(?:'$xml10_encname_rx'|"$xml10_encname_rx")/xo;

=item $xml10_sddecl_rx

The standaloneness declaration part of an XML declaration.  This indicates
whether the XML document can be correctly interpreted without examining
the external part of the DTD.

=cut

our $xml10_sddecl_rx = qr/${xml10_s_rx}standalone$xml10_eq_rx
			  (?:'(?:yes|no)'|"(?:yes|no)")/xo;

=item $xml10_xmldecl_rx

An XML declaration, as used at the start of an XML document.  This
consists of "B<< <?xml >>", mandatory version declaration, optional
encoding declaration, optional standaloneness declaration, and "B<<
?> >>".

=cut

our $xml10_xmldecl_rx = qr/<\?xml
	$xml10_versioninfo_rx
	$xml10_encodingdecl_rx?
	$xml10_sddecl_rx?
	$xml10_s_rx?
\?>/xo;

=item $xml10_textdecl_rx

A text declaration, as used at the start of an XML external parsed
entity or external DTD.  This consists of "B<< <?xml >>", optional
version declaration, mandatory encoding declaration, and "B<< ?> >>".
This is very similar to an XML declaration, but technically a different
item and used in different situations.  It is possible, and useful, to
construct a declaration which is acceptable both as an XML declaration
and as a text declaration.

=cut

our $xml10_textdecl_rx = qr/<\?xml
	$xml10_versioninfo_rx?
	$xml10_encodingdecl_rx
	$xml10_s_rx?
\?>/xo;

=back

=head2 Document structure

=over

=item $xml10_misc_rx

Non-content item permitted in the prologue and epilogue of a document.
This is either a comment, a processing instruction, or a stretch of
whitespace.

Beware in using a pattern such as C<$xml10_misc_rx*>.  It could match
a string of whitespace charaters in many ways, leading to exponential
behaviour if it becomes necessary to backtrack.  This can be avoided by
using the C<$xml10_miscseq_rx> pattern (below).

=cut

our $xml10_misc_rx = qr/$xml10_comment_rx|$xml10_pi_rx|$xml10_s_rx/o;

=item $xml10_miscseq_rx

A sequence (possibly empty) of non-content matter permitted in the
prologue and epilogue of a document.  This can contain comments,
processing instructions, and whitespace, in any order.

This production is not named in the XML specification.  This regular
expression should be preferred over C<$xml10_misc_rx*> (which is the
direct translation of what appears in the XML specification), because
this one guarantees to match a particular text in only one way, and is
thus able to backtrack cleanly.

=cut

our $xml10_miscseq_rx = qr/$xml10_s_rx?
			   (?:(?:$xml10_comment_rx|$xml10_pi_rx)
			      $xml10_s_rx?)*/xo;

=item $xml10_prolog_xdtd_rx

Document prologue, except for not permitting a document type declaration.
This consists of an optional XML declaration followed by any sequence
of comments, processing instructions, and whitespace.

=cut

our $xml10_prolog_xdtd_rx = qr/$xml10_xmldecl_rx?$xml10_miscseq_rx/o;

=item $xml10_document_xdtd_rx

A complete XML document, except for not permitting a document type
declaration.  This consists of a non-content prologue, an element
(the root element, which can recursively contain other elements), and
a non-content epilogue.  The well-formedness constraints of elements
apply to the root element.

=cut

our $xml10_document_xdtd_rx = qr/$xml10_prolog_xdtd_rx$xml10_element_rx
				 $xml10_miscseq_rx/xo;

=item $xml10_extparsedent_rx

A complete external parsed entity.  This consists of an optional text
declaration followed by a sequence of content of the same type that is
permitted within an element.  The well-formedness constraints of element
content apply.

=cut

our $xml10_extparsedent_rx = qr/$xml10_textdecl_rx?$xml10_content_rx/o;

=back

=head1 BUGS

Many of these regular expressions are liable to tickle a serious bug in
perl's regexp engine.  The bug is that the C<*> and C<+> repeat operators
don't always match an unlimited number of repeats: in some cases they are
limited to 32767 iterations.  Whether this bogus limit applies depends
on the complexity of the expression being repeated, whether the string
being examined is internally encoded in UTF-8, and the version of perl.
In some cases, but not all, a false match failure is preceded by a warning
"Complex regular subexpression recursion limit (32766) exceeded".

This bug is present, in various forms, in all perl versions up to at
least 5.8.9 and 5.10.0.  Pre-5.10 perls may also overflow their stack
space, in similar circumstances, if a resource limit is imposed.

There is no known feasible workaround for this perl bug.  The regular
expressions supplied by this module will therefore, unavoidably, fail
to accept some lengthy valid inputs.  Where this occurs, though, it is
likely that other regular expressions being applied to the same or related
input will also suffer the same problem.  It is pervasive.  Do not rely
on this module (or perl) to process long inputs on affected perl versions.

This bug does not affect the L<XML::Easy::Text> parser.

=head1 SEE ALSO

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
