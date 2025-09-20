# Changelog

All notable changes to the LiveAssignmentBuilder project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-19

### Added
- **Class-based architecture**: Converted from function-based to class-based implementation
- **Static methods**: Added `version()`, `help()`, `syntax()`, and `examples()` static methods
- **Custom parsing syntax** for educational content:
  - **Sticky Blocks** (`%!`): Mark sections as non-editable for students
  - **Answer Blocks** (`%@`): Instructor-only content hidden in student version
  - **Multiline Answer Blocks** (`%|@ ... %||@`): Sections for student answers
  - **Inline Answer Blocks** (`%<@ ... %>@`): Inline expressions for student answers
  - **Comment Blocks** (`%# ... %/#`): Strip content from worksheets while preserving comments
- **Indentation preservation**: All block types respect and maintain code indentation
- **Custom sticky block comments**: Allow custom comments with `%! comment` syntax
- **Modular parsing architecture**: 
  - `detectBlocks()` method for block detection
  - Specialized parsing methods for each block type
  - Enhanced error handling with custom exceptions
- **Enhanced comment block behavior**:
  - `%/#` lines are entirely removed regardless of additional content
  - Preserves comment text while hiding setup code
  - Supports multiline comment blocks
- **File generation capabilities**:
  - Automatic conversion from `.m` to `.mlx` live scripts
  - Separate worksheet and key file generation
  - Temporary file handling with cleanup
- **Package and distribution features**:
  - ZIP file packaging for distribution
  - Table of contents generation with links
  - Library inclusion support
- **Comprehensive error handling**:
  - Custom exception creation with `exception()` static method
  - Missing end block detection and warnings
  - File validation and error reporting
- **Verbose output mode**: Detailed progress reporting during parsing
- **Script vs function detection**: Automatic identification of input file types

### Changed
- **Parser architecture**: Replaced `parseBlockMarkers()` with modular `detectBlocks()` and specialized parsing methods
- **Comment block processing**: Enhanced to handle nested blocks and proper end detection
- **Inline block processing**: Improved to handle both key and worksheet outputs separately
- **Multiline block processing**: Enhanced end detection with fallback to section breaks
- **Error handling**: Upgraded to use structured exceptions with specific identifiers

### Fixed
- **Block detection**: Fixed issues with block markers not being detected at line beginnings
- **Indentation handling**: Consistent tab-to-space conversion for indentation counting
- **Comment block parsing**: Fixed issues with multiline comments and content stripping
- **End block detection**: Improved reliability of finding corresponding end markers
- **File processing**: Enhanced robustness of temporary file creation and cleanup

### Documentation
- **README.md**: Comprehensive rewrite with:
  - Badge support for MATLAB version compatibility
  - Quick start guide with exact command syntax
  - Detailed parsing architecture explanation
  - Processing flow documentation
  - Enhanced examples with correct syntax
  - Output structure documentation
- **LICENSE**: Added MIT license file
- **Examples**: Enhanced example.m with comprehensive syntax demonstrations

### Technical Details
- **MATLAB compatibility**: Originally developed on R2022a, tested and updated on R2025a
- **Class structure**: Non-handle class with static methods and private properties
- **Method organization**: 
  - Static methods for utility functions and help
  - Constructor for main processing
  - Private methods for internal parsing logic
- **Error handling**: Structured exception system with specific identifiers for different error types

### Breaking Changes
- **Function to class conversion**: Users must now use class syntax instead of function calls
- **Method names**: Some internal method names changed during refactoring
- **Option structure**: Enhanced option validation and error handling

### Migration Guide
For users upgrading from previous versions:
1. Replace function calls with class constructor: `LiveAssignmentBuilder(inputFile, opts)`
2. Use static methods for help: `LiveAssignmentBuilder.help()`
3. Update any custom parsing logic to use new block detection methods
4. Review error handling code for new exception identifiers

---

## Previous Versions

### [Pre-0.1.0] - Development History
- Initial function-based implementation
- Basic parsing syntax support
- Manual file conversion process
- Limited error handling and validation

---

## Contributing

When making changes to this project, please:
1. Update this CHANGELOG.md with your changes
2. Follow the existing format and structure
3. Include both user-facing and technical changes
4. Note any breaking changes clearly
5. Update version numbers according to semantic versioning

## Version Numbering

- **MAJOR** version for incompatible API changes
- **MINOR** version for functionality added in a backwards compatible manner  
- **PATCH** version for backwards compatible bug fixes

## Links

- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [MATLAB Live Scripts](https://www.mathworks.com/help/matlab/matlab_prog/live-scripts.html)
