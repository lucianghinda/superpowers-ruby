#!/usr/bin/env bash
# fetch-changelogs.sh
#
# Fetches Rails CHANGELOG entries from GitHub for a specific version.
#
# Usage:
#   ./fetch-changelogs.sh <version|main> [output_dir]
#   ./fetch-changelogs.sh --list-versions
#
# Examples:
#   ./fetch-changelogs.sh 8.1.0
#   ./fetch-changelogs.sh 8.1.3.1              # security patch (4 segments)
#   ./fetch-changelogs.sh main ./changelogs    # unreleased entries from main
#   ./fetch-changelogs.sh --list-versions
#
# Requirements: curl

set -euo pipefail

# Configuration
VERSION="${1:-}"
OUTPUT_DIR="${2:-.}"
RAILS_REPO="rails/rails"
GITHUB_RAW="https://raw.githubusercontent.com/${RAILS_REPO}"
GITHUB_API="https://api.github.com/repos/${RAILS_REPO}"

COMPONENTS=(
  "actioncable"
  "actionmailbox"
  "actionmailer"
  "actionpack"
  "actiontext"
  "actionview"
  "activejob"
  "activemodel"
  "activerecord"
  "activestorage"
  "activesupport"
  "railties"
)


# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

check_curl() {
  if ! command -v curl > /dev/null 2>&1; then
    echo "Error: curl is required but not found. Please install curl and try again." >&2
    exit 1
  fi
}

show_help() {
  cat <<EOF
fetch-changelogs.sh — Fetch Rails CHANGELOG entries from GitHub

Usage:
  ./fetch-changelogs.sh <version|main> [output_dir]
  ./fetch-changelogs.sh --list-versions
  ./fetch-changelogs.sh --help

Arguments:
  version     Rails version to fetch. Accepts 2, 3, or 4 segments —
              8.1, 8.1.0, and 8.1.3.1 (security patch) are all valid.
              Pass 'main' to fetch the unreleased entries at the top of
              each CHANGELOG on the main branch (currently Rails 8.2).
  output_dir  Directory to write output files (default: current directory)

Flags:
  --list-versions   List the 20 most recent Rails release tags on GitHub
  --help            Show this help message

Examples:
  ./fetch-changelogs.sh 8.1.0
  ./fetch-changelogs.sh 8.1.3.1 ./changelogs
  ./fetch-changelogs.sh main ./changelogs
  ./fetch-changelogs.sh --list-versions

Output files:
  {output_dir}/{component}-{version}.md      Per-component changelog section
  {output_dir}/rails-{version}-changelog.md  Consolidated changelog

Requirements: curl
EOF
}

list_versions() {
  echo "Fetching available Rails versions..."
  local result
  result=$(curl --silent --fail "${GITHUB_API}/tags?per_page=30" 2>/dev/null) || {
    echo "Error: Failed to fetch tags from GitHub API. Check your network connection." >&2
    exit 1
  }
  echo ""
  echo "Most recent Rails release tags:"
  echo ""
  echo "$result" \
    | grep '"name"' \
    | sed 's/.*"name": *"v\([^"]*\)".*/\1/' \
    | grep '^[0-9]' \
    | head -20
}

# Map a user-supplied version into the git ref that holds it.
# Released versions live under a "v"-prefixed tag; "main" is a branch name.
git_ref() {
  local version="$1"
  if [[ "$version" == "main" ]]; then
    echo "main"
  else
    echo "v${version}"
  fi
}

check_version_exists() {
  local version="$1"
  local url="${GITHUB_RAW}/$(git_ref "$version")/railties/CHANGELOG.md"
  curl --silent --head --fail "$url" > /dev/null 2>&1
}

