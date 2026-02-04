# Contributing to ga_sync

First off, thank you for considering contributing to ga_sync! It's people like you that make ga_sync such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (config files, spreadsheet structure, etc.)
- **Describe the behavior you observed and what you expected**
- **Include your environment** (Dart version, OS, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List any alternatives you've considered**

### Pull Requests

1. **Fork the repo** and create your branch from `main`
2. **Install dependencies**: `dart pub get`
3. **Make your changes**
4. **Add tests** for any new functionality
5. **Ensure tests pass**: `dart test`
6. **Ensure code passes analysis**: `dart analyze`
7. **Format your code**: `dart format .`
8. **Commit your changes** with a descriptive commit message
9. **Push to your fork** and submit a pull request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ga_sync.git
cd ga_sync

# Install dependencies
dart pub get

# Run tests
dart test

# Run analysis
dart analyze

# Format code
dart format .

# Run the CLI locally
dart run bin/ga_sync.dart --help
```

## Project Structure

```
ga_sync/
├── bin/
│   └── ga_sync.dart          # CLI entry point
├── lib/
│   ├── ga_sync.dart          # Library exports
│   └── src/
│       ├── commands/         # CLI commands
│       ├── config/           # Configuration handling
│       ├── generators/       # Code generators
│       ├── models/           # Data models
│       ├── parsers/          # Route parsers
│       └── sheets/           # Google Sheets API
├── test/                     # Tests
└── example/                  # Example workflows
```

## Coding Guidelines

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use Dart 3 features (switch expressions, patterns, etc.)
- Write tests for new functionality
- Keep functions small and focused
- Use meaningful variable and function names
- Add documentation comments for public APIs

## Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Use prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Limit the first line to 72 characters or less

Examples:
```
feat: add support for optional parameters
fix: handle empty spreadsheet gracefully
docs: update README with new examples
refactor: simplify route parser logic
test: add tests for event validation
chore: update dependencies
```

## Running Tests

```bash
# Run all tests
dart test

# Run with coverage
dart test --coverage=coverage
```

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

Thank you for contributing! 🎉
