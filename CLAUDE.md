# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of Perl utilities for various text processing tasks. The codebase uses modern Perl (v5.38+) with strict/warnings enabled.

## Running Utilities

All Perl scripts are executable and can be run directly:

```bash
./md_toc.pl [options] <markdown_file>
```

Or via the Perl interpreter:

```bash
perl md_toc.pl [options] <markdown_file>
```

## Current Utilities

### md_toc.pl - Markdown Table of Contents Generator

A utility that generates or updates a Table of Contents in Markdown files.

**Usage:**
```bash
# File to file
./md_toc.pl --input_file document.md --output_file document.md
./md_toc.pl -if input.md -of output.md --depth=3

# Using pipes (STDIN/STDOUT)
cat document.md | ./md_toc.pl > output.md
./md_toc.pl -if document.md > output.md
cat document.md | ./md_toc.pl -of output.md

# Help
./md_toc.pl --help          # Show help
./md_toc.pl --man           # Show full manual
```

**Options:**
- `--input_file, -if` - Input markdown file (default: STDIN)
- `--output_file, -of` - Output markdown file (default: STDOUT, can be same as input for in-place)
- `--depth, -d` - Maximum header depth to include (default: 3)
- `--verbose, -v` - Verbose output
- `--help, -h, -?` - Show help message
- `--man` - Show full manual

**Key Implementation Details:**

- Object-oriented structure using package/class pattern
- Uses CRC64 hashing (Digest::CRC) to generate stable, unique anchor names
- Excludes the first H1 header from the TOC (document title)
- Normalizes TOC indentation relative to the minimum header level found
- Inserts TOC after the first level 1 header
- Supports in-place updating of existing TOCs (marked with `<!-- begin TOC -->` and `<!-- end TOC -->`) on separate lines
- Properly handles code blocks to avoid parsing headers within fenced code
- Adds HTML anchors (`<a name="..."></a>`) above headers with smart whitespace handling:
  - Preserves existing blank lines between anchor and header
  - Adds double newline only when needed for proper HTML rendering
- Idempotent: replaces existing anchors instead of duplicating them
- Supports STDIN/STDOUT for pipe operations and text processing workflows
- Uses `Const::Fast` for constant definitions
- Uses `English` module for readable special variables
- POD documentation embedded in the script (accessible via `--man`)

**Architecture:**
1. `get_options()` - Parse command-line options using GetOptions
2. `run()` - Main execution method:
   - Read input from file or STDIN into memory
   - Find the first H1 header to determine TOC insertion point
   - Parse all headers while tracking code block state to avoid false matches
   - Generate TOC entries with CRC64-based anchors (skipping the first H1)
   - Normalize indentation: find minimum header level and adjust all entries relative to it
   - Build TOC with normalized indentation (e.g., H2 becomes level 0, H3 becomes level 1)
   - Replace or insert existing anchors in the document:
     - Skip backwards over blank lines to find existing anchor
     - Preserve spacing if blank lines already exist
     - Add double newline only when needed
   - Find or create TOC section after first H1
   - Write modified content to file or STDOUT

## Development Guidelines

### Perl Version

All scripts require Perl v5.38 or higher. Use `use v5.38;` to enforce this.
Use all the stable features of the version.

### Standard Modules Used

- `Getopt::Long` - Command-line option parsing
- `Pod::Usage` - POD-based help/manual generation
- `Const::Fast` - Compile-time constant definitions
- `English` - Readable names for special variables (e.g., `$INPUT_RECORD_SEPARATOR`)
- `Data::Dumper` - Data structure debugging
- `Digest::CRC` - CRC64 hashing for stable anchor generation

### Script Structure

Each utility should follow this pattern:

1. Shebang: `#!/usr/bin/env perl`
2. Package declaration with version: `package script_name; our $VERSION = "x.y.z";`
3. Pragmas: `use strict; use warnings;`
4. Version requirement: `use v5.38;` (or higher)
5. Module imports (standard library, then CPAN modules)
6. Constants definition using `Const::Fast` (const my $name => value;)
7. Subroutines:
   - `get_options($self)` - Parse and validate command-line options
   - `run()` - Main execution logic
8. Script invocation: `__PACKAGE__->run();`
9. POD documentation in `__END__` section

**Code Style:**
- Use object-oriented method signatures: `sub method_name ($self, $param) { ... }`
- Use postfix dereferencing where appropriate
- Define option lists as constants
- Use meaningful variable names
- Add separating comment blocks (`#***...`) for major sections

### Documentation

All scripts should include embedded POD documentation with:
- NAME
- SYNOPSIS
- DESCRIPTION
- OPTIONS (with detailed explanations)
- EXAMPLES
- AUTHOR

Access documentation via `--man` option or `perldoc <script>`.

### Testing

To test a script, run it with `--help` to verify the POD is properly formatted:

```bash
./md_toc.pl --help
```

For functional testing, create a test markdown file and verify the output.

### Formatting Code

```bash
perltidy --profile=/home/val/perltidy-a.conf "$@"
```

### Analyze Code

```bash
perlcritic --profile=/home/val/perlcritic-a.conf "$@"
```
