#!/usr/bin/env bash

#############################################################
# Project Setup Script
# This script sets up all necessary dependencies for the project
#############################################################

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${GREEN}==>${NC} $1\n"
}

#############################################################
# Step 1: Check if Git is installed
#############################################################
log_step "Checking if Git is installed..."

if ! command -v git &> /dev/null; then
    log_error "Git is not installed!"
    log_error "Please install Git first: https://git-scm.com/downloads"
    exit 1
fi

GIT_VERSION=$(git --version)
log_success "Git is installed: $GIT_VERSION"

#############################################################
# Step 2: Check if Homebrew is installed
#############################################################
log_step "Checking if Homebrew is installed..."

if ! command -v brew &> /dev/null; then
    log_error "Homebrew is not installed!"
    log_error "Please install Homebrew first: https://brew.sh"
    log_error "Run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

BREW_VERSION=$(brew --version | head -n 1)
log_success "Homebrew is installed: $BREW_VERSION"

#############################################################
# Step 3: Update Homebrew
#############################################################
log_step "Updating Homebrew..."

log_info "Running 'brew update'..."
if brew update; then
    log_success "Homebrew updated successfully"
else
    log_error "Failed to update Homebrew"
    exit 1
fi

#############################################################
# Step 4: Install/Update jq
#############################################################
log_step "Installing/Updating jq..."

if command -v jq &> /dev/null; then
    log_info "jq is already installed. Updating..."
    if brew upgrade jq 2>&1 | tee /dev/tty | grep -q "already installed"; then
        log_success "jq is already up to date"
    else
        log_success "jq updated successfully"
    fi
else
    log_info "jq not found. Installing..."
    if brew install jq; then
        log_success "jq installed successfully"
    else
        log_error "Failed to install jq"
        exit 1
    fi
fi

# Verify jq installation
JQ_VERSION=$(jq --version)
log_info "Current jq: $JQ_VERSION"

#############################################################
# Step 5: Install/Update rbenv
#############################################################
log_step "Installing/Updating rbenv..."

if command -v rbenv &> /dev/null; then
    log_info "rbenv is already installed. Updating..."
    if brew upgrade rbenv 2>&1 | tee /dev/tty | grep -q "already installed"; then
        log_success "rbenv is already up to date"
    else
        log_success "rbenv updated successfully"
    fi
else
    log_info "rbenv not found. Installing..."
    if brew install rbenv; then
        log_success "rbenv installed successfully"
    else
        log_error "Failed to install rbenv"
        exit 1
    fi
fi

# Initialize rbenv if not already in PATH
if ! grep -q 'rbenv init' ~/.zshrc 2>/dev/null && ! grep -q 'rbenv init' ~/.bash_profile 2>/dev/null; then
    log_warning "rbenv init not found in shell config. You may need to add it manually."
    log_info "Add this to your ~/.zshrc or ~/.bash_profile:"
    log_info "  eval \"\$(rbenv init - zsh)\""
fi

# Initialize rbenv for current session
eval "$(rbenv init - bash)" 2>/dev/null || eval "$(rbenv init - zsh)" 2>/dev/null || true

#############################################################
# Step 5: Upgrade ruby-build
#############################################################
log_step "Upgrading ruby-build..."

log_info "Running 'brew upgrade ruby-build'..."
if brew upgrade ruby-build 2>&1 | tee /dev/tty | grep -q "already installed"; then
    log_success "ruby-build is already up to date"
else
    log_success "ruby-build upgraded successfully"
fi

# Update rbenv ruby definitions
log_info "Updating ruby-build definitions..."
if command -v rbenv &> /dev/null; then
    git -C "$(rbenv root)"/plugins/ruby-build pull 2>/dev/null || log_info "ruby-build plugin update not needed"
fi

#############################################################
# Step 7: Install Ruby version from .ruby-version
#############################################################
log_step "Installing Ruby version from .ruby-version..."

if [ ! -f .ruby-version ]; then
    log_error ".ruby-version file not found in current directory!"
    exit 1
fi

RUBY_VERSION=$(cat .ruby-version | tr -d '[:space:]')
log_info "Target Ruby version: $RUBY_VERSION"

# Check if the Ruby version is already installed
if rbenv versions | grep -q "$RUBY_VERSION"; then
    log_success "Ruby $RUBY_VERSION is already installed"
else
    log_info "Installing Ruby $RUBY_VERSION... (this may take a while)"
    if rbenv install "$RUBY_VERSION"; then
        log_success "Ruby $RUBY_VERSION installed successfully"
    else
        log_error "Failed to install Ruby $RUBY_VERSION"
        log_error "Make sure the version exists. Check available versions with: rbenv install --list"
        exit 1
    fi
fi

# Set the local Ruby version
log_info "Setting local Ruby version to $RUBY_VERSION..."
rbenv local "$RUBY_VERSION"
rbenv rehash
log_success "Ruby version set to $RUBY_VERSION"

# Verify Ruby installation
CURRENT_RUBY=$(ruby -v)
log_info "Current Ruby: $CURRENT_RUBY"

#############################################################
# Step 8: Install Ruby gems with Bundler
#############################################################
log_step "Installing Ruby gems with Bundler..."

# Check if Gemfile exists
if [ ! -f Gemfile ]; then
    log_warning "Gemfile not found. Skipping bundle install."
    log_info "If you need to create a Gemfile, you can run: bundle init"
