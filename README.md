# perlutils

A collection of Perl utilities for text processing tasks, built with modern Perl (v5.38+).

## Utilities

### md_toc.pl - Markdown Table of Contents Generator

Generates or updates a Table of Contents in Markdown files with stable CRC64-based anchors.

#### Features

- **Smart TOC Generation**: Excludes first H1 (document title), normalizes indentation
- **Stable Anchors**: Uses CRC64 hashing for consistent anchor names
- **Idempotent**: Safely replaces existing TOCs and anchors without duplication
- **Code Block Aware**: Properly ignores headers inside fenced code blocks
- **Flexible I/O**: Supports files, STDIN/STDOUT, and pipe operations
- **Safe In-Place Editing**: Optional backup creation with `--backup` flag
- **Smart Whitespace**: Preserves existing spacing between anchors and headers

#### Usage

```bash
# Basic in-place editing
./md_toc.pl -if document.md -of document.md

# In-place with backup
./md_toc.pl -if README.md -of README.md --backup

# Using pipes
cat document.md | ./md_toc.pl > output.md

# Limit TOC depth
./md_toc.pl -if doc.md -of doc.md --depth 2

# Verbose mode
./md_toc.pl -if input.md -of output.md -b -v
```

#### Options

- `--input_file, -if` - Input markdown file (default: STDIN)
- `--output_file, -of` - Output markdown file (default: STDOUT)
- `--depth, -d` - Maximum header depth (default: 3)
- `--backup, -b` - Create .bak file for in-place editing
- `--verbose, -v` - Verbose output
- `--help, -h, -?` - Show help message
- `--man` - Show full manual

#### Examples

**Process file and write to different output:**
```bash
./md_toc.pl -if input.md -of output.md
```

**In-place editing with backup:**
```bash
./md_toc.pl -if README.md -of README.md --backup
# Creates README.md.bak with original content
```

**Using in a pipe:**
```bash
cat document.md | ./md_toc.pl > processed.md
```

**Read from file, write to STDOUT:**
```bash
./md_toc.pl -if document.md > output.md
```

**Read from STDIN, write to file:**
```bash
cat document.md | ./md_toc.pl -of output.md
```

## Requirements

- Perl v5.38 or higher
- Standard Perl modules:
  - Getopt::Long
  - Pod::Usage
  - Const::Fast
  - English
  - Data::Dumper
  - File::Copy
  - Digest::CRC

## Installation

```bash
git clone https://github.com/valpere/perlutils.git
cd perlutils
chmod +x md_toc.pl
```

## Development

### Code Quality

Analyze code with perlcritic:
```bash
perlcritic --profile=/home/val/perlcritic-a.conf md_toc.pl
```

Format code with perltidy:
```bash
perltidy --profile=/home/val/perltidy-a.conf md_toc.pl
```

### Documentation

View built-in documentation:
```bash
./md_toc.pl --man
perldoc md_toc.pl
```

## License

See LICENSE file for details.

## Contributing

Contributions are welcome! Please ensure code passes perlcritic and perltidy checks before submitting.
