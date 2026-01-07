# LiveAssignmentBuilder Examples

This directory contains example files demonstrating the LiveAssignmentBuilder parsing syntax and functionality.

## Files

### `example.m`
A comprehensive example that demonstrates all parsing syntax features:

- **Sticky Blocks (`%!`)**: Protected code that students cannot edit
- **Answer Blocks (`%@`)**: Instructor-only content hidden from students. Behavior controlled by `answerBlockMode`:
  - **Default mode** (`"default"`): Replaces `%@` with `"% ANSWER HERE"` on the line containing `%@`, then marks the next full statement for removal. Handles multi-line statements with `...` (line continuation) by continuing until the last `...` line plus one more line.
  - **Expand mode** (`"expand"`): The line with `%@` and all subsequent lines until `%/@`, `%!`, or `%%` are removed from worksheets.
- **Multiline Answer Blocks (`%|@ ... %||@`)**: Areas for student code completion. Display in key files controlled by `keyDisplayMode` option.
- **Inline Answer Blocks (`%<@ ... %>@`)**: Single expressions for student completion. Display in key files controlled by `keyDisplayMode` option.
- **Comment Blocks (`%# ... %/#`)**: Instructor notes stripped from worksheets but preserved in keys

The example shows a mathematical function evaluation task with:
- Function definition
- Loop-based evaluation
- Data visualization
- Analysis questions
- Optional advanced exercises

### `test_example.m`
A test script that demonstrates how to use the LiveAssignmentBuilder class to convert the example.m file into live scripts.

## Usage
To use the LiveAssignmentBuilder with the provided example files:

1. **Place your `.m` file(s)** (such as `example.m`) in this directory.

2. **From MATLAB**, run:

```matlab
LiveAssignmentBuilder('example.m');
```

You can also customize output options (such as output folder, verbosity, packaging, answer block mode, etc.) using an options structure:

```matlab
% Use default answer block mode (only removes the line with %@)
LiveAssignmentBuilder('example.m', verbose=true, output="output_folder");

% Use expand answer block mode (removes %@ line and all subsequent lines until stop marker)
LiveAssignmentBuilder('example.m', answerBlockMode='expand', verbose=true);

% Control how answer blocks are displayed in key files (applies to inline and multiline blocks)
LiveAssignmentBuilder('example.m', keyDisplayMode='markup');
```

This will generate a student worksheet (`example.mlx`) and an instructor key (`example_key.mlx`) in the specified output folder.

### Answer Block Modes

The `answerBlockMode` option controls how answer blocks (`%@`) are processed:

- **Default mode** (`"default"`): Replaces `%@` with `"% ANSWER HERE"` on the line containing `%@`, then marks the next full statement for removal. This automatically handles single-line statements and multi-line statements with `...` (line continuation). The statement is completely removed from worksheets but remains visible in keys. This is useful when you want to hide complete instructor code statements while keeping the structure clear.

- **Expand mode** (`"expand"`): The line containing `%@` and all subsequent lines until one of `%/@`, `%!`, or `%%` (two or more consecutive `%` symbols) are removed from worksheets. This is useful when you want to hide entire sections of instructor-only code.

### Key Display Modes

The `keyDisplayMode` option controls how answer code is displayed in key files for all answer block types (inline and multiline):

- **Default mode** (`"default"`): Only shows the answer code, no comment annotation. This provides a clean key file with just the solutions.

- **Markup mode** (`"markup"`): Shows the answer code on new lines above the original assignment markup (which is commented out). For multiline blocks, shows answer code followed by commented original structure. This helps instructors see both the solution and what students were asked to complete.

- **Marked mode** (`"marked"`): Shows the answer code followed by a comment with the same code on the same line. This provides clear annotation showing what the answer is.

## Parsing Syntax Reference

| Syntax | Purpose | Student View | Instructor View |
|--------|---------|--------------|-----------------|
| `%!` | Sticky block | Protected code | Same |
| `%@` | Answer block (default mode) | Next statement removed | Full statement visible |
| `%@` ... `%/@` | Answer block (expand mode) | All lines removed | All lines visible |
| <code>%&#124;@ ... %&#124;&#124;@</code> | Multiline answers | Answer area | Complete solution (format controlled by `keyDisplayMode`) |
| `%<@ ... %>@` | Inline answers | Placeholder | Actual answer (format controlled by `keyDisplayMode`) |
| `%# ... %/#` | Comment block | Stripped content | Regular comments |

## Customization

You can modify `example.m` to:
- Add more complex mathematical functions
- Include additional analysis questions
- Create more advanced programming challenges
- Add visualization components
- Include data analysis tasks

The parsing syntax makes it easy to create educational content that adapts to different audiences (students vs. instructors) while maintaining the same source file.
