<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
-->

# Export Gerrit change request information

The gerrit-change-info action takes the Gerrit change URL and patchset number
as input and returns information about the Gerrit change request, which other
releng reusable workflows then reuse as input.

## gerrit-change-info

## Usage Example

<!-- markdownlint-disable MD046 -->

```yaml
steps:
  - name: "Gerrit change information"
    id: gerrit
    uses: lfreleng-actions/gerrit-change-info@main
    with:
      GERRIT_CHANGE_URL: ${{ inputs.GERRIT_CHANGE_URL }}
      GERRIT_SSH_USER: ${{ vars.GERRIT_SSH_USER }}
      GERRIT_PATCHSET_NUMBER: ${{ inputs.GERRIT_PATCHSET_NUMBER }}
    secrets:
      GERRIT_SSH_PRIVKEY: ${{ secrets.GERRIT_SSH_PRIVKEY }}

```

<!-- markdownlint-enable MD046 -->

## Inputs

<!-- markdownlint-disable MD013 -->

| Variable Name          | Required | Description                 |
| ---------------------- | -------- | --------------------------- |
| GERRIT_CHANGE_URL      | Yes      | Gerrit change-request URL   |
| GERRIT_SSH_USER        | Yes      | SSH User name               |
| GERRIT_PATCHSET_NUMBER | False    | Gerrit patchset number      |
| GERRIT_SSH_PRIVKEY     | False    | Gerrit SSH user private key |

<!-- markdownlint-enable MD013 -->

## Outputs

<!-- markdownlint-disable MD013 -->

| Variable Name           | Description                           |
| ----------------------- | ------------------------------------- |
| GERRIT_BRANCH           | Gerrit branch                         |
| GERRIT_CHANGE_ID        | Gerrit change ID                      |
| GERRIT_CHANGE_URL       | Gerrit change URL                     |
| GERRIT_CHANGE_NUMBER    | Gerrit change number                  |
| GERRIT_EVENT_TYPE       | Gerrit event type                     |
| GERRIT_PATCHSET_NUMBER  | Gerrit change patchset revision number|
| GERRIT_PATCHSET_REVISION| Gerrit change patchset revision sha   |
| GERRIT_PROJECT          | Gerrit project                        |
| GERRIT_REFSPEC          | refspec of the Gerrit change request  |
| GERRIT_HOSTNAME         | Gerrit hostname                       |

<!-- markdownlint-enable MD013 -->

## Workflow output example

```console
GERRIT_BRANCH="master"
GERRIT_CHANGE_ID="Icbc94be813abd2dcfb3ad5bd9bed66ecf1847572"
GERRIT_CHANGE_URL="https://git.opendaylight.org/gerrit/c/releng/builder/+/111445"
GERRIT_CHANGE_NUMBER="111445"
GERRIT_EVENT_TYPE="comment_added"
GERRIT_PATCHSET_NUMBER="6"
GERRIT_PATCHSET_REVISION="887d670768f79896b48bda353ef473ae66b13dc7"
GERRIT_PROJECT="opendaylight/releng-builder"
GERRIT_REFSPEC="refs/changes/45/111445/6"
GERRIT_HOSTNAME="git.opendaylight.org"
```

## Implementation Details

Using an SSH connection to the Gerrit server, the gerrit-query CLI command
obtains and validates parameters required by downstream reusable
workflows.

### Security Features

- Input validation for all parameters
- SSH timeout handling (30 seconds)
- Strict host key checking enabled
- No sensitive data exposed in logs

### Error Handling

- Validates Gerrit URL format
- Checks SSH connectivity before queries
- Validates JSON response from Gerrit
- Provides detailed error messages

## Troubleshooting

### Common Issues

#### SSH Connection Failures

```text
Error: SSH connection to Gerrit failed
```

- **Cause**: Incorrect SSH credentials, network issues, or firewall blocking
- **Solution**:
  - Verify SSH private key format and permissions
  - Check `gerrit_known_hosts` entry is correct
  - Ensure Gerrit server is accessible on port 29418
  - Test SSH connection manually: `ssh -p 29418 user@gerrit.host`

#### Invalid Gerrit URL Format

```text
Error: Invalid Gerrit URL format
```

- **Cause**: URL doesn't match expected Gerrit change format
- **Solution**: Ensure URL follows pattern: `https://hostname/gerrit/c/project/+/number`
- **Example**: `https://git.opendaylight.org/gerrit/c/releng/builder/+/111445`

#### Change Not Found

```text
Error: Could not extract change ID from Gerrit response
```

- **Cause**: Change doesn't exist, insufficient permissions, or closed change
- **Solution**:
  - Verify change number is correct
  - Ensure SSH user has read access to the project
  - Check if change is still open (action queries `is:open`)

#### Missing Required Permissions

```text
Error: Could not extract required fields from Gerrit response
```

- **Cause**: SSH user lacks necessary Gerrit permissions
- **Solution**: Ensure SSH user has:
  - Read access to the project
  - Permission to query changes
  - Access to patchset information

### SSH Key Setup

#### Generate SSH Key Pair

```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

#### Add Public Key to Gerrit

1. Copy public key: `cat ~/.ssh/id_rsa.pub`
2. In Gerrit web UI: Settings → SSH Keys → Add Key

#### Configure GitHub Secrets

- `GERRIT_SSH_KEY`: Private key content
- `GERRIT_SSH_USER`: Gerrit username

#### Get Known Hosts Entry

```bash
ssh-keyscan -p 29418 your-gerrit-host.com
```

### Debugging Steps

1. **Test SSH Connection**

   ```bash
   ssh -p 29418 username@gerrit-host.com gerrit version
   ```

2. **Manual Query Test**

   ```bash
   ssh -p 29418 user@host 'gerrit query --format=JSON change:12345 limit:1'
   ```

3. **Check Action Logs**
   - Look for detailed error messages in GitHub Action logs
   - Check if all required inputs exist
   - Verify output file creation

### Performance Considerations

- SSH queries typically complete within 5-10 seconds
- Action has 30-second timeout for SSH operations
- Large projects may take longer to query

## Notes

The purpose of the workflow reduces the large number of manually entered
inputs by the end user requiring to trigger workflows.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, guidelines,
and contribution process.
