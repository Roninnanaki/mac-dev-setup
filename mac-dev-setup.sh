#!/bin/bash
set -e

echo ""
echo "=== Mac Development Setup ==="
echo ""

# Helper: install a brew formula if not already installed
brew_install() {
  if brew list "$1" &>/dev/null; then
    echo "  $1 already installed, skipping."
  else
    brew install "$1"
    echo "  $1 installed."
  fi
}

# Helper: install a brew cask if not already installed
brew_install_cask() {
  local app_name="$2"
  if brew list --cask "$1" &>/dev/null || [ -d "/Applications/$app_name" ]; then
    echo "  $1 already installed, skipping."
  else
    brew install --cask "$1" || echo "  Warning: $1 install had issues, continuing."
    echo "  $1 installed."
  fi
}

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo "Homebrew installed."
else
  echo "Homebrew already installed, updating..."
  brew update
  echo "Homebrew updated."
fi
echo ""

# --- Xcode Command Line Tools ---
if xcode-select -p &>/dev/null; then
  echo "Xcode CLI tools already installed, skipping."
else
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Press enter after Xcode CLI tools finish installing..."
  read -r
  echo "Xcode CLI tools installed."
fi
echo ""

# --- CLI Tools ---
echo "Checking CLI tools..."
for tool in git gh ripgrep fd fzf jq; do
  brew_install "$tool"
done
echo "CLI tools ready."
echo ""

# --- Version Managers ---
echo "Checking version managers..."
for tool in fnm rbenv ruby-build; do
  brew_install "$tool"
done
echo "Version managers ready."
echo ""

# --- Databases & Services ---
echo "Checking databases and services..."
for tool in postgresql@17 redis libvips; do
  brew_install "$tool"
done
echo "Databases and services ready."
echo ""

# --- Editor ---
echo "Checking VS Code..."
brew_install_cask visual-studio-code "Visual Studio Code.app"
echo "Editor ready."
echo ""

# --- Shell Configuration ---
ZSHRC="$HOME/.zshrc"

add_to_zshrc() {
  if ! grep -qF "$1" "$ZSHRC" 2>/dev/null; then
    echo "$1" >> "$ZSHRC"
    echo "  Added to .zshrc: $1"
  else
    echo "  Already in .zshrc: $1"
  fi
}

echo "Configuring shell..."
add_to_zshrc 'eval "$(/opt/homebrew/bin/brew shellenv)"'
add_to_zshrc 'eval "$(fnm env --use-on-cd)"'
add_to_zshrc 'eval "$(rbenv init - zsh)"'
echo "Shell configured."
echo ""

# Reload shell config
source "$ZSHRC"

# --- Node (via fnm) ---
if fnm list | grep -q "lts"; then
  echo "Node LTS already installed, skipping."
else
  echo "Installing Node LTS..."
  fnm install --lts
  echo "Node LTS installed."
fi
fnm default lts-latest
echo "Node ready: $(node -v 2>/dev/null || echo 'restart shell to use')"
echo ""

# --- Ruby (via rbenv) ---
RUBY_LATEST=$(rbenv install -l 2>/dev/null | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
if rbenv versions | grep -q "$RUBY_LATEST"; then
  echo "Ruby $RUBY_LATEST already installed, skipping."
else
  echo "Installing Ruby $RUBY_LATEST..."
  rbenv install -s "$RUBY_LATEST"
  echo "Ruby $RUBY_LATEST installed."
fi
rbenv global "$RUBY_LATEST"
echo "Ruby ready: $(ruby -v 2>/dev/null || echo 'restart shell to use')"
echo ""

# --- Ruby Gems ---
if gem list -i rails &>/dev/null; then
  echo "Rails already installed, skipping."
else
  echo "Installing Rails..."
  gem install rails --no-document
  echo "Rails installed."
fi

if gem list -i bundler &>/dev/null; then
  echo "Bundler already installed, skipping."
else
  echo "Installing Bundler..."
  gem install bundler --no-document
  echo "Bundler installed."
fi
echo "Ruby gems ready."
echo ""

# --- Node Global Packages ---
if npm list -g yarn &>/dev/null; then
  echo "Yarn already installed, skipping."
else
  echo "Installing Yarn..."
  npm install -g yarn
  echo "Yarn installed."
fi
echo "Node packages ready."
echo ""

# --- Start Services ---
echo "Starting services..."
brew services start postgresql@17 2>/dev/null || echo "  PostgreSQL already running."
brew services start redis 2>/dev/null || echo "  Redis already running."
echo "Services ready."
echo ""

# --- Git Configuration ---
echo "=== Git Configuration ==="
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)

if [ -n "$CURRENT_NAME" ] && [ -n "$CURRENT_EMAIL" ]; then
  echo "Git already configured as: $CURRENT_NAME <$CURRENT_EMAIL>"
  read -rp "Reconfigure? (y/n): " RECONFIG
  if [ "$RECONFIG" != "y" ]; then
    echo "Git config kept."
  else
    read -rp "Your full name for git: " GIT_NAME
    read -rp "Your email for git: " GIT_EMAIL
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    echo "Git reconfigured."
  fi
else
  read -rp "Your full name for git: " GIT_NAME
  read -rp "Your email for git: " GIT_EMAIL
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  echo "Git configured."
fi
echo ""

# --- SSH Key ---
if [ -f "$HOME/.ssh/id_ed25519" ]; then
  echo "SSH key already exists, skipping."
else
  GIT_EMAIL=$(git config --global user.email)
  echo "Generating SSH key..."
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519"
  echo ""
  echo "Your public key (add this to GitHub):"
  echo ""
  cat "$HOME/.ssh/id_ed25519.pub"
  echo "SSH key generated."
fi
echo ""

# --- GitHub CLI Auth ---
if gh auth status &>/dev/null; then
  echo "Already authenticated with GitHub, skipping."
else
  read -rp "Authenticate with GitHub now? (y/n): " GH_AUTH
  if [ "$GH_AUTH" = "y" ]; then
    gh auth login
    echo "GitHub authenticated."
  else
    echo "GitHub auth skipped."
  fi
fi

# --- Claude AI Tools ---
echo "Checking Claude AI tools..."

# Claude Desktop
brew_install_cask claude "Claude.app"

# Claude Code CLI
if npm list -g @anthropic-ai/claude-code &>/dev/null; then
  echo "  Claude Code CLI already installed, skipping."
else
  echo "  Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
  echo "  Claude Code CLI installed."
fi

# Claude Code VS Code Extension
if code --list-extensions 2>/dev/null | grep -qi "anthropic.claude-code"; then
  echo "  Claude Code VS Code extension already installed, skipping."
else
  echo "  Installing Claude Code VS Code extension..."
  code --install-extension anthropic.claude-code
  echo "  Claude Code VS Code extension installed."
fi
echo "Claude AI tools ready."
echo ""

echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "  Node:  $(node -v 2>/dev/null || echo 'restart shell to use')"
echo "  Ruby:  $(ruby -v 2>/dev/null || echo 'restart shell to use')"
echo "  Rails: $(rails -v 2>/dev/null || echo 'restart shell to use')"
echo "  Yarn:  $(yarn -v 2>/dev/null || echo 'restart shell to use')"
echo ""
echo "Services:"
brew services list
echo ""
echo "Run 'source ~/.zshrc' or open a new terminal to pick up all changes."
