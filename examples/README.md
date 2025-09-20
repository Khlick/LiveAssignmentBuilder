# LiveAssignmentBuilder Examples

This directory contains example files demonstrating the LiveAssignmentBuilder parsing syntax and functionality.

## Files

### `example.m`
A comprehensive example that demonstrates all parsing syntax features:

- **Sticky Blocks (`%!`)**: Protected code that students cannot edit
- **Answer Blocks (`%@`)**: Instructor-only content hidden from students
- **Multiline Answer Blocks (`%|@ ... %||@`)**: Areas for student code completion
- **Inline Answer Blocks (`%<@ ... %>@`)**: Single expressions for student completion
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

1. **Run the test script**:
   ```matlab
   cd examples
   run('test_example.m')
   ```

2. **Or use LiveAssignmentBuilder directly**:
   ```matlab
   % Basic usage
   LiveAssignmentBuilder('example.m');
   
   % With options
   LiveAssignmentBuilder( ...
     'example.m', ...
     verbose=true, ...
     output="my_output", ...
     package=false ...
     );
   ```

3. **Check the output**:
   - `example.mlx` - Student worksheet
   - `example_key.mlx` - Instructor key with answers

## Expected Output

The example should generate:

- **Student Worksheet**: Shows the task with answer placeholders, protected code blocks, and instructor comments converted to regular comments
- **Instructor Key**: Shows complete solutions, all instructor notes, and bonus content

## Parsing Syntax Reference

| Syntax | Purpose | Student View | Instructor View |
|--------|---------|--------------|-----------------|
| `%!` | Sticky block | Protected code | Same |
| `%@` | Answer block | Hidden | Visible |
| <code>%&#124;@ ... %&#124;&#124;@</code> | Multiline answers | Answer area | Complete solution |
| `%<@ ... %>@` | Inline answers | Placeholder | Actual answer |
| `%# ... %/#` | Comment block | Stripped content | Regular comments |

## Customization

You can modify `example.m` to:
- Add more complex mathematical functions
- Include additional analysis questions
- Create more advanced programming challenges
- Add visualization components
- Include data analysis tasks

The parsing syntax makes it easy to create educational content that adapts to different audiences (students vs. instructors) while maintaining the same source file.
