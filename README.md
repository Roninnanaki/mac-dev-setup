# Mac Dev Setup

A single script to set up a fresh Mac for web and mobile development with Node, React, Ruby on Rails, and Swift.

## What It Installs

- **Homebrew** — macOS package manager
- **Node.js** (LTS) via [fnm](https://github.com/Schniz/fnm) — with Yarn
- **Ruby** (latest stable) via [rbenv](https://github.com/rbenv/rbenv) — with Rails and Bundler
- **PostgreSQL 17** and **Redis** — started as background services
- **VS Code** — editor (skipped if already installed)
- **CLI tools** — git, gh, ripgrep, fd, fzf, jq
- **Git + SSH** — global config and ED25519 key generation
- **GitHub CLI auth** — optional login prompt

## Prerequisites

1. **macOS** on Apple Silicon (M-series) or Intel
2. **Xcode** — install from the App Store for Swift/SwiftUI development, then accept the license:
   ```bash
   sudo xcodebuild -license accept
   ```
3. **Admin access** — Homebrew and some installs require your password
4. **Internet connection** — everything is downloaded during setup

## Usage

```bash
git clone https://github.com/Roninnanaki/mac-dev-setup.git
cd mac-dev-setup
chmod +x mac-dev-setup.sh
./mac-dev-setup.sh
```

The script is **idempotent** — it checks for existing installations and skips anything already set up. Safe to re-run if interrupted.

## After Setup

- Open a new terminal or run `source ~/.zshrc` to load all changes
- Add your SSH public key to GitHub: `cat ~/.ssh/id_ed25519.pub`

## Customization

Edit the script to add or remove tools. The helper functions `brew_install` and `brew_install_cask` handle idempotent installs — just add new entries to the relevant section.
