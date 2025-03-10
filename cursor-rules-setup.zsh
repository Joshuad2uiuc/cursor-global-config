#!/bin/zsh
# cursor-rules-setup.zsh - Enhanced Global Cursor Rules Management for macOS

# Configuration
REPO_URL="https://github.com/Joshuad2uiuc/cursor-global-config.git"
LOCAL_REPO_PATH="$HOME/.cursor-global-config"
RULES_FILE="global-rules.mdc"
TARGET_FILENAME=".cursorrules"

# Function to ensure repository is up to date
update_rules_repo() {
  echo "🔄 Updating cursor rules from repository..."
  
  # Check if the directory exists
  if [[ ! -d "$LOCAL_REPO_PATH" ]]; then
    echo "📂 Creating repository directory..."
    mkdir -p "$LOCAL_REPO_PATH"
  fi
  
  # Check if it's a git repository
  if [[ -d "$LOCAL_REPO_PATH/.git" ]]; then
    # It's already a git repository, pull latest changes
    (cd "$LOCAL_REPO_PATH" && git pull origin main)
  else
    # It's not a git repository, clone into it
    if [[ "$(ls -A "$LOCAL_REPO_PATH")" ]]; then
      # Directory is not empty, need to handle existing files
      echo "⚠️ Directory exists but is not a git repository and contains files."
      echo "   Will clone repository to a temporary location and copy rules."
      
      # Clone to temporary directory
      TEMP_DIR=$(mktemp -d)
      git clone "$REPO_URL" "$TEMP_DIR"
      
      # Copy just the rules file
      if [[ -f "$TEMP_DIR/$RULES_FILE" ]]; then
        cp "$TEMP_DIR/$RULES_FILE" "$LOCAL_REPO_PATH/"
        echo "✅ Rules file copied from repository to $LOCAL_REPO_PATH/$RULES_FILE"
      else
        echo "❌ Rules file not found in repository"
        rm -rf "$TEMP_DIR"
        return 1
      fi
      
      # Clean up
      rm -rf "$TEMP_DIR"
    else
      # Directory is empty, clean clone
      git clone "$REPO_URL" "$LOCAL_REPO_PATH"
    fi
  fi
  
  # Verify that the rules file exists
  if [[ ! -f "$LOCAL_REPO_PATH/$RULES_FILE" ]]; then
    echo "❌ Rules file not found at $LOCAL_REPO_PATH/$RULES_FILE"
    return 1
  fi
  
  echo "✅ Rules repository updated successfully"
  return 0
}

# Function to apply rules to current project
apply_cursor_rules() {
  local target_dir="${1:-.}"
  local target_file="$target_dir/$TARGET_FILENAME"
  local source_file="$LOCAL_REPO_PATH/$RULES_FILE"
  
  # Ensure rules repo is up to date
  update_rules_repo || return 1
  
  # Check if target directory exists
  if [[ ! -d "$target_dir" ]]; then
    echo "❌ Target directory does not exist: $target_dir"
    return 1
  fi
  
  # Check if global rules file exists
  if [[ ! -f "$source_file" ]]; then
    echo "❌ Global rules file not found: $source_file"
    return 1
  fi
  
  # Handle existing rules file
  if [[ -f "$target_file" ]]; then
    echo "⚠️ Cursor rules file already exists at: $target_file"
    echo -n "Do you want to replace it? (y/n): "
    read -r answer
    
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "❌ Operation cancelled"
      return 1
    fi
    
    # Backup existing file
    cp "$target_file" "${target_file}.backup"
    echo "📄 Existing rules backed up to ${target_file}.backup"
  fi
  
  # Copy global rules to target
  cp "$source_file" "$target_file"
  
  if [[ $? -eq 0 ]]; then
    echo "✅ Cursor rules applied successfully to $target_dir"
    return 0
  else
    echo "❌ Failed to apply cursor rules"
    return 1
  fi
}

