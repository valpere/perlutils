#!/usr/bin/env perl
package md_toc;

use strict;
use warnings;

use v5.38.2;

our $VERSION = "0.1.0";

#*******************************************************************************************************************************

use Getopt::Long;
use Pod::Usage;
use Const::Fast;
use English qw(-no_match_vars);
use Data::Dumper;

use Digest::CRC qw(crc64);

#*******************************************************************************
const my $default_depth => 3;

const my @_OPTIONS => (
    'help|h|?',
    'man',
    'depth|d=i',
    'verbose|v',
    'input_file|if=s',
    'output_file|of=s',
);

#*******************************************************************************************************************************
sub get_options ($self) {

    my $params = {};
    if (!GetOptions($params, @_OPTIONS)) {
        pod2usage(-verbose => 0, -exitval => 2, -output => \*STDERR, -message => "Invalid option(s)");
    }

    if ($params->{help}) {
        pod2usage(-verbose => 0, -exitval => 2, -output => \*STDERR);
    }

    if ($params->{man}) {
        pod2usage(-verbose => 1, -exitval => 2, -output => \*STDERR);
    }

    if (!$params->{input_file}) {
        $params->{input_file} = '';
    }

    if (!$params->{output_file}) {
        $params->{output_file} = '';
    }

    if (!$params->{depth}) {
        $params->{depth} = $default_depth;
    }

    return $params;
} ## end sub get_options

#*******************************************************************************
sub run {
    my ($self) = @_;

    local $Data::Dumper::Indent   = 2;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Deepcopy = 1;

    my $params = $self->get_options();

    my $input_file = $params->{input_file};

    open my $fh, '<', $input_file or die("Cannot open $input_file: $OS_ERROR\n");
    my @lines = <$fh>;
    close $fh;

    # Find the first level 1 header
    my $first_h1_index = -1;
    my $in_codeblock   = 0;
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ /^```/) {
            $in_codeblock = !$in_codeblock;
            next;
        }
        if (!$in_codeblock && $lines[$i] =~ /^#\s/) {
            $first_h1_index = $i;
            last;
        }
    }

    if ($first_h1_index == -1) {
        die("No level 1 header found in $input_file\n");
    }

    # Parse headers for TOC (skip the first H1)
    my @toc_entries;
    $in_codeblock = 0;
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ /^```/) {
            $in_codeblock = !$in_codeblock;
            next;
        }
        if (!$in_codeblock && $lines[$i] =~ /^(#{1,$params->{depth}})\s+(.+)$/) {
            my $level  = length($1);
            my $text   = $2;
            my $anchor = sprintf("%016x", crc64($text));
            # Skip the first H1 header
            next if ($i == $first_h1_index);
            push(@toc_entries, {level => $level, text => $text, anchor => $anchor, index => $i});
        }
    }

    # Build TOC - adjust indentation relative to minimum level
    my $toc = "\n";
    # Find minimum level to normalize indentation
    my $min_level = $toc_entries[0]{level} if @toc_entries;
    for my $entry (@toc_entries) {
        $min_level = $entry->{level} if $entry->{level} < $min_level;
    }
    for my $entry (@toc_entries) {
        my $indent = '  ' x ($entry->{level} - $min_level);
        $toc .= "$indent- [$entry->{text}](#$entry->{anchor})\n";
    }

    # Place anchors above headers
    for my $entry (sort {$b->{index} <=> $a->{index}} @toc_entries) {
        next if $entry->{index} == $first_h1_index;    # Don't add anchor above the first header

        # Check if the line at this index starts with # (it should be a header)
        if ($lines[$entry->{index}] =~ /^(#{1,})/) {
            my $level_markers = $1;
            # Remove existing anchor and whitespace, then add new anchor
            if ($lines[$entry->{index}] =~ s/^<a name="\w+"><\/a>[\s\n]*\n(#{1,})/$1/) {
                # Anchor was on the same logical line, now add it properly on previous line
                splice @lines, $entry->{index}, 0, "<a name=\"$entry->{anchor}\"></a>\n\n";
            }
            else {
                # Check previous lines for anchor
                my $prev_index = $entry->{index} - 1;
                while (($prev_index >= 0) && $lines[$prev_index] =~ m/^\s*$/) {
                    --$prev_index;
                }
                if (($prev_index >= 0) && ($lines[$prev_index] =~ /<a name="[^"]*"><\/a>/)) {
                    # Replace the anchor line
                    if ($entry->{index} - $prev_index > 1) {
                        $lines[$prev_index] = "<a name=\"$entry->{anchor}\"></a>\n";
                    }
                    else {
                        $lines[$prev_index] = "<a name=\"$entry->{anchor}\"></a>\n\n";
                    }
                }
                else {
                    # No existing anchor, insert new one
                    splice(@lines, $entry->{index}, 0, "<a name=\"$entry->{anchor}\"></a>\n\n");
                }
            } ## end else [ if ($lines[$entry->{index...}])]
        } ## end if ($lines[$entry->{index...}])
    } ## end for my $entry (sort {$b...})

    # Find existing TOC
    my $toc_start = -1;
    my $toc_end   = -1;
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ /<!-- begin TOC -->/) {
            $toc_start = $i;
        }
        elsif ($lines[$i] =~ /<!-- end TOC -->/) {
            $toc_end = $i;
            last;
        }
    }

    if ($toc_start != -1 && $toc_end != -1) {
        # Replace existing TOC
        splice(@lines, $toc_start, $toc_end - $toc_start + 1, "<!-- begin TOC -->$toc<!-- end TOC -->\n");
    }
    else {
        # Insert after first H1
        splice(@lines, $first_h1_index + 1, 0, "<!-- begin TOC -->$toc<!-- end TOC -->\n");
    }

    # Write back to file

    my $output_file = $params->{output_file};
    open $fh, '>', $output_file or die("Cannot write to $output_file: $OS_ERROR\n");
    print {$fh} @lines;
    close $fh;

    return 1;
} ## end sub run

