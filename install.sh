#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_AGENTS="$HOME/.claude/agents"
CLAUDE_COMMANDS="$HOME/.claude/commands"
PREFIX="sv-"
COMMAND_FILE="validate-idea.md"

mkdir -p "$CLAUDE_AGENTS" "$CLAUDE_COMMANDS"

action="${1:-install}"

if [[ "$action" == "--uninstall" || "$action" == "uninstall" ]]; then
  echo "Removing startup-validator symlinks..."
  for f in "$CLAUDE_AGENTS"/${PREFIX}*.md; do
    [[ -L "$f" ]] && rm -v "$f"
  done
  if [[ -L "$CLAUDE_COMMANDS/$COMMAND_FILE" ]]; then
    rm -v "$CLAUDE_COMMANDS/$COMMAND_FILE"
  fi
  echo "Done."
  exit 0
fi

echo "Installing startup-validator into ~/.claude/..."
echo

for agent in "$REPO_DIR"/.claude/agents/*.md; do
  base="$(basename "$agent")"
  target="$CLAUDE_AGENTS/${PREFIX}${base}"
  ln -sfn "$agent" "$target"
  echo "  agent   -> $target"
done

ln -sfn "$REPO_DIR/.claude/commands/$COMMAND_FILE" "$CLAUDE_COMMANDS/$COMMAND_FILE"
echo "  command -> $CLAUDE_COMMANDS/$COMMAND_FILE"

echo
echo "Installed. Restart Claude Code, then run: /validate-idea"