# Extract only the section for the target version from a CHANGELOG file.
# Rails CHANGELOGs use headers like:
#   ## Rails 8.1.0 (January 22, 2025) ##
#
# We capture text from the matching header line up to (but not including)
# the next "## Rails X.Y.Z" header.
extract_version_section() {
  local content="$1"
  local version="$2"

  echo "$content" | awk -v ver="$version" '
    # Start capturing when we hit the exact version header
    /^## Rails [[:space:]]*/ && $0 ~ ("Rails " ver) {
      found = 1
      print
      next
    }
    # Stop (without printing) when we hit the next version header
    found && /^## Rails [0-9]/ {
      exit
    }
    found {
      print
    }
  '
}

# Extract the UNRELEASED entries from a main-branch CHANGELOG.
#
# Unlike a tagged CHANGELOG, main has no "## Rails X.Y.Z" header to anchor on.
# When Rails cuts a release branch, main's CHANGELOGs are emptied, so what remains
# at the top of the file is everything merged since — i.e. the next version.
#
# A main-branch CHANGELOG looks like this, with no version headers at all:
#
#     *   Some change description.
#
#         More detail about the change.
#
#         *Author Name*
#
#     *   Another change.
#
#         *Author Name*
#
#
#     Please check [8-1-stable](https://github.com/.../CHANGELOG.md) for previous changes.
#
# Print the unreleased entries from "$content". Print nothing when there are none,
# so the caller's existing "SKIP (no section)" branch handles empty components.
extract_unreleased_section() {
  local content="$1"

  echo "$content" | awk '
    # Defensive: main is not expected to carry release headers, but if Rails ever
    # changes how the branch is managed, stop rather than dump the whole history.
    /^## Rails [0-9]/ {
      exit
    }
    # Drop the pointer to the previous stable branch. It documents the PREVIOUS
    # release, so it is misleading inside a file labelled "unreleased".
    /^Please check .* for previous changes\.?[[:space:]]*$/ {
      next
    }
    {
      lines[n++] = $0
    }
    END {
      # Trim trailing blank lines so a component with no unreleased entries
      # yields a genuinely empty string, not a run of newlines.
      while (n > 0 && lines[n - 1] ~ /^[[:space:]]*$/) {
        n--
      }
      for (i = 0; i < n; i++) {
        print lines[i]
      }
    }
  '
}

# Pretty-print a component name (falls back to the raw key if somehow missing)
component_display_name() {
  local component="$1"
  case "$component" in
    actioncable)   echo "Action Cable" ;;
    actionmailbox) echo "Action Mailbox" ;;
    actionmailer)  echo "Action Mailer" ;;
    actionpack)    echo "Action Pack" ;;
    actiontext)    echo "Action Text" ;;
    actionview)    echo "Action View" ;;
    activejob)     echo "Active Job" ;;
    activemodel)   echo "Active Model" ;;
    activerecord)  echo "Active Record" ;;
    activestorage) echo "Active Storage" ;;
    activesupport) echo "Active Support" ;;
    railties)      echo "Railties" ;;
    *)             echo "$component" ;;
  esac
}

# ──────────────────────────────────────────────
# Main fetch logic
# ──────────────────────────────────────────────

