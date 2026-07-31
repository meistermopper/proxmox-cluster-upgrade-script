# Contributing to Proxmox Cluster Upgrade Script

Thank you for considering contributing to this project!

## How to Contribute

1. **Fork the Repository**: Create your own feature branch.
2. **Make Changes**:
   - Write clean, POSIX/Bash compatible shell code.
   - Run `shellcheck cluster-upgrade.sh` locally to ensure zero linting warnings.
   - Ensure line endings for `.sh` files remain `LF`.
3. **Test Your Changes**: Always run `./cluster-upgrade.sh --dry-run` to test flow execution.
4. **Submit a Pull Request**: Describe your changes clearly in the PR description.

## Code Style
- Use 4 spaces for indentation.
- Follow ShellCheck guidelines and best practices.
- Add English code comments and documentation updates for any new settings.
