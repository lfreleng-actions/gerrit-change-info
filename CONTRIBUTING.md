<!--
SPDX-License-Identifier: Apache-2.0
SPDX-FileCopyrightText: 2025 The Linux Foundation
-->

# Contributing to Gerrit Change Info Action

Thank you for your interest in contributing to the Gerrit Change Info
GitHub Action! This document provides guidelines and information for
contributors.

## 🚀 Getting Started

### Prerequisites

- Bash shell environment
- Git
- Access to a Gerrit instance for testing (optional)
- Basic understanding of GitHub Actions

### Development Setup

1. **Fork and Clone**

   ```bash
   git clone https://github.com/YOUR_USERNAME/gerrit-change-info.git
   cd gerrit-change-info
   ```

2. **Install Development Tools**

   ```bash
   # Install pre-commit hooks
   pip install pre-commit
   <!-- write-good-disable no-repeat -->
   pre-commit install -t commit-msg
   <!-- write-good-enable no-repeat -->

   # Install required tools (if not already available)
   # - shellcheck (for shell script linting)
   # - yamllint (for YAML validation)
   # - jq (for JSON processing)
   ```

3. **Verify Setup**

   ```bash
   # Run pre-commit checks
   pre-commit run --all-files

   # Test shell scripts
   shellcheck .github/scripts/*.sh
   ```

## 🛠️ Development Workflow

### Making Changes

1. **Create a Feature Branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**
   - Follow existing code style and conventions
   - Add appropriate error handling
   - Update documentation if needed

3. **Test Your Changes**
   - Run pre-commit hooks: `pre-commit run --all-files`
   - Test shell scripts manually
   - Verify the GitHub Action works locally

4. **Commit Your Changes**

   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

### Commit Message Guidelines

We follow conventional commit format:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks
- `test:` - Test additions or modifications
- `refactor:` - Code refactoring

Examples:

```text
feat: add timeout handling for SSH connections
fix: resolve URL parsing for complex project names
docs: update README with troubleshooting section
```

## 🧪 Testing

### Local Testing

1. **Shell Script Testing**

   ```bash
   # Test URL extraction
   .github/scripts/extract_ssh_inputs.sh "https://gerrit.example.org/c/project/+/12345"

   # Verify output
   cat gerrit_ssh_info.env
   ```

2. **Path Prefix Feature Testing**

   ```bash
   # Test with default path
   mkdir -p test-workspace && cd test-workspace
   ../.github/scripts/extract_ssh_inputs.sh "https://gerrit.example.org/c/project/+/12345"

   # Test with custom directory
   mkdir -p custom-dir && cd custom-dir
   ../../.github/scripts/extract_ssh_inputs.sh "https://gerrit.example.org/c/project/+/12345"

   # Verify files appear in correct locations
   ls -la */gerrit_ssh_info.env
   ```

3. **Action Testing**
   - The GitHub Action tests run automatically on push/PR
   - Tests run with `continue-on-error: true` to prevent CI failures when
     secrets are unavailable
   - Use `.github/workflows/testing.yml` to test path_prefix

### Integration Testing

The repository includes comprehensive integration tests:

- **Valid input testing** - Tests with real Gerrit URLs
- **Error condition testing** - Tests missing credentials and invalid URLs
- **Output validation** - Verifies action produces expected outputs
- **Path prefix testing** - Tests default paths, custom directories, and error conditions

## 📝 Documentation

### Code Documentation

- Add comments for complex logic
- Include usage examples in scripts
- Document function parameters and return values

### README Updates

When adding features, update:

- Input/output tables
- Usage examples
- Implementation details section

## 🔒 Security Considerations

### Security Guidelines

- **Never commit secrets** - Use repository secrets for sensitive data
- **Check all inputs** - Check for injection attacks
- **Use secure defaults** - Enable StrictHostKeyChecking for SSH
- **Add timeouts** - Prevent hanging operations

### SSH Security

- Always check known_hosts entries
- Use timeout for SSH operations
- Avoid exposing private keys in logs
- Check SSH usernames and hostnames

## 🐛 Bug Reports

### Before Reporting

1. Check existing issues
2. Verify it's not a configuration problem
3. Test with minimal reproduction case

### Issue Template

```markdown
**Bug Description**
Clear description of the issue

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- OS: [e.g., Ubuntu 22.04]
- Gerrit Version: [if known]
- Action Version: [tag or commit]

**Reproduction Steps**
1. Step 1
2. Step 2
3. See error

**Logs/Screenshots**
Include relevant logs (redact sensitive information)
```

## ✨ Feature Requests

### Request Guidelines

- Describe the use case
- Explain how it would benefit users
- Consider backward compatibility
- Provide implementation suggestions if possible

## 📋 Pull Request Process

### Before Submitting

- [ ] Tests pass locally
- [ ] Pre-commit hooks pass
- [ ] Documentation updated
- [ ] Commit messages follow conventions
- [ ] Branch is up to date with main

### PR Template

```markdown
## Description
Brief description of changes

## Change Type
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring

## Testing
- [ ] Local testing completed
- [ ] Pre-commit checks pass
- [ ] Integration tests considered

## Checklist
- [ ] Code follows project style
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process

1. **Automated Checks** - All CI checks must pass
2. **Code Review** - At least one maintainer review required
3. **Testing** - Verify functionality works as expected
4. **Approval** - Maintainer approval required for merge

## 🏷️ Release Process

Automated releases use:

- **Release Drafter** - Automatically creates draft releases
- **Semantic Versioning** - Based on conventional commit messages
- **Tag Push** - Promotes draft releases to published releases

### Version Bumping

- **Major** (1.0.0): Breaking changes (labeled `breaking-change`)
- **Minor** (1.1.0): New features (labeled `feature` or `enhancement`)
- **Patch** (1.1.1): Bug fixes, chores, docs (labeled `fix`, `chore`, etc.)

## 💬 Getting Help

- **Issues** - For bugs and feature requests
- **Discussions** - For questions and general discussion
- **Documentation** - Check README and inline comments

## 📄 License

By contributing, you agree that your contributions use the Apache-2.0 License.