fetch_changelogs() {
  local version="$1"
  local output_dir="$2"

  local ref
  ref=$(git_ref "$version")

  # Create output directory if needed
  if [[ ! -d "$output_dir" ]]; then
    echo "Creating output directory: $output_dir"
    mkdir -p "$output_dir"
  fi

  echo "Checking that '${ref}' exists on GitHub..."
  if ! check_version_exists "$version"; then
    echo ""
    echo "Warning: Could not find '${ref}' in rails/rails." >&2
    if [[ "$version" == "main" ]]; then
      echo "         The main branch was unreachable — check your network connection." >&2
    else
      echo "         The tag '${ref}' may not exist or the network is unreachable." >&2
      echo "" >&2
      echo "Run './fetch-changelogs.sh --list-versions' to see available versions." >&2
    fi
    exit 1
  fi

  if [[ "$version" == "main" ]]; then
    echo "Found '${ref}'. Fetching UNRELEASED changelogs..."
  else
    echo "Found '${ref}'. Fetching changelogs..."
  fi
  echo ""

  local consolidated_file="${output_dir}/rails-${version}-changelog.md"
  local generated_date
  generated_date=$(date +"%Y-%m-%d")

  local title_note=""
  if [[ "$version" == "main" ]]; then
    title_note="
NOTE: These are UNRELEASED entries from the main branch. They describe the next
Rails version, which has not shipped. Entries can change or be reverted before
release — verify against main before relying on any of them.
"
  fi

  # Write consolidated file header
  cat > "$consolidated_file" <<EOF
# Rails ${version} CHANGELOG

Generated by fetch-changelogs.sh on ${generated_date}
Source: https://github.com/rails/rails/blob/${ref}/*/CHANGELOG.md
${title_note}
---

EOF

  local fetched_count=0
  local skipped_count=0

  for component in "${COMPONENTS[@]}"; do
    local url="${GITHUB_RAW}/${ref}/${component}/CHANGELOG.md"
    local per_component_file="${output_dir}/${component}-${version}.md"
    local display_name
    display_name=$(component_display_name "$component")

    printf "  Fetching %-20s CHANGELOG from %s... " "$component" "$ref"

    # Fetch with error suppressed; detect failure via exit code
    local raw_content
    if ! raw_content=$(curl --silent --fail "$url" 2>/dev/null); then
      printf "SKIP (not found)\n"
      skipped_count=$((skipped_count + 1))
      continue
    fi

    # Extract only the section relevant to this version. On main there is no
    # version header to anchor on, so the unreleased entries are taken instead.
    local section
    if [[ "$version" == "main" ]]; then
      section=$(extract_unreleased_section "$raw_content")
    else
      section=$(extract_version_section "$raw_content" "$version")
    fi

    if [[ -z "$section" ]]; then
      # File exists but no section found. For a tagged version this means a point
      # release that only touched some components; on main it means the component
      # has no unreleased changes yet.
      printf "SKIP (no section for %s in CHANGELOG)\n" "$version"
      skipped_count=$((skipped_count + 1))
      continue
    fi

    local line_count
    line_count=$(echo "$section" | wc -l | tr -d ' ')

    # Write per-component file
    {
      echo "# ${display_name} — Rails ${version} CHANGELOG"
      echo ""
      echo "$section"
    } > "$per_component_file"

    # Append to consolidated file
    {
      echo "## ${display_name}"
      echo ""
      echo "$section"
      echo ""
      echo "---"
      echo ""
    } >> "$consolidated_file"

    printf "OK (%s lines)\n" "$line_count"
    fetched_count=$((fetched_count + 1))
  done

  echo ""
  echo "Done."
  echo "  Fetched : ${fetched_count} component(s)"
  echo "  Skipped : ${skipped_count} component(s)"
  echo ""
  echo "Output written to: ${output_dir}/"
  echo "  Consolidated : rails-${version}-changelog.md"
  if [[ $fetched_count -gt 0 ]]; then
    echo "  Per-component: {component}-${version}.md (${fetched_count} file(s))"
  fi
}

# ──────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────

main() {
  check_curl

  if [[ -z "$VERSION" ]]; then
    show_help
    exit 0
  fi

  case "$VERSION" in
    --help|-h)
      show_help
      exit 0
      ;;
    --list-versions)
      list_versions
      exit 0
      ;;
    -*)
      echo "Error: Unknown flag: $VERSION" >&2
      echo ""
      show_help
      exit 1
      ;;
    main)
      fetch_changelogs "main" "$OUTPUT_DIR"
      ;;
    *)
      # Validate that it looks like a version number.
      # Rails security releases carry a fourth segment (e.g. 8.1.3.1), so the
      # last two segments are both optional.
      if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+){0,2}$'; then
        echo "Error: '$VERSION' does not look like a valid version number." >&2
        echo "       Expected 2-4 numeric segments (e.g. 8.1, 8.1.0, 8.1.3.1) or 'main'." >&2
        exit 1
      fi
      fetch_changelogs "$VERSION" "$OUTPUT_DIR"
      ;;
  esac
}

main "$@"
