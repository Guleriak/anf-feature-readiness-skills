#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Guleriak/anf-feature-readiness-skills.git"
SKILLS_DIR="$HOME/.cursor/skills"
BRANCH="main"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$SKILLS_DIR/.backup-$TIMESTAMP"

SKILL_FOLDERS=(
  "Weekly-Ring"
  "feature-readiness-hub"
  "feature-readiness-plan"
)
EXTRA_FILES=(
  "SETUP-GUIDE.md"
)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${GREEN}[INFO]${NC}  %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

if ! command -v git &>/dev/null; then
  error "git is not installed. Please install git first."
  exit 1
fi

TMPDIR_CLONE=$(mktemp -d "${TMPDIR:-/tmp}/anf-skills-install.XXXXXX" 2>/dev/null || mktemp -d)
trap 'rm -rf "$TMPDIR_CLONE"' EXIT

info "Cloning $REPO_URL (branch: $BRANCH) ..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMPDIR_CLONE" 2>&1 | sed 's/^/     /'

mkdir -p "$SKILLS_DIR"

NEEDS_BACKUP=false
for folder in "${SKILL_FOLDERS[@]}"; do
  if [ -d "$SKILLS_DIR/$folder" ]; then
    NEEDS_BACKUP=true
    break
  fi
done
for file in "${EXTRA_FILES[@]}"; do
  if [ -f "$SKILLS_DIR/$file" ]; then
    NEEDS_BACKUP=true
    break
  fi
done

if $NEEDS_BACKUP; then
  info "Backing up existing skills to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  for folder in "${SKILL_FOLDERS[@]}"; do
    if [ -d "$SKILLS_DIR/$folder" ]; then
      cp -R "$SKILLS_DIR/$folder" "$BACKUP_DIR/"
    fi
  done
  for file in "${EXTRA_FILES[@]}"; do
    if [ -f "$SKILLS_DIR/$file" ]; then
      cp "$SKILLS_DIR/$file" "$BACKUP_DIR/"
    fi
  done
fi

for folder in "${SKILL_FOLDERS[@]}"; do
  if [ -d "$TMPDIR_CLONE/$folder" ]; then
    info "Installing skill: $folder"
    rm -rf "$SKILLS_DIR/$folder"
    cp -R "$TMPDIR_CLONE/$folder" "$SKILLS_DIR/$folder"
  else
    warn "Skill folder '$folder' not found in repo � skipped"
  fi
done

for file in "${EXTRA_FILES[@]}"; do
  if [ -f "$TMPDIR_CLONE/$file" ]; then
    info "Installing file: $file"
    cp "$TMPDIR_CLONE/$file" "$SKILLS_DIR/$file"
  fi
done

echo ""
info "Installation complete! Installed skills:"
echo ""
for folder in "${SKILL_FOLDERS[@]}"; do
  if [ -d "$SKILLS_DIR/$folder" ]; then
    printf "  %-30s %s\n" "$folder/" "$(ls "$SKILLS_DIR/$folder" | tr '\n' ' ')"
  fi
done
echo ""

if $NEEDS_BACKUP; then
  info "Backup saved at: $BACKUP_DIR"
fi

echo ""
info "Next steps:"
echo "  1. Review SETUP-GUIDE.md for personalization instructions (Step 4)"
echo "  2. Update Confluence page IDs and space IDs in SKILL.md files"
echo "  3. Ensure ~/.cursor/mcp.json is configured (see SETUP-GUIDE.md Step 3)"
echo "  4. Restart Cursor to pick up changes"
echo ""