# Function to apply rules to multiple projects
apply_cursor_rules_batch() {
  local dirs=("$@")
  
  # If no directories provided, use current directory
  if [[ ${#dirs[@]} -eq 0 ]]; then
    dirs=(".")
  fi
  
  # Ensure rules repo is up to date first
  update_rules_repo || return 1
  
  local success_count=0
  local fail_count=0
  
  echo "🚀 Applying cursor rules to ${#dirs[@]} project(s)..."
  
  for dir in "${dirs[@]}"; do
    echo "📁 Processing directory: $dir"
    if apply_cursor_rules "$dir"; then
      ((success_count++))
    else
      ((fail_count++))
    fi
  done
  
  echo "✅ Applied rules to $success_count project(s)"
  if [[ $fail_count -gt 0 ]]; then
    echo "❌ Failed to apply rules to $fail_count project(s)"
  fi
}

# Function to create a symlink instead of copying
link_cursor_rules() {
  local target_dir="${1:-.}"
  local target_file="$target_dir/$TARGET_FILENAME"
  local source_file="$LOCAL_REPO_PATH/$RULES_FILE"
  
  # Ensure rules repo is up to date
  update_rules_repo || return 1
  
  # Handle existing rules file
  if [[ -f "$target_file" ]]; then
    if [[ -L "$target_file" ]]; then
      echo "⚠️ Symlink already exists at: $target_file"
      echo -n "Do you want to replace it? (y/n): "
    else
      echo "⚠️ Cursor rules file already exists at: $target_file"
      echo -n "Do you want to replace it with a symlink? (y/n): "
    fi
    
    read -r answer
    
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "❌ Operation cancelled"
      return 1
    fi
    
    # Backup existing file if it's not a symlink
    if [[ ! -L "$target_file" ]]; then
      cp "$target_file" "${target_file}.backup"
      echo "📄 Existing rules backed up to ${target_file}.backup"
    fi
    
    # Remove existing file or symlink
    rm "$target_file"
  fi
  
  # Create symbolic link
  ln -s "$source_file" "$target_file"
  
  if [[ $? -eq 0 ]]; then
    echo "✅ Cursor rules symlinked successfully to $target_dir"
    return 0
  else
    echo "❌ Failed to create symlink"
    return 1
  fi
}

# Initialize project with both global and project-specific rules
init_cursor_rules() {
  local target_dir="${1:-.}"
  local cursor_dir="$target_dir/.cursor"
  local rules_dir="$cursor_dir/rules"
  local global_target="$rules_dir/global-rules.mdc"
  local project_rules="$rules_dir/project-rules.mdc"
  local source_file="$LOCAL_REPO_PATH/$RULES_FILE"
  
  # Ensure rules repo is up to date
  update_rules_repo || return 1
  
  # Check if target directory exists
  if [[ ! -d "$target_dir" ]]; then
    echo "❌ Target directory does not exist: $target_dir"
    return 1
  fi
  
  # Create .cursor/rules directory structure
  echo "📁 Creating Cursor rules directory structure..."
  mkdir -p "$rules_dir"
  
  # Check if project rules already exist
  if [[ -f "$project_rules" ]]; then
    echo "⚠️ Project-specific rules already exist at: $project_rules"
    echo -n "Do you want to replace them? (y/n): "
    read -r answer
    
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "❌ Project rules initialization cancelled"
      # But continue with global rules
    else
      # Backup existing project rules
      cp "$project_rules" "${project_rules}.backup"
      echo "📄 Existing project rules backed up to ${project_rules}.backup"
      
      # Create new project-specific rules file
      create_project_rules "$project_rules" "$(basename $target_dir)"
    fi
  else
    # Create new project-specific rules file
    create_project_rules "$project_rules" "$(basename $target_dir)"
  fi
  
  # Copy or link global rules
  if [[ -f "$global_target" ]]; then
    echo "⚠️ Global rules already exist in project at: $global_target"
    echo -n "Do you want to update them? (y/n): "
    read -r answer
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      if [[ -L "$global_target" ]]; then
        # Already a symlink, no need to do anything
        echo "ℹ️ Global rules are already symlinked and up to date"
      else
        # Replace file with latest version
        cp "$source_file" "$global_target"
        echo "✅ Global rules updated successfully"
      fi
    fi
  else
    # Ask whether to symlink or copy
    echo -n "Do you want to symlink global rules (recommended for auto-updates)? (y/n): "
    read -r answer
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      ln -s "$source_file" "$global_target"
      echo "✅ Global rules symlinked to project"
    else
      cp "$source_file" "$global_target"
      echo "✅ Global rules copied to project"
    fi
  fi
  
  echo "🎉 Project initialized successfully with Cursor rules!"
  echo ""
  echo "Structure created:"
  echo "  $target_dir/"
  echo "  └── .cursor/"
  echo "      └── rules/"
  echo "          ├── global-rules.mdc (from your global config)"
  echo "          └── project-rules.mdc (project-specific rules)"
  echo ""
  echo "Customize project-specific rules at:"
  echo "  $project_rules"
  
  return 0
}

# Helper function to create project-specific rules template
create_project_rules() {
  local project_rules_file="$1"
  local project_name="$2"
  
  cat > "$project_rules_file" << EOL
---
description: Project-specific rules for ${project_name}
globs: ["**/*.{js,jsx,ts,tsx,md,css,scss,html,py}"]
extends: ["global-rules.mdc"]
---

# ${project_name} Project Rules

@context {
    "type": "cursor_rules",
    "purpose": "project_standards",
    "format_version": "1.0.0",
    "extends": "global-rules"
}

## Project-Specific Guidelines

@project_rules {
    "architecture": "Define the architecture pattern for this project",
    "state_management": "Specify the state management approach",
    "api_integration": "Define how API integration should be handled"
}

<!-- Add your project-specific rules below -->

<rule>
name: project_specific_naming
description: Enforce project-specific naming conventions
filters:
  - type: file_extension
    pattern: "\.(js|ts|jsx|tsx)$"

actions:
  - type: suggest
    message: |
      Project-specific naming conventions:
      
      - API services: suffix with "Service" (e.g., userService)
      - Components: PascalCase, prefixed by feature (e.g., AuthLoginForm)
      - Add your own conventions here...

metadata:
  priority: medium
  version: 1.0
</rule>

<!-- Add more project-specific rules as needed -->
EOL

  echo "✅ Created project-specific rules template"
}

# Function to initialize automatic application of cursor rules
setup_git_hooks() {
  local hooks_dir=".git/hooks"
  
  if [[ ! -d ".git" ]]; then
    echo "❌ Not a git repository. Initialize with 'git init' first."
    return 1
  fi
  
  mkdir -p "$hooks_dir"
  
  # Create post-checkout hook to automatically apply cursor rules
  cat > "$hooks_dir/post-checkout" << 'EOL'
#!/bin/zsh
# Apply cursor rules after checkout
~/.cursor-global-config/cursor-rules-setup.zsh apply
EOL
  
  chmod +x "$hooks_dir/post-checkout"
  
  echo "✅ Git hooks installed. Cursor rules will be applied automatically after checkout."
}

# Main execution
case "$1" in
  update)
    update_rules_repo
    ;;
  apply)
    shift
    apply_cursor_rules_batch "$@"
    ;;
  link)
    shift
    link_cursor_rules "$@"
    ;;
  init)
    shift
    init_cursor_rules "$@"
    ;;
  hooks)
    setup_git_hooks
    ;;
  *)
    echo "Cursor Rules Manager"
    echo "Usage:"
    echo "  $0 update               - Update rules from repository"
    echo "  $0 init [dir]           - Initialize project with global + project-specific rules"
    echo "  $0 apply [dir1 dir2...] - Apply rules to specified directories (or current dir)"
    echo "  $0 link [dir]           - Create symlink to rules instead of copying"
    echo "  $0 hooks                - Setup git hooks for auto-applying rules"
    ;;
esac