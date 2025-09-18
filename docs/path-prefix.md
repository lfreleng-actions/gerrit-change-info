<!--
SPDX-License-Identifier: Apache-2.0
SPDX-FileCopyrightText: 2025 The Linux Foundation
-->

# Path Prefix Feature

Use path_prefix to run the gerrit-change-info action in specific directories.

## Overview

With this feature you can:

- Run the action in repository subdirectories
- Structure multi-project repositories with targeted action execution
- Keep existing workflows working without changes

## Usage

### Default Behavior

```yaml
- uses: lfreleng-actions/gerrit-change-info@main
  with:
    # ... other parameters
    path_prefix: "."  # Default - executes in repository root
```

### Custom Directory

```yaml
- uses: lfreleng-actions/gerrit-change-info@main
  with:
    # ... other parameters
    path_prefix: "my-project"  # Executes in my-project/ subdirectory
```

### Nested Directory

```yaml
- uses: lfreleng-actions/gerrit-change-info@main
  with:
    # ... other parameters
    path_prefix: "projects/backend"  # Executes in projects/backend/ subdirectory
```

## How It Works

1. **Directory Creation**: The action creates missing directories
2. **Script Execution**: Scripts run within the specified directory
3. **File Operations**: Output files go into the specified directory
4. **Path Resolution**: All paths resolve relative to the directory

## Security Features

- **Path Traversal Protection**: Blocks `..` in paths
- **Input Validation**: Checks for safe path characters
- **Safe Directory Creation**: Makes directories inside workspace

## Error Handling

The action fails with error messages when:

- path_prefix contains dangerous patterns like `..`
- path_prefix is empty
- Security validation detects issues

## Examples

### Multi-Project Repository Structure

```plaintext
repository/
├── frontend/
│   └── package.json
├── backend/
│   └── pom.xml
└── infrastructure/
    └── terraform/
```

To run the action for the backend project:

```yaml
path_prefix: "backend"
```

To run for infrastructure terraform:

```yaml
path_prefix: "infrastructure/terraform"
```

## Migration from Existing Workflows

Existing workflows work without changes. The `path_prefix` default value `"."`
preserves current behavior.

To switch to a specific directory:

1. Add the `path_prefix` parameter to your action configuration
2. Specify the desired directory path
3. Test your workflow to verify output file locations

## Output Files

When using `path_prefix`, the action places all output files in the directory:

- `gerrit_ssh_info.env` - In `{path_prefix}/gerrit_ssh_info.env`
- `{change_number}.file` - In `{path_prefix}/{change_number}.file`

This helps workflow steps find the files in the expected location relative to the
working directory.
