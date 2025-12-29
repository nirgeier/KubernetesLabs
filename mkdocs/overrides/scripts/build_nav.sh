#!/bin/bash
# Dynamic Navigation Builder for MkDocs
# Automatically generates navigation structure based on content in Labs folder

set -eo pipefail  # Exit on error, pipe failures

# Get the root of the Git Project
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Configuration
readonly LABS_DIR="${PROJECT_ROOT}/Labs"
readonly NAV_FILE="${PROJECT_ROOT}/mkdocs/06-mkdocs-nav.yml"
readonly NAV_BACKUP="${NAV_FILE}.backup"
readonly TEMP_NAV="/tmp/mkdocs_nav_temp.yml"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
VERBOSE=false
DRY_RUN=false
SORT_TYPE="alpha"  # alpha, numeric, date
INCLUDE_DRAFTS=false

#######################################
# Show usage information
#######################################
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Dynamically generates MkDocs navigation structure based on content in the Labs folder.

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --dry-run       Show what would be generated without writing files
    -s, --sort TYPE     Sort method: alpha, numeric, date (default: alpha)
    -i, --include-drafts Include draft files (files starting with _)
    --backup            Create backup of existing nav file
    --restore           Restore from backup file

DESCRIPTION:
    This script scans the Labs directory and automatically generates a navigation
    structure for MkDocs. It:
    
    1. Discovers all Markdown files and directories
    2. Extracts titles from file headers or uses filename
    3. Organizes content hierarchically
    4. Generates proper YAML navigation structure
    5. Updates the mkdocs navigation configuration

EXAMPLES:
    $0                      # Generate navigation with default settings
    $0 --dry-run           # Preview what would be generated
    $0 --sort numeric      # Sort using numeric prefixes
    $0 --include-drafts    # Include draft files
    $0 --backup            # Create backup before updating

EOF
}

#######################################
# Parse command line arguments
#######################################
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -s|--sort)
                SORT_TYPE="$2"
                if [[ ! "$SORT_TYPE" =~ ^(alpha|numeric|date)$ ]]; then
                    print_error "Invalid sort type: $SORT_TYPE. Use: alpha, numeric, date"
                    exit 1
                fi
                shift 2
                ;;
            -i|--include-drafts)
                INCLUDE_DRAFTS=true
                shift
                ;;
            --backup)
                create_backup
                exit 0
                ;;
            --restore)
                restore_backup
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

#######################################
# Print colored output
#######################################
print_color() {
    printf "${1}%s${NC}\n" "$2"
}

print_info() {
    print_color "$BLUE" "ℹ️  $1"
}

print_success() {
    print_color "$GREEN" "✅ $1"
}

print_warning() {
    print_color "$YELLOW" "⚠️  $1"
}

print_error() {
    print_color "$RED" "❌ $1"
}

print_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        print_info "$1"
    fi
}

#######################################
# Create backup of existing navigation file
#######################################
create_backup() {
    if [[ -f "$NAV_FILE" ]]; then
        cp "$NAV_FILE" "$NAV_BACKUP"
        print_success "Backup created: $NAV_BACKUP"
    else
        print_warning "Navigation file not found: $NAV_FILE"
    fi
}

#######################################
# Restore navigation from backup
#######################################
restore_backup() {
    if [[ -f "$NAV_BACKUP" ]]; then
        cp "$NAV_BACKUP" "$NAV_FILE"
        print_success "Navigation restored from backup"
    else
        print_error "Backup file not found: $NAV_BACKUP"
        exit 1
    fi
}

#######################################
# Extract title from markdown file
# Arguments:
#   $1: file path
#######################################
extract_title() {
    local file="$1"
    local title=""
    
    if [[ -f "$file" ]]; then
        # Try to extract title from first H1 header
        title=$(head -20 "$file" | grep -m1 '^# ' | sed 's/^# //' | sed 's/[[:space:]]*$//' || true)
        
        # If no H1 found, try H2
        if [[ -z "$title" ]]; then
            title=$(head -20 "$file" | grep -m1 '^## ' | sed 's/^## //' | sed 's/[[:space:]]*$//' || true)
        fi
        
        # If still no title, try to extract from frontmatter
        if [[ -z "$title" ]]; then
            title=$(head -20 "$file" | sed -n '/^---$/,/^---$/p' | grep '^title:' | sed 's/^title:[[:space:]]*//' | tr -d '"' || true)
        fi
    fi
    
    # If no title found, generate from filename
    if [[ -z "$title" ]]; then
        title=$(basename "$file" .md)
        # Remove numeric prefixes (e.g., "01-" or "1.")
        title=$(echo "$title" | sed 's/^[0-9][0-9]*[.-][[:space:]]*//')
        # Convert hyphens and underscores to spaces and title case
        title=$(echo "$title" | tr '_-' ' ' | sed 's/\b\w/\U&/g')
    fi
    
    echo "$title"
}

