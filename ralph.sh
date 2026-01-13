#!/bin/bash
#
# Ralph Wiggum Management Script
#
# An autonomous AI agent that iteratively works through PRD tasks using Claude.
# Ralph maintains progress state, handles branch transitions, and archives completed work.
#
# Usage: ./ralph.sh <command> [options]
#
# Commands:
#   run [max_iterations]     Run the Ralph agent loop (default: 10 iterations)
#   create-prd <description> Create a new PRD using the create-prd skill
#   create-tasks <file-path> Create tasks from existing PRD file
#   status                   Show current progress and statistics
#   clean                    Clean up logs and progress files
#   archive-list             List all archived runs
#   help                     Show this help message
#
# Examples:
#   ./ralph.sh run          # Run with default 10 iterations
#   ./ralph.sh run 50       # Run with 50 iterations
#   ./ralph.sh create-prd Add user authentication system
#   ./ralph.sh create-tasks prd.md
#   ./ralph.sh status       # Check current status
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/ralph-prd.json"
PROGRESS_FILE="$SCRIPT_DIR/ralph-progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
LOG_FILE="$SCRIPT_DIR/ralph.log"
AI_AGENT_PRD_COMMAND="claude --dangerously-skip-permissions"
AI_AGENT_TASKS_COMMAND="claude -p --dangerously-skip-permissions"
AI_AGENT_RUN_COMMAND="claude -p --dangerously-skip-permissions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${CYAN}[INFO]${NC} ${timestamp} - $1" | tee -a "$LOG_FILE"
}

log_success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $1" | tee -a "$LOG_FILE"
}

log_warning() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - $1" | tee -a "$LOG_FILE"
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} ${timestamp} - $1" | tee -a "$LOG_FILE" >&2
}

log_section() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${MAGENTA}╔═══════════════════════════════════════════════════════════════╗${NC}" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${MAGENTA}║${NC}  $1" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${MAGENTA}╚═══════════════════════════════════════════════════════════════╝${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Spinner for progress indication
show_spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r${CYAN}${spin:$i:1}${NC} %s" "$message"
        sleep 0.1
    done
    printf "\r"
}

# Cleanup function for graceful shutdown
cleanup() {
    log_warning "Received interrupt signal. Cleaning up..."
    log_info "Final status saved to: $PROGRESS_FILE"
    log_info "Full logs available at: $LOG_FILE"
    exit 130
}

trap cleanup SIGINT SIGTERM

# Validate required files and dependencies
validate_environment() {
    log_info "Validating environment..."

    if ! command -v $AI_AGENT_RUN_COMMAND &> /dev/null; then
        log_error "Claude CLI not found. Please install it first."
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq not found. Please install it first."
        exit 1
    fi

    if [ ! -f "$SCRIPT_DIR/ralph-prompt.md" ]; then
        log_error "ralph-prompt.md not found in $SCRIPT_DIR"
        exit 1
    fi

    if [ ! -f "$PRD_FILE" ]; then
        log_error "PRD file not found: $PRD_FILE"
        log_error "Please create a ralph-prd.json file before running Ralph"
        exit 1
    fi

    log_success "Environment validation passed"
}

