# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KubernetesLabs is a hands-on Kubernetes learning repository with 33+ numbered labs and 7 task collections. Content is published as an MkDocs Material site at https://nirgeier.github.io/KubernetesLabs/.

## Build & Serve Commands

```bash
# Install dependencies
pip install -r mkdocs/requirements.txt

# Local development server (http://localhost:8000)
mkdocs serve --config-file mkdocs.yml

# Build static site (output: mkdocs-site/)
mkdocs build --config-file mkdocs.yml

# Deploy to GitHub Pages (done automatically by CI on push to main/master)
mkdocs gh-deploy --force --clean --config-file mkdocs.yml --no-history
```

## Architecture

### MkDocs Configuration

The single `mkdocs.yml` at root is a merged file containing all config sections. The modular source files live in `mkdocs/`:

- `01-mkdocs-site.yml` - Site metadata (name, URL, author)
- `02-mkdocs-theme.yml` - Material theme settings
- `03-mkdocs-extra.yml` - Social links, extra CSS/JS
- `04-mkdocs-plugins.yml` - Plugins (git-committers, search, minify, print-site, include-markdown)
- `05-mkdocs-extensions.yml` - Markdown extensions (pymdownx, mermaid, admonitions, tabs)
- `06-mkdocs-nav.yml` - Navigation structure

**Important:** `docs_dir` is set to `Labs` - all content lives under `Labs/`.

### Lab Structure

Each lab follows this pattern:
```
Labs/XX-TopicName/
├── README.md          # Main lab content (this is the MkDocs page)
├── manifests/         # Kubernetes YAML files
├── scripts/           # Shell automation scripts
└── [Dockerfile, etc.]
```

Tasks live in `Labs/Tasks/Kubernetes-*-Tasks/README.md`.

### Navigation

When adding a new lab, update the nav in both:
- `mkdocs.yml` (the merged config)
- `mkdocs/06-mkdocs-nav.yml` (the source file)

## Lab README Conventions

- Start with optional YAML frontmatter
- Include sections: description, "What will we learn?", "Official Documentation & References" (table format), "Prerequisites", then numbered content sections (01, 01.01, etc.)
- Use `=== "macOS"` / `=== "Linux"` tab syntax for platform-specific instructions
- Use admonitions (`!!! note`, `!!! warning`, `!!! tip`) for callouts
- Use mermaid fenced blocks for architecture diagrams
- Code blocks use language hints: `bash`, `yaml`, `go`, `dockerfile`

## CI/CD

GitHub Actions (`.github/workflows/deploy-mkdocs.yml`) deploys on push to `main` or `master`. Requires Python 3.11, full git history (`fetch-depth: 0`), and `mkdocs/requirements.txt`.

## Commit Message Convention

Follow the pattern: `labXX: <description>` (e.g., `lab32: Add EFK stack`).
