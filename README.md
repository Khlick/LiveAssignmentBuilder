# LiveAssignmentBuilder

[![MATLAB](https://img.shields.io/badge/MATLAB-R2022a+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Tested](https://img.shields.io/badge/Tested-R2025a-green.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**LiveAssignmentBuilder** is a MATLAB utility designed to simplify the creation of live scripts for assignments, tasks, or instructional materials. It converts `.m` files into MATLAB live scripts (`.mlx`), automatically generating worksheets for students and answer keys for instructors, with clear indications for student responses. Additionally, it can create a table of contents with links to each generated live script and package the outputs for easy distribution.

## Features

- **Convert MATLAB Scripts**: Transforms MATLAB `.m` files into organized live scripts (`.mlx`) for both worksheets and answer keys.
- **Custom Parsing Syntax**: Supports custom syntax to separate answer blocks, sticky content, and areas for student input.
- **Comment Block Support**: Strips designated content from student worksheets while preserving instructor notes.
- **Build Table of Contents**: Automatically generates a CONTENTS live script that organizes and links all generated live scripts.
- **Packaging**: Packages the generated live scripts and contents into a ZIP file for easy distribution.
- **Configurable Options**: Allows customization of input files, output directories, inclusion of libraries, and more via various options.
- **Class-Based Interface**: Provides static methods for version information and help documentation.

## Installation

To use LiveAssignmentBuilder, download the repository and add the folder to your MATLAB path:

```matlab
addpath('path_to_LiveAssignmentBuilder');
```

## Quick Start

To run the example from the root directory:

```matlab
LiveAssignmentBuilder("example.m", root=fullfile(cd, "examples"), output=fullfile(cd, "examples", "target"));
```

This will process the `example.m` file in the `examples` directory and generate the output files in `examples/target`.

## Usage

### Basic Syntax

```matlab
obj = LiveAssignmentBuilder(inputFile, opts)
```

### Arguments

- `inputFile`: A string or array of strings specifying the input `.m` files to be parsed. If set to `"none"`, the function will parse all `.m` files in the specified root directory.
- `opts`: A structure of optional arguments.

### Options (`opts`)

- `root` (string, default: `"."`): Root directory where the input files are located.
- `output` (string, default: `"."`): Directory where the output files will be saved.
- `libs` (string, default: `""`): Path to additional libraries to include in the package.
- `verbose` (logical, default: `false`): If true, prints detailed progress and status messages.
- `package` (logical, default: `false`): If true, packages the generated outputs into a ZIP file.
- `buildContents` (logical, default: `false`): If true, generates a CONTENTS live script with links to all generated live scripts.
- `executeKey` (logical, default: `false`): If true, executes the generated key files to verify their functionality.
- `answerBlockMode` (string, default: `"default"`): Controls how answer blocks (`%@`) are processed:
  - `"default"`: Replaces `%@` with `"% ANSWER HERE"` on the line containing `%@`, then marks the next full statement for removal. If the next line uses `...` (line continuation), it continues until the last line with `...` and then marks one additional line, capturing complete multi-line statements.
  - `"expand"`: The line containing `%@` and all subsequent lines until `%/@`, `%!`, or `%%` (two or more consecutive `%` symbols) are marked for removal.

### Static Methods

- `LiveAssignmentBuilder.version()` - Display version information
- `LiveAssignmentBuilder.help()` - Display help documentation (equivalent to `doc LiveAssignmentBuilder`)
- `LiveAssignmentBuilder.syntax()` - Display syntax and usage information
- `LiveAssignmentBuilder.examples()` - Display detailed usage examples

### Examples

#### Example 1: Basic Usage

Convert specific `.m` files into live scripts in the specified output directory:

```matlab
obj = LiveAssignmentBuilder("file1.m", "file2.m");
```

#### Example 2: Run the Example File

Process the example file with verbose output:

```matlab
obj = LiveAssignmentBuilder("example.m", root=fullfile(cd, "examples"), output=fullfile(cd, "examples", "target"), verbose=true);
```

#### Example 3: Build with Table of Contents

Build live scripts and generate a table of contents:

```matlab
obj = LiveAssignmentBuilder("none", buildContents=true, verbose=true);
```

#### Example 4: Package the Build

Generate live scripts and package them with additional libraries:

```matlab
obj = LiveAssignmentBuilder("task1.m", output='./output_directory', libs='./path/to/libs', package=true);
```

#### Example 7: Using Answer Block Modes

Use default mode (only mark the line with `%@` for removal):

```matlab
obj = LiveAssignmentBuilder("example.m", answerBlockMode='default');
```

Use expand mode (remove `%@` line and all subsequent lines until stop marker):

```matlab
obj = LiveAssignmentBuilder("example.m", answerBlockMode='expand');
```

**Answer Block Example (Default Mode):**

```matlab
% Regular code that students see
%@ Optional instructor code
debugVar = true;
% More code that students see
```

**Worksheet Output:**
```matlab
% Regular code that students see
% ANSWER HERE
% More code that students see
```

**Key Output:**
```matlab
% Regular code that students see
% Optional instructor code
debugVar = true;
% More code that students see
```

**Answer Block Example (Default Mode with Line Continuation):**

```matlab
% Regular code that students see
%@ Complex calculation
result = someFunction(arg1, ...
    arg2, ...
    arg3);
% More code that students see
```

**Worksheet Output:**
```matlab
% Regular code that students see
% ANSWER HERE
% More code that students see
```

**Key Output:**
```matlab
% Regular code that students see
% Complex calculation
result = someFunction(arg1, ...
    arg2, ...
    arg3);
% More code that students see
```

**Answer Block Example (Expand Mode):**

```matlab
% Regular code that students see
%@ Optional instructor section
debugVar = true;
tempData = load('instructor_data.mat');
% More code that students see
```

**Worksheet Output:**
```matlab
% Regular code that students see
% More code that students see
```

**Key Output:**
```matlab
% Regular code that students see
% Optional instructor section
debugVar = true;
tempData = load('instructor_data.mat');
% More code that students see
```

#### Example 5: Get Version Information

```matlab
LiveAssignmentBuilder.version()
```

#### Example 6: Display Help

```matlab
LiveAssignmentBuilder.help()
% or
LiveAssignmentBuilder.syntax()
% or
LiveAssignmentBuilder.examples()
```

## How It Works

**LiveAssignmentBuilder** uses a sophisticated parsing system that processes MATLAB `.m` files in multiple phases to generate both student worksheets and instructor keys. Here's how the parsing works:

### Parsing Architecture

The parser uses a modular approach with specialized methods for each block type:

1. **Block Detection**: The `detectBlocks()` method identifies block markers (`%!`, `%@`, `%#`, etc.) and their indentation
2. **Block Processing**: Specialized methods (`parseStickyBlocks()`, `parseAnswerBlocks()`, etc.) handle each block type
3. **Content Separation**: Content is split into key and worksheet versions
4. **File Generation**: MATLAB's `openAndSave()` converts processed `.m` files to `.mlx` live scripts

### Custom Parsing Syntax

The parser recognizes the following block types:

- **Sticky Blocks** (`%!`): Sections marked as non-editable for students. Use `%! comment` to provide custom comments.
- **Answer Blocks** (`%@`): Instructor-only content that is hidden in the student version. Behavior controlled by `answerBlockMode` option:
  - **Default mode** (`"default"`): Replaces `%@` with `"% ANSWER HERE"` on the line containing `%@`, then marks the next full statement for removal. Handles multi-line statements with `...` (line continuation) by continuing until the last `...` line plus one more line.
  - **Expand mode** (`"expand"`): The line with `%@` and all subsequent lines until `%/@`, `%!`, or `%%` are removed from worksheets.
  
  **Note**: Answer blocks in comment lines are ignored. If the first non-whitespace character before `%@` is `%` (e.g., `% %@ comment`), the block is left unchanged.
- **Multiline Answer Blocks** (`%|@ ... %||@`): Sections where students are expected to provide answers. Respects indentation.
- **Inline Answer Blocks** (`%<@ ... %>@`): Inline expressions for student answers or hidden solutions. Respects indentation.
- **Comment Blocks** (`%# ... %/#`): Strips content from worksheets but preserves comment text. In keys, converts to regular comments. Respects indentation.

### Enhanced Features

#### Custom Sticky Block Comments
You can provide custom comments for sticky blocks:

```matlab
%! Protected variable setup
new_x = 1:0.1:3;

%! Visualization code  
figure; plot(x, y);
```

If no comment is provided, defaults to "DO NOT MODIFY THE FOLLOWING".

#### Indentation Preservation
All parsing syntax respects code indentation:

```matlab
idx = 0;
while idx < 10
    %# Don't forget to increment your iterator!
    idx = idx + 1;
    %/#
    
    if idx > 5
        %|@ Complete this calculation
        result = idx * 2;
        %||@
    end
end
```

#### Comment Block End Tags
The `%/#` end tag removes the entire line regardless of additional content:

```matlab
%# This comment will be preserved
%# But this line with extra content will be removed entirely
some_code_to_hide();
%/# This entire line is removed
```

### Comment Block Syntax

Comment blocks allow you to include instructor-only notes and hide setup code from students:

```matlab
% Regular code that students will see

%# This is an instructor note that will appear as a regular comment
%# Another instructor note line
%# These comments will be visible to both students and instructors

% Setup code that students shouldn't see
debugVar = true;
tempData = load('instructor_data.mat');

%/# End of instructor-only section

% More code that students will see
```

**Worksheet Output**: Students see only the comment text (without the `#`) and the code outside the comment block:
```matlab
% Regular code that students will see

% This is an instructor note that will appear as a regular comment
% Another instructor note line
% These comments will be visible to both students and instructors

% More code that students will see
```

**Key Output**: Instructors see the full code with comment markers converted to regular comments:
```matlab
% Regular code that students will see

% This is an instructor note that will appear as a regular comment
% Another instructor note line
% These comments will be visible to both students and instructors

% Setup code that students shouldn't see
debugVar = true;
tempData = load('instructor_data.mat');

% More code that students will see
```

### Multiline Comment Blocks

You can also create multiline comment blocks with consecutive comment lines:

```matlab
%# Use this section to set up variables
%# Here is another comment line
%# And these should continue until we reach
%# the termination.
% some code
% we want to strip
% so the student doesn't see it in the assignment
% but the key sees it.
%/# 
```

### Processing Flow

1. **File Reading**: Source `.m` files are read and converted to string arrays
2. **Block Detection**: All block markers are detected with their positions and indentation
3. **Sequential Processing**: Blocks are processed in order:
   - Sticky blocks (`%!`) → Convert to protected comments
   - Answer blocks (`%@`) → Mark for removal from worksheet
   - Multiline answer blocks (`%|@ ... %||@`) → Mark for removal from worksheet
   - Comment blocks (`%# ... %/#`) → Mark for removal from worksheet
   - Inline answer blocks (`%<@ ... %>@`) → Process for both key and worksheet
4. **Content Separation**: Content is split into key and worksheet versions
5. **File Generation**: Processed content is written to temporary `.m` files and converted to `.mlx`

### Error Handling

The parser includes comprehensive error handling:
- Missing end blocks throw exceptions with specific identifiers
- Invalid file paths are reported and skipped
- Parsing errors are caught and reported with context

## Class Interface

The LiveAssignmentBuilder is implemented as a class with the following static methods:

### Static Methods

- **`version()`** - Display version information including version number, author, year, and license
- **`help()`** - Display help documentation (equivalent to `doc LiveAssignmentBuilder`)
- **`syntax()`** - Display syntax and usage information
- **`examples()`** - Display detailed usage examples and parsing syntax

### Usage Examples

```matlab
% Get version information
LiveAssignmentBuilder.version()

% Display help
LiveAssignmentBuilder.help()

% Get syntax information
LiveAssignmentBuilder.syntax()

% See examples
LiveAssignmentBuilder.examples()

% Use the constructor (same as before)
obj = LiveAssignmentBuilder("file1.m", "file2.m");
```

## Output Structure

When you run LiveAssignmentBuilder, it creates the following output structure:

```
target/
├── example.mlx          # Student worksheet
├── example_key.mlx      # Instructor key
└── _pkg/                # Package directory (if packaging enabled)
    ├── example.mlx
    ├── example_key.mlx
    └── CONTENTS.mlx     # Table of contents (if buildContents enabled)
```

## Contribution and Support

Contributions are welcome to enhance LiveAssignmentBuilder. If you encounter any issues or have suggestions, please submit them via GitHub issues.

## License

This project is licensed under the MIT License - see the LICENSE file for more details.

## Versioning

This version (v0.2.0) was written on MATLAB 2022b and tested on 2025a.
