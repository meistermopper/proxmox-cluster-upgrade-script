# Workspace Rules

## Git Commit Proposals
- After completing code modifications or features, always prepare and suggest a formatted Conventional Commit command in English at the end of your response.
- Use Conventional Commit tags like `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.
- Format the git commands in a ready-to-copy code block (e.g. `git add .` and `git commit -m "..."`).
- **Co-Author Attribution:** All commits created or suggested with AI assistance must include the Git trailer:
  ```git
  Co-authored-by: Gemini <noreply@google.com>
  ```
  Example:
  ```bash
  git commit -m "feat: add cluster health check step" -m "Co-authored-by: Gemini <noreply@google.com>"
  ```

## Release & Changelog Management
- This repository uses `@alcalzone/release-script` for versioning and releases (`npm run release`).
- `CHANGELOG.md` must ALWAYS contain the placeholder header `## **WORK IN PROGRESS**` above the latest version section so that `@alcalzone/release-script` can process new release entries automatically.
- New changes for an upcoming release must be documented as bullet points (under `### Added`, `### Fixed`, etc.) directly beneath `## **WORK IN PROGRESS**`.
- After a release is published via `@alcalzone/release-script`, the `## **WORK IN PROGRESS**` header must be re-added to `CHANGELOG.md` above the newly created release section for the next cycle.