else
    # Ensure bundler is installed
    if ! gem list bundler -i &> /dev/null; then
        log_info "Installing bundler..."
        gem install bundler
        rbenv rehash
    fi

    log_info "Running 'bundle install --path vendor/bundle'..."
    if bundle install --path vendor/bundle; then
        log_success "Gems installed successfully to vendor/bundle"
    else
        log_error "Failed to install gems"
        exit 1
    fi
fi

#############################################################
# Step 9: Check and install/update Claude CLI
#############################################################
log_step "Checking Claude CLI installation..."

if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    log_success "Claude CLI is installed: $CLAUDE_VERSION"

    log_info "Attempting to update Claude CLI..."
    # Try to update using the same installation method
    if curl -fsSL https://claude.ai/install.sh | bash; then
        log_success "Claude CLI update completed"
    else
        log_warning "Claude CLI update may have failed, but the current installation should still work"
    fi
else
    log_info "Claude CLI not found. Installing..."
    log_info "Running: curl -fsSL https://claude.ai/install.sh | bash"

    if curl -fsSL https://claude.ai/install.sh | bash; then
        log_success "Claude CLI installed successfully"
        log_info "You may need to restart your terminal or run: source ~/.zshrc (or ~/.bash_profile)"
    else
        log_error "Failed to install Claude CLI"
        exit 1
    fi
fi

#############################################################
# Step 10: Check Claude CLI Authentication
#############################################################
log_step "Checking Claude CLI authentication..."

# Check if claude command is available (may need to reload path)
if command -v claude &> /dev/null; then
    # Check if ~/.claude.json exists and contains customApiKeyResponses
    CLAUDE_AUTHENTICATED=false
    if [ -f "$HOME/.claude.json" ]; then
        # Check if the file contains customApiKeyResponses using jq
        if jq -e '.customApiKeyResponses' "$HOME/.claude.json" &> /dev/null; then
            CLAUDE_AUTHENTICATED=true
        fi
    fi

    if [ "$CLAUDE_AUTHENTICATED" = true ]; then
        log_success "Claude CLI seems to be authenticated (~/.claude.json found with API key)"
    else
        log_warning "Claude CLI is installed but not authenticated"
        echo ""
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "  AUTHENTICATION REQUIRED"
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log_info "To authenticate with Claude CLI, follow these steps:"
        echo ""
        log_info "1. Get your API key:"
        log_info "   → Visit: https://console.anthropic.com/settings/keys"
        log_info "   → Sign in to your Anthropic account"
        log_info "   → Create a new API key or copy an existing one"
        echo ""
        log_info "2. Authenticate Claude CLI:"
        log_info "   → Run: claude"
        log_info "   → Then run: /login"
        log_info "   → Follow the prompts to enter your API key"
        echo ""
        log_info "Alternatively, set the API key as an environment variable:"
        log_info "   export ANTHROPIC_API_KEY='your-api-key-here'"
        echo ""
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
else
    log_warning "Claude CLI command not found in PATH"
    log_info "You may need to restart your terminal or run: source ~/.zshrc"
fi

#############################################################
# Step 11: Check Rails Credentials
#############################################################
log_step "Checking Rails credentials..."

# Check if this is a Rails project
if [ -f "bin/rails" ]; then
    log_info "Rails project detected"

    # Check if credentials files exist
    CREDENTIALS_MISSING=false
    if [ ! -f "config/credentials.yml.enc" ]; then
        log_warning "config/credentials.yml.enc not found"
        CREDENTIALS_MISSING=true
    fi

    if [ ! -f "config/master.key" ]; then
        log_warning "config/master.key not found"
        CREDENTIALS_MISSING=true
    fi

    if [ "$CREDENTIALS_MISSING" = true ]; then
        log_info "Initializing Rails credentials..."

        # Use EDITOR="true" to create credentials without opening an editor
        # This prevents the script from blocking
        if EDITOR="true" bin/rails credentials:edit &> /dev/null; then
            log_success "Rails credentials initialized"
            log_info "Credentials created at:"
            log_info "  - config/credentials.yml.enc"
            log_info "  - config/master.key"
            log_warning "IMPORTANT: Keep config/master.key secure and never commit it to version control!"
        else
            log_warning "Could not automatically initialize credentials"
            log_info "You may need to run manually: bin/rails credentials:edit"
        fi
    else
        log_success "Rails credentials already exist"
    fi
else
    log_info "Not a Rails project or bin/rails not found. Skipping credentials check."
fi

#############################################################
# Setup Complete
#############################################################
log_step "Setup Complete!"

echo ""
log_success "All dependencies have been successfully installed and configured!"
echo ""
log_info "Summary:"
log_info "  ✓ Git: Verified"
log_info "  ✓ Homebrew: Updated"
log_info "  ✓ jq: Installed/Updated"
log_info "  ✓ rbenv: Installed/Updated"
log_info "  ✓ ruby-build: Upgraded"
log_info "  ✓ Ruby $RUBY_VERSION: Installed"
if [ -f Gemfile ]; then
    log_info "  ✓ Gems: Installed to vendor/bundle"
fi
log_info "  ✓ Claude CLI: Installed/Updated"
if [ -f "bin/rails" ]; then
    log_info "  ✓ Rails Credentials: Checked"
fi
echo ""
log_info "Next steps:"
log_info "  - Make sure to restart your terminal or run: source ~/.zshrc"
log_info "  - Verify Ruby version: ruby -v"
log_info "  - Verify rbenv: rbenv version"
if [ -f Gemfile ]; then
    log_info "  - Run your application with: bundle exec <command>"
fi
log_info "  - If Claude CLI is not authenticated, run claude and /login after that"
echo ""
