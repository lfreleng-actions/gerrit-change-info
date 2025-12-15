<!--
SPDX-License-Identifier: Apache-2.0
SPDX-FileCopyrightText: 2025 The Linux Foundation
-->

# CHANGELOG

## [Unreleased]

### Added

- **path_prefix support**: New `path_prefix` input parameter to set the directory
  for action execution
  - Allows execution in repository subdirectories
  - Works with nested paths like `"projects/backend"`
  - Keeps backward compatibility (defaults to `"."`)
  - Creates missing directories automatically
  - Includes security checks against directory traversal

### Security

- **Path validation**: Added security checks for `path_prefix` parameter
  - Blocks parent directory references with `..`
  - Prevents absolute paths starting with `/`
  - Checks for dangerous characters
  - Creates directories in workspace

### Enhanced

- **Script execution**: Updated scripts to work with the `path_prefix` directory
- **File operations**: Output files now go to the `path_prefix` directory
- **Error handling**: Improved error messages for path-related issues
- **Documentation**: Comprehensive documentation and examples for the new feature

### Testing

- **Integration tests**: Added comprehensive test suite for `path_prefix` functionality
- **Security tests**: Validation tests for dangerous path patterns
- **Compatibility tests**: Backward compatibility verification
- **Error handling tests**: Tests for common error conditions

### Documentation

- **README updates**: Added usage examples and parameter documentation
- **Feature documentation**: Detailed explanation in `docs/path-prefix.md`
- **Contributing guide**: Updated with testing instructions for new feature
- **Troubleshooting**: Added common issues and solutions for path_prefix

### Files Modified

- `action.yaml`: Added path_prefix input and updated all steps to support it
- `.github/scripts/extract_ssh_inputs.sh`: Modified to work with different directories
- `.github/scripts/gerrit_query.sh`: Now creates output files in correct locations
- `README.md`: Updated with new parameter documentation and examples
- `CONTRIBUTING.md`: Added testing instructions for path_prefix feature
- Added: `.github/workflows/test-path-prefix.yml`: Comprehensive test workflow
- Added: `docs/path-prefix.md`: Detailed feature documentation
- Added: `test-path-prefix.sh`: Local integration test script

### Breaking Changes

None - this release maintains full backward compatibility with existing workflows.

### Migration Guide

Existing workflows work without changes. To use the new path_prefix feature:

1. Add the `path_prefix` parameter to your action configuration
2. Specify the desired directory path (relative to repository root)
3. Ensure the directory exists or let the action create it automatically

Example:

```yaml
- uses: lfreleng-actions/gerrit-change-info@main
  with:
    # ... existing parameters
    path_prefix: "my-project"  # NEW: execute in this directory
```