#*******************************************************************************
__PACKAGE__->run();
#*******************************************************************************
__END__

=head1 NAME

md_toc.pl - Generate or update Table of Contents in Markdown files

=head1 SYNOPSIS

md_toc.pl --input_file <input_file> --output_file <output_file> [options]

Options:
    --input_file, -if   Input markdown file (required)
    --output_file, -of  Output markdown file (required, can be same as input)
    --depth, -d         Maximum header depth to include (default: 3)
    --verbose, -v       Verbose output
    --help, -h, -?      Show help message
    --man               Show full manual

=head1 DESCRIPTION

This script reads a Markdown file and generates or updates a Table of Contents (TOC)
directly below the first level 1 header.

Key features:

=over 4

=item * Excludes the first H1 header from the TOC (treats it as document title)

=item * Normalizes indentation relative to minimum header level (e.g., H2 becomes level 0)

=item * Generates stable anchors using CRC64 hashing

=item * Idempotent: safely replaces existing anchors without duplication

=item * Handles code blocks properly (ignores headers inside fenced code blocks)

=item * Smart whitespace handling: preserves existing spacing between anchors and headers

=back

If a TOC already exists (marked with <!-- begin TOC --> and <!-- end TOC --> comments),
it will be replaced. The TOC includes headers up to the specified depth (default: 3).

=head1 OPTIONS

=over 8

=item B<--input_file>, B<-if>

Input markdown file to process. Required.

=item B<--output_file>, B<-of>

Output markdown file. Can be the same as input file for in-place modification. Required.

=item B<--depth>, B<-d>

Specify the maximum header depth to include in the TOC. Default is 3.
For example, --depth=2 will include only H1 and H2 headers.

=item B<--verbose>, B<-v>

Enable verbose output for debugging.

=item B<--help>, B<-h>, B<-?>

Print a brief help message and exit.

=item B<--man>

Print the full manual and exit.

=back

=head1 EXAMPLES

Process a markdown file in-place:

    md_toc.pl --input_file document.md --output_file document.md

Using short options:

    md_toc.pl -if README.md -of README.md

Limit TOC to only H1 and H2 headers:

    md_toc.pl -if doc.md -of doc.md --depth 2

Process with verbose output:

    md_toc.pl -if input.md -of output.md -v

=head1 AUTHOR

Valentyn Solomko

=cut
