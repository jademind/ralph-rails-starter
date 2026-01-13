# Rails 8.1 Starter Template with Ralph Wiggum

This is an opinionated Rails 8.1 starter template that includes the "Ralph Wiggum" autonomous agent workflow. Ralph Wiggum works iteratively through Product Requirements Documents (PRDs) using Claude as an AI agent to build features autonomously.

## What Makes This Template Opinionated?

This starter project comes with pre-configured defaults and tools:

- **Package Manager**: Homebrew (macOS)
- **Ruby Version Manager**: rbenv
- **Framework**: Rails 8.1
- **Authentication**: Rails 8 native authentication (no Devise)
- **Authorization**: Pundit for policy-based authorization
- **AI Agent**: Claude Code CLI for Ralph Wiggum autonomous development
- **Deployment**: Kamal 2 for containerized deployments
- **CSS Framework**: Tailwind CSS
- **Testing**: Minitest (Rails default)

## Project Setup

### Initial Setup Script

Use the provided `setup-project.sh` script to get your development environment ready:

```bash
./setup-project.sh
```

This script will:
- Verify Git installation
- Check and update Homebrew
- Install/update jq (JSON processor)
- Install/update rbenv and ruby-build
- Install the correct Ruby version (specified in `.ruby-version`)
- Install Bundler
- Install project dependencies via `bundle install`
- **Install/update Claude CLI** (required for Ralph Wiggum)
- Check Claude CLI authentication status
- Initialize Rails credentials if needed
- Verify the complete installation

The script handles the complete setup process, making it easy to get started on a new machine or for new team members.

**Note on Claude CLI Authentication**: If Claude CLI is not authenticated, the script will provide instructions on how to authenticate:
1. Get your API key from [Anthropic Console](https://console.anthropic.com/settings/keys)
2. Run `claude` and then `/login` to authenticate
3. Alternatively, set `ANTHROPIC_API_KEY` as an environment variable

## Ralph Wiggum Autonomous Development

### What is Ralph Wiggum?

Ralph Wiggum is an autonomous development workflow that uses Claude Code CLI to iteratively work through PRDs and build features with minimal human intervention. It follows a structured approach: create a PRD, convert it to tasks, and let Claude execute the implementation.

For a comprehensive step-by-step guide, see: [Ralph Wiggum Guide](https://x.com/ryancarson/status/2008548371712135632)

### The ralph.sh Script

The `ralph.sh` script is your main interface for running the Ralph Wiggum workflow:

```bash
./ralph.sh [command] [options]
```

**Available commands:**

| Command | Description | Usage |
|---------|-------------|-------|
| `create-prd <description>` | Create a new PRD using Claude's create-prd skill | `./ralph.sh create-prd Add user authentication` |
| `create-tasks <file-path>` | Convert an existing PRD file into ralph-prd.json tasks | `./ralph.sh create-tasks prd.md` |
| `run [max_iterations]` | Run the autonomous build process (default: 10 iterations) | `./ralph.sh run` or `./ralph.sh run 50` |
| `status` | Show current progress and statistics | `./ralph.sh status` |
| `clean` | Clean up logs and progress files | `./ralph.sh clean` |
| `archive-list` | List all archived Ralph runs | `./ralph.sh archive-list` |
| `help` | Show help message with all commands | `./ralph.sh help` |

**Key Features:**
- **Progress Tracking**: Maintains state in `ralph-progress.txt` to track completed iterations
- **Branch Management**: Automatically detects branch changes and archives previous runs
- **Archiving**: Archives completed or interrupted runs to the `archive/` directory
- **Logging**: Full session logs saved to `ralph.log`
- **Graceful Interruption**: Use `Ctrl+C` to stop Ralph while preserving progress

### Development Workflow with Ralph

Follow these three steps for autonomous feature development:

#### 1. Create a PRD
```bash
./ralph.sh create-prd
```

This opens an interactive session with Claude to help you create a detailed Product Requirements Document. The PRD defines:
- Feature overview and purpose
- User stories and acceptance criteria
- Technical requirements
- Design considerations
- Edge cases and constraints

#### 2. Convert PRD to Tasks
```bash
./ralph.sh create-tasks
```

This command takes your PRD and converts it into a structured `ralph-prd.json` file containing:
- Broken-down tasks
- Implementation steps
- Dependencies between tasks
- Success criteria for each task

#### 3. Run Autonomous Build
```bash
./ralph.sh run
```

This launches the autonomous build process where Claude:
- Works through each task sequentially
- Writes code and tests
- Runs validations
- Commits changes
- Handles errors and iterations
- Continues until all tasks are complete

Ralph will work autonomously, but you can monitor progress and intervene if needed.

## External Resources

### Ralph Wiggum Resources
- **Step-by-Step Guide**: [Ryan Carson's Ralph Wiggum Guide](https://x.com/ryancarson/status/2008548371712135632)
- **Ralph Scripts & Skills**: [Ralph GitHub Repository](https://github.com/snarktank/ralph)
- **Original technique**: https://ghuntley.com/ralph/
- **Ralph Orchestrator**: https://github.com/mikeyobrien/ralph-orchestrator

### Claude Code Resources
- **Claude Code CLI Documentation**: [Official CLI Reference](https://code.claude.com/docs/en/cli-reference)
- **Claude Plugins Repository**: [Official Plugins](https://github.com/anthropics/claude-plugins-official/tree/main)
