# Workspace Rules

## Git Commit Proposals
- After completing code modifications or features, always prepare and suggest a formatted Conventional Commit command in English at the end of your response.
- Use Conventional Commit tags like `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.
- Format the git commands in a ready-to-copy code block (e.g. `git add .` and `git commit -m "..."`).

## Release & Changelog Management
- This repository uses `@alcalzone/release-script` for versioning and releases (`npm run release`).
- `CHANGELOG.md` must ALWAYS contain the placeholder header `## **WORK IN PROGRESS**` above the latest version section so that `@alcalzone/release-script` can process new release entries automatically.

