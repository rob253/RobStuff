# CLAUDE.md - AI Assistant Guidelines for RobStuff

> This file provides context and guidelines for AI assistants working with this codebase.

## Project Overview

**Status**: New repository - initial setup in progress

**Repository**: RobStuff
**Owner**: rob253

This repository is newly initialized and awaiting initial project setup. Update this section once the project purpose and scope are defined.

---

## Repository Structure

```
/home/user/RobStuff/
├── CLAUDE.md          # AI assistant guidelines (this file)
└── .git/              # Git version control
```

> **Note**: Update this structure diagram as the project grows.

---

## Development Workflow

### Git Conventions

- **Main Branch**: To be established
- **Feature Branches**: Use descriptive names (e.g., `feature/user-auth`, `fix/login-bug`)
- **Commit Messages**: Use conventional commits format:
  - `feat:` - New features
  - `fix:` - Bug fixes
  - `docs:` - Documentation changes
  - `refactor:` - Code refactoring
  - `test:` - Adding or updating tests
  - `chore:` - Maintenance tasks

### Commit Signing

This repository is configured with GPG commit signing via SSH key. Commits are automatically signed.

---

## Code Conventions

> Update this section once the primary language and frameworks are established.

### General Principles

1. **Readability**: Write clear, self-documenting code
2. **Simplicity**: Prefer simple solutions over complex ones
3. **Consistency**: Follow established patterns in the codebase
4. **Testing**: Write tests for new functionality
5. **Documentation**: Document public APIs and complex logic

---

## Build & Test Commands

> Add commands here once the project build system is configured.

```bash
# Example commands (update when project is set up):
# npm install          # Install dependencies
# npm run build        # Build the project
# npm test             # Run tests
# npm run lint         # Run linter
```

---

## Key Files & Directories

> Document important files and their purposes as they are created.

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | AI assistant guidelines |
| _TBD_ | _Add key files as project develops_ |

---

## Dependencies

> List key dependencies and their purposes once established.

---

## Environment Setup

### Prerequisites

> List required tools and versions once determined (e.g., Node.js, Python, etc.)

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd RobStuff

# Additional setup steps to be added
```

---

## AI Assistant Guidelines

### When Working in This Repository

1. **Read before modifying**: Always read files before making changes
2. **Follow existing patterns**: Match the code style already in use
3. **Keep changes focused**: Make minimal, targeted changes
4. **Test changes**: Run relevant tests after modifications
5. **Clear commits**: Write descriptive commit messages

### What to Avoid

- Don't introduce unnecessary complexity
- Don't add features beyond what's requested
- Don't modify unrelated files
- Don't commit sensitive information (API keys, credentials)
- Don't skip tests or linting

### File Operations

- Prefer editing existing files over creating new ones
- Use appropriate tools for file operations (Read, Edit, Write)
- Maintain consistent formatting with the rest of the codebase

---

## Troubleshooting

> Add common issues and solutions as they are discovered.

---

## Contact & Resources

- **Repository Owner**: rob253
- **Issue Tracker**: [GitHub Issues]

---

*Last updated: 2026-01-25*