# Archive and initialization
archive_previous_run() {
    if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
        CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
        LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

        if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
            DATE=$(date +%Y-%m-%d_%H-%M-%S)
            FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
            ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

            log_warning "Branch changed from '$LAST_BRANCH' to '$CURRENT_BRANCH'"
            log_info "Archiving previous run..."

            mkdir -p "$ARCHIVE_FOLDER"
            [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
            [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
            [ -f "$LOG_FILE" ] && cp "$LOG_FILE" "$ARCHIVE_FOLDER/"

            log_success "Archived to: $ARCHIVE_FOLDER"

            # Reset progress file for new run
            echo "# Ralph Progress Log" > "$PROGRESS_FILE"
            echo "Started: $(date)" >> "$PROGRESS_FILE"
            echo "Branch: $CURRENT_BRANCH" >> "$PROGRESS_FILE"
            echo "---" >> "$PROGRESS_FILE"
        fi
    fi
}

track_current_branch() {
    if [ -f "$PRD_FILE" ]; then
        CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
        if [ -n "$CURRENT_BRANCH" ]; then
            echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
            log_info "Tracking branch: $CURRENT_BRANCH"
        fi
    fi
}

initialize_progress_file() {
    if [ ! -f "$PROGRESS_FILE" ]; then
        log_info "Initializing progress file..."
        echo "# Ralph Progress Log" > "$PROGRESS_FILE"
        echo "Started: $(date)" >> "$PROGRESS_FILE"
        echo "---" >> "$PROGRESS_FILE"
    fi
}

# Show help message
show_help() {
    cat << EOF

Ralph Wiggum Management Script

An autonomous AI agent that iteratively works through PRD tasks using Claude.
Ralph maintains progress state, handles branch transitions, and archives completed work.

Usage: ./ralph.sh <command> [options]

Commands:
  run [max_iterations]     Run the Ralph agent loop (default: 10 iterations)
  create-prd <description> Create a new PRD using the create-prd skill
  create-tasks <file-path> Create tasks from existing PRD file
  status                   Show current progress and statistics
  clean                    Clean up logs and progress files
  archive-list             List all archived runs
  help                     Show this help message

Examples:
  ./ralph.sh run          # Run with default 10 iterations
  ./ralph.sh run 50       # Run with 50 iterations
  ./ralph.sh create-prd Add user authentication system
  ./ralph.sh create-tasks prd.md
  ./ralph.sh status       # Check current status

EOF
    exit 0
}

# Show current status
show_status() {
    log_section "Ralph Status"

    if [ ! -f "$PRD_FILE" ]; then
        log_warning "No PRD file found at: $PRD_FILE"
    else
        BRANCH=$(jq -r '.branchName // "N/A"' "$PRD_FILE" 2>/dev/null || echo "N/A")
        TITLE=$(jq -r '.title // "N/A"' "$PRD_FILE" 2>/dev/null || echo "N/A")
        log_info "Current PRD: $TITLE"
        log_info "Branch: $BRANCH"
    fi

    if [ -f "$PROGRESS_FILE" ]; then
        log_info "Progress file: $PROGRESS_FILE"
        LAST_ITERATION=$(grep -c "^--- Iteration" "$PROGRESS_FILE" 2>/dev/null || echo "0")
        log_info "Completed iterations: $LAST_ITERATION"
    else
        log_warning "No progress file found"
    fi

    if [ -f "$LOG_FILE" ]; then
        LOG_SIZE=$(du -h "$LOG_FILE" | cut -f1)
        log_info "Log file size: $LOG_SIZE"
    fi

    if [ -d "$ARCHIVE_DIR" ]; then
        ARCHIVE_COUNT=$(find "$ARCHIVE_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        log_info "Archived runs: $ARCHIVE_COUNT"
    fi

    exit 0
}

# Clean up logs and progress
clean_logs() {
    log_section "Cleaning Ralph Logs"

    if [ -f "$LOG_FILE" ]; then
        log_info "Removing log file: $LOG_FILE"
        rm -f "$LOG_FILE"
    fi

    if [ -f "$PROGRESS_FILE" ]; then
        log_info "Removing progress file: $PROGRESS_FILE"
        rm -f "$PROGRESS_FILE"
    fi

    if [ -f "$LAST_BRANCH_FILE" ]; then
        log_info "Removing last branch tracker: $LAST_BRANCH_FILE"
        rm -f "$LAST_BRANCH_FILE"
    fi

    log_success "Cleanup complete"
    exit 0
}

# List archived runs
list_archives() {
    log_section "Archived Ralph Runs"

    if [ ! -d "$ARCHIVE_DIR" ] || [ -z "$(ls -A "$ARCHIVE_DIR" 2>/dev/null)" ]; then
        log_info "No archived runs found"
        exit 0
    fi

    for dir in "$ARCHIVE_DIR"/*; do
        if [ -d "$dir" ]; then
            BASENAME=$(basename "$dir")
            SIZE=$(du -sh "$dir" | cut -f1)
            log_info "$BASENAME ($SIZE)"
        fi
    done

    exit 0
}

# Create PRD using the create-prd skill
create_prd() {
    shift # Remove the 'create-prd' command itself
    local FEATURE_DESCRIPTION="$*"

    if [ -z "$FEATURE_DESCRIPTION" ]; then
        log_error "Please provide a feature description"
        echo ""
        echo "Usage: ./ralph.sh create-prd <feature description>"
        echo "Example: ./ralph.sh create-prd Add user authentication system"
        exit 1
    fi

    log_section "Creating PRD"
    log_info "Feature: $FEATURE_DESCRIPTION"

    # Invoke Claude with the create-prd skill
    echo "/create-prd $FEATURE_DESCRIPTION" | $AI_AGENT_PRD_COMMAND

    exit $?
}

# Create tasks from existing PRD using the create-prd-tasks skill
create_tasks() {
    shift # Remove the 'create-tasks' command itself
    local FILE_PATH="$1"

    if [ -z "$FILE_PATH" ]; then
        log_error "Please provide a file path"
        echo ""
        echo "Usage: ./ralph.sh create-tasks <file-path>"
        echo "Example: ./ralph.sh create-tasks prd.md"
        exit 1
    fi

    if [ ! -f "$FILE_PATH" ]; then
        log_error "File not found: $FILE_PATH"
        exit 1
    fi

    log_section "Creating Tasks from PRD"
    log_info "File: $FILE_PATH"

    # Invoke Claude with the create-prd-tasks skill
    echo "/create-prd-tasks $FILE_PATH" | $AI_AGENT_TASKS_COMMAND

    exit $?
}

# Initialize log file for run command
initialize_log_file() {
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "Ralph Session Started: $(date)"
        echo "═══════════════════════════════════════════════════════════════"
    } > "$LOG_FILE"
}

# Run the Ralph agent loop
run_ralph() {
    local MAX_ITERATIONS=${1:-10}

    initialize_log_file

    # Run initialization
    validate_environment
    archive_previous_run
    track_current_branch
    initialize_progress_file

    log_section "Starting Ralph - Max Iterations: $MAX_ITERATIONS"

    # Track statistics
    local TOTAL_START_TIME=$(date +%s)
    local SUCCESSFUL_ITERATIONS=0
    local FAILED_ITERATIONS=0

    for i in $(seq 1 $MAX_ITERATIONS); do
        local ITERATION_START_TIME=$(date +%s)

        log_section "Iteration $i of $MAX_ITERATIONS"

        # Update progress file
        {
            echo ""
            echo "--- Iteration $i started at $(date) ---"
        } >> "$PROGRESS_FILE"

        # Create temp file for capturing output
        local TEMP_OUTPUT=$(mktemp)

        # Run Claude in the background
        cat "$SCRIPT_DIR/ralph-prompt.md" | $AI_AGENT_RUN_COMMAND > "$TEMP_OUTPUT" 2>&1 &
        local CLAUDE_PID=$!

        # Show spinner while Claude is running
        show_spinner $CLAUDE_PID "Running iteration $i/$MAX_ITERATIONS..."

        # Wait for Claude to complete and get exit status
        wait $CLAUDE_PID
        local CLAUDE_EXIT_CODE=$?

        if [ $CLAUDE_EXIT_CODE -eq 0 ]; then
            SUCCESSFUL_ITERATIONS=$((SUCCESSFUL_ITERATIONS + 1))

            # Calculate iteration time
            local ITERATION_END_TIME=$(date +%s)
            local ITERATION_DURATION=$((ITERATION_END_TIME - ITERATION_START_TIME))

            log_success "Iteration $i completed in ${ITERATION_DURATION}s"
            echo "Iteration $i: SUCCESS (${ITERATION_DURATION}s)" >> "$PROGRESS_FILE"

            # Append iteration output to progress file
            {
                echo ""
                echo "--- Iteration $i Output ---"
                cat "$TEMP_OUTPUT"
                echo ""
            } >> "$PROGRESS_FILE"

            # Check for completion signal
            if grep -q "<promise>COMPLETE</promise>" "$TEMP_OUTPUT"; then
                rm -f "$TEMP_OUTPUT"

                local TOTAL_END_TIME=$(date +%s)
                local TOTAL_DURATION=$((TOTAL_END_TIME - TOTAL_START_TIME))

                log_section "🎉 Ralph Completed Successfully! 🎉"
                log_success "Completed at iteration $i of $MAX_ITERATIONS"
                log_info "Total duration: ${TOTAL_DURATION}s"
                log_info "Successful iterations: $SUCCESSFUL_ITERATIONS"
                log_info "Failed iterations: $FAILED_ITERATIONS"
                log_info "Progress saved to: $PROGRESS_FILE"
                log_info "Full logs available at: $LOG_FILE"

                {
                    echo ""
                    echo "═══════════════════════════════════════════════════════"
                    echo "COMPLETED at $(date)"
                    echo "Total iterations: $i"
                    echo "Total duration: ${TOTAL_DURATION}s"
                    echo "═══════════════════════════════════════════════════════"
                } >> "$PROGRESS_FILE"

                exit 0
            fi

            rm -f "$TEMP_OUTPUT"
        else
            FAILED_ITERATIONS=$((FAILED_ITERATIONS + 1))

            log_warning "Iteration $i encountered an error but continuing..."
            echo "Iteration $i: FAILED" >> "$PROGRESS_FILE"

            # Append error output to progress file
            if [ -f "$TEMP_OUTPUT" ]; then
                {
                    echo ""
                    echo "--- Iteration $i Output (FAILED) ---"
                    cat "$TEMP_OUTPUT"
                    echo ""
                } >> "$PROGRESS_FILE"
                rm -f "$TEMP_OUTPUT"
            fi
        fi

        log_info "Waiting before next iteration..."
        sleep 2
    done

    # Max iterations reached
    local TOTAL_END_TIME=$(date +%s)
    local TOTAL_DURATION=$((TOTAL_END_TIME - TOTAL_START_TIME))

    log_section "⚠ Max Iterations Reached ⚠"
    log_warning "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks"
    log_info "Total duration: ${TOTAL_DURATION}s"
    log_info "Successful iterations: $SUCCESSFUL_ITERATIONS"
    log_info "Failed iterations: $FAILED_ITERATIONS"
    log_info "Check progress at: $PROGRESS_FILE"
    log_info "Full logs available at: $LOG_FILE"

    {
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "MAX ITERATIONS REACHED at $(date)"
        echo "Total iterations: $MAX_ITERATIONS"
        echo "Total duration: ${TOTAL_DURATION}s"
        echo "Successful: $SUCCESSFUL_ITERATIONS"
        echo "Failed: $FAILED_ITERATIONS"
        echo "═══════════════════════════════════════════════════════"
    } >> "$PROGRESS_FILE"

    exit 1
}

# Main command dispatcher
COMMAND=${1:-help}

case "$COMMAND" in
    run)
        run_ralph "${2:-10}"
        ;;
    create-prd)
        create_prd "$@"
        ;;
    create-tasks)
        create_tasks "$@"
        ;;
    status)
        show_status
        ;;
    clean)
        clean_logs
        ;;
    archive-list)
        list_archives
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        echo ""
        show_help
        ;;
esac