#######################################
# Generate directory title
# Arguments:
#   $1: directory name
#######################################
generate_dir_title() {
    local dir_name="$1"
    local title=""
    
    # Generate from directory name
    title="$dir_name"
    # Convert hyphens and underscores to spaces and title case
    title=$(echo "$title" | tr '_-' ' ' | awk 'BEGIN{FS=OFS=" "} {for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    
    echo "$title"
}

#######################################
# Check if file should be included
# Arguments:
#   $1: file path
#######################################
should_include_file() {
    local file="$1"
    local basename_file
    basename_file=$(basename "$file")
    
    # Skip non-markdown files
    if [[ ! "$file" =~ \.md$ ]]; then
        return 1
    fi
    
    # Skip assets directory
    if [[ "$file" =~ ^assets/ ]]; then
        return 1
    fi
    
    # Skip draft files (starting with _) unless explicitly included
    if [[ "$basename_file" =~ ^_ ]] && [[ "$INCLUDE_DRAFTS" != true ]]; then
        print_verbose "Skipping draft file: $file"
        return 1
    fi
    
    # Skip hidden files (starting with .)
    if [[ "$basename_file" =~ ^\. ]]; then
        return 1
    fi
    
    return 0
}

#######################################
# Sort files based on sort type
# Arguments:
#   Files piped to stdin
#######################################
sort_files() {
    case "$SORT_TYPE" in
        "numeric")
            # Sort by numeric prefix, then alphabetically
            sort -V
            ;;
        "date")
            # Sort by file modification date (newest first)
            while IFS= read -r file; do
                echo "$(stat -f "%m" "$LABS_DIR/$file" 2>/dev/null || echo "0") $file"
            done | sort -rn | cut -d' ' -f2-
            ;;
        "alpha"|*)
            # Alphabetical sort (default)
            sort
            ;;
    esac
}

#######################################
# Get relative path (macOS compatible)
# Arguments:
#   $1: file path
#   $2: base directory
#######################################
get_relative_path() {
    local file_path="$1"
    local base_dir="$2"
    
    # Convert to absolute paths
    file_path=$(cd "$(dirname "$file_path")" && pwd)/$(basename "$file_path")
    base_dir=$(cd "$base_dir" && pwd)
    
    # Remove base directory from file path
    echo "${file_path#$base_dir/}"
}

#######################################
# Generate navigation for a directory
# Arguments:
#   $1: directory path (relative to Labs)
#   $2: indentation level
#######################################
generate_nav_for_directory() {
    local dir_path="$1"
    local indent_level="$2"
    local indent=""
    local full_path="$LABS_DIR/$dir_path"
    local items=()
    
    # Create indentation
    for ((i=0; i<indent_level*2; i++)); do
        indent+=" "
    done
    
    print_verbose "Processing directory: $dir_path (level $indent_level)"
    
    if [[ ! -d "$full_path" ]]; then
        return
    fi
    
    # Get all items in directory
    while IFS= read -r -d '' item; do
        local relative_item
        relative_item=$(get_relative_path "$item" "$LABS_DIR")
        
        if [[ -d "$item" ]]; then
            # Skip assets directory
            if [[ "$(basename "$item")" != "assets" ]]; then
                # Only include directories that contain at least one .md file
                if find "$item" -maxdepth 1 -name "*.md" | grep -q .; then
                    items+=("DIR:$relative_item")
                fi
            fi
        elif should_include_file "$relative_item"; then
            items+=("FILE:$relative_item")
        fi
    done < <(find "$full_path" -maxdepth 1 \( -type f -name "*.md" -o -type d \) -not -path "$full_path" -print0 2>/dev/null)
    
    # Sort items
    local sorted_items=()
    local paths=()
    for item in "${items[@]}"; do
        paths+=("${item#*:}")
    done
    local sorted_paths=()
    while IFS= read -r path; do
        sorted_paths+=("$path")
    done < <(printf '%s\n' "${paths[@]}" | sort_files)
    for sorted_path in "${sorted_paths[@]}"; do
        for item in "${items[@]}"; do
            if [[ "$item" == *:"$sorted_path" ]]; then
                sorted_items+=("$item")
                break
            fi
        done
    done
    
    # Process README.md first if it exists
    local readme_path="$dir_path/README.md"
    if [[ "$dir_path" == "." ]]; then
        readme_path="README.md"
    fi
    
    if [[ -f "$LABS_DIR/$readme_path" ]] && should_include_file "$readme_path"; then
        local title
        title=$(extract_title "$LABS_DIR/$readme_path")
        echo "${indent}- $title: $readme_path"
    fi
    
    # Process other files and directories
    for item in "${sorted_items[@]}"; do
        local item_type="${item%%:*}"
        local item_path="${item#*:}"
        local item_name
        item_name=$(basename "$item_path")
        
        # Skip README.md as it's already processed
        if [[ "$item_name" == "README.md" ]]; then
            continue
        fi
        
        if [[ "$item_type" == "DIR" ]]; then
            local dir_title
            dir_title=$(generate_dir_title "$item_name")
            echo "${indent}- $dir_title:"
            
            # Recursively process subdirectory
            generate_nav_for_directory "$item_path" $((indent_level + 1))
            
        elif [[ "$item_type" == "FILE" ]]; then
            local file_title
            file_title=$(extract_title "$LABS_DIR/$item_path")
            echo "${indent}- $file_title: $item_path"
        fi
    done
}

#######################################
# Generate the complete navigation structure
#######################################
generate_navigation() {
    print_info "Generating navigation structure..."
    
    # Start with YAML header
    cat > "$TEMP_NAV" << 'EOF'
###
### mkdocs-nav.yml
###

nav:
EOF
    
    # Generate navigation starting from Labs directory
    # Temporarily disable verbose output for YAML generation
    local original_verbose="$VERBOSE"
    VERBOSE=false
    generate_nav_for_directory "." 1 >> "$TEMP_NAV"
    VERBOSE="$original_verbose"
    
    print_success "Navigation structure generated"
}

#######################################
# Validate generated YAML
#######################################
validate_yaml() {
    print_info "Validating generated YAML..."
    
    # Try to use virtual environment Python first, then system Python
    local python_cmd=""
    if [[ -f ".venv/bin/python" ]]; then
        python_cmd=".venv/bin/python"
    elif command -v python3 >/dev/null 2>&1; then
        python_cmd="python3"
    else
        print_warning "Python not available for YAML validation"
        return 0
    fi
    
    if $python_cmd -c "
import yaml
import sys
try:
    with open('$TEMP_NAV', 'r') as f:
        yaml.safe_load(f)
except Exception as e:
    print(f'YAML validation error: {e}')
    sys.exit(1)
" 2>/dev/null; then
        print_success "YAML validation passed"
        return 0
    else
        print_warning "YAML validation failed (PyYAML may not be installed)"
        print_info "Performing basic syntax check..."
        
        # Basic YAML syntax check
        if grep -q "^nav:$" "$TEMP_NAV" && ! grep -q "^[[:space:]]*- .*: .*: " "$TEMP_NAV"; then
            print_success "Basic YAML syntax appears valid"
            return 0
        else
            print_error "Basic YAML syntax check failed"
            print_info "Generated content:"
            cat "$TEMP_NAV"
            return 1
        fi
    fi
}

#######################################
# Display the generated navigation
#######################################
show_navigation() {
    print_info "Generated navigation structure:"
    echo
    cat "$TEMP_NAV"
    echo
}

#######################################
# Update the navigation file
#######################################
update_navigation_file() {
    if [[ "$DRY_RUN" == true ]]; then
        print_info "Dry run mode - navigation file not updated"
        return 0
    fi
    
    # Update navigation file
    mv "$TEMP_NAV" "$NAV_FILE"
    print_success "Navigation file updated: $NAV_FILE"
}

#######################################
# Main function
#######################################
main() {
    parse_arguments "$@"
    
    if [[ "$VERBOSE" == true ]]; then
        set -x  # Enable debug mode
    fi
    
    print_info "Dynamic Navigation Builder for MkDocs"
    print_info "Sort type: $SORT_TYPE"
    print_info "Include drafts: $INCLUDE_DRAFTS"
    
    # Check if Labs directory exists
    if [[ ! -d "$LABS_DIR" ]]; then
        print_error "Labs directory not found: $LABS_DIR"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [[ ! -d "${PROJECT_ROOT}/mkdocs" ]]; then
        print_error "mkdocs directory not found. Please run from project root."
        exit 1
    fi
    
    # Generate navigation
    generate_navigation
    
    # Validate YAML
    if ! validate_yaml; then
        print_error "Generated YAML is invalid"
        exit 1
    fi
    
    # Show navigation if verbose or dry run
    if [[ "$VERBOSE" == true ]] || [[ "$DRY_RUN" == true ]]; then
        show_navigation
    fi
    
    # Update navigation file
    update_navigation_file
    
    print_success "Navigation build complete!"
    
    if [[ "$DRY_RUN" != true ]]; then
        print_info "To rebuild your site, run: mkdocs build"
    fi
}

# Cleanup function
cleanup() {
    if [[ -f "$TEMP_NAV" ]]; then
        rm -f "$TEMP_NAV"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
