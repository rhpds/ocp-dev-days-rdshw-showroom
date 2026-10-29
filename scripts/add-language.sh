#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

insert_after_line() {
  local lineno="$1" text="$2" file="$3"
  { head -n "$lineno" "$file"; printf '%s\n' "$text"; tail -n +"$((lineno + 1))" "$file"; } > "$file.tmp" && mv "$file.tmp" "$file"
}

insert_before_match() {
  local pattern="$1" text="$2" file="$3"
  awk -v p="$pattern" -v t="$text" '$0 ~ p{print t} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

insert_after_match() {
  local pattern="$1" text="$2" file="$3"
  awk -v p="$pattern" -v t="$text" '1; $0 ~ p{print t}' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
CONFIG_FILE="$REPO_ROOT/i18n/config.yaml"

# Defaults
LANG=""
NAME=""
NATIVE_NAME=""
FLAG=""
MODEL=""
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") --lang <code> --name <name> --native-name <native> --flag <emoji> [OPTIONS]

Bootstrap a new language for the showroom content.

Options:
  --lang <code>            Language code (e.g. ko, es, zh)
  --name <name>            English name (e.g. Korean, Spanish)
  --native-name <native>   Native name (e.g. 한국어, Español)
  --flag <emoji>           Flag emoji (e.g. 🇰🇷, 🇪🇸)
  --model <id>             Model for initial translation (default: from opencode.json)
  --dry-run                Show what would be done without making changes
  -h, --help               Show this help
EOF
  exit 0
}

# ── arg parsing ──────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang)        LANG="$2"; shift 2 ;;
    --name)        NAME="$2"; shift 2 ;;
    --native-name) NATIVE_NAME="$2"; shift 2 ;;
    --flag)        FLAG="$2"; shift 2 ;;
    --model)       MODEL="$2"; shift 2 ;;
    --dry-run)     DRY_RUN=true; shift ;;
    -h|--help)     usage ;;
    *)             echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

for required in LANG NAME NATIVE_NAME FLAG; do
  if [[ -z "${!required}" ]]; then
    echo "Error: --$(echo "$required" | tr '[:upper:]' '[:lower:]' | tr '_' '-') is required" >&2
    exit 1
  fi
done

# ── dependency checks ────────────────────────────────────────────────────────

for cmd in jq yq git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is required but not found in PATH" >&2
    exit 1
  fi
done

# ── validate ─────────────────────────────────────────────────────────────────

if yq -e ".target_languages.$LANG" "$CONFIG_FILE" &>/dev/null; then
  echo "Error: language '$LANG' already exists in $CONFIG_FILE" >&2
  exit 1
fi

if [[ -d "$REPO_ROOT/content/$LANG" ]]; then
  echo "Error: content/$LANG/ already exists" >&2
  exit 1
fi

echo "==> Adding language: $LANG ($NAME / $NATIVE_NAME $FLAG)"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run — the following steps would be performed:"
  echo ""
  echo "  1. Add '$LANG' entry to i18n/config.yaml"
  echo "  2. Copy content/en/ → content/$LANG/"
  echo "  3. Create content/$LANG/antora.yml (version: $LANG, display: $NATIVE_NAME)"
  echo "  4. Add content source to site.yml and local-site.yml"
  echo "  5. Add $LANG to language-switcher.js"
  echo "  6. Add $LANG validation to .github/workflows/gh-pages.yml"
  echo "  7. Run translate.sh --lang $LANG for initial translation"
  exit 0
fi

# ── 1. update config.yaml ────────────────────────────────────────────────────

echo "==> [1/7] Updating i18n/config.yaml..."
yq -i ".target_languages.$LANG = {
  \"name\": \"$NAME\",
  \"native_name\": \"$NATIVE_NAME\",
  \"flag\": \"$FLAG\",
  \"antora_display_version\": \"$NATIVE_NAME\"
}" "$CONFIG_FILE"

# ── 2. copy content directory ────────────────────────────────────────────────

echo "==> [2/7] Copying content/en/ → content/$LANG/..."
cp -r "$REPO_ROOT/content/en" "$REPO_ROOT/content/$LANG"

# Replace copied images with a symlink to en to avoid duplication
rm -rf "$REPO_ROOT/content/$LANG/modules/ROOT/assets/images"
ln -s ../../../../en/modules/ROOT/assets/images "$REPO_ROOT/content/$LANG/modules/ROOT/assets/images"

# ── 3. create antora.yml ─────────────────────────────────────────────────────

echo "==> [3/7] Writing content/$LANG/antora.yml..."
cat > "$REPO_ROOT/content/$LANG/antora.yml" <<EOF
name: modules
title: OpenShift Dev Day
version: $LANG
display_version: $NATIVE_NAME
prerelease: false
nav:
  - modules/ROOT/nav.adoc

asciidoc:
  attributes:
    experimental: true
    page-pagination: true
    page-lang: $LANG
EOF

# ── 4. patch site.yml and local-site.yml ─────────────────────────────────────

echo "==> [4/7] Adding content source to site.yml and local-site.yml..."

for site_file in site.yml local-site.yml; do
  filepath="$REPO_ROOT/$site_file"
  if [[ ! -f "$filepath" ]]; then
    echo "    Warning: $site_file not found, skipping"
    continue
  fi

  # Check if the content source already exists
  if grep -q "start_path: content/$LANG" "$filepath"; then
    echo "    $site_file already has content/$LANG, skipping"
    continue
  fi

  # Add new content source after the last existing one
  # Find the line with the last "start_path:" and add after the next line
  LAST_START_PATH_LINE=$(grep -n "start_path: content/" "$filepath" | tail -1 | cut -d: -f1)
  if [[ -n "$LAST_START_PATH_LINE" ]]; then
    # Find the "branches:" line that follows
    BRANCHES_LINE=$(tail -n +"$LAST_START_PATH_LINE" "$filepath" | grep -n "branches:" | head -1 | cut -d: -f1)
    INSERT_AFTER=$((LAST_START_PATH_LINE + BRANCHES_LINE - 1))
    insert_after_line "$INSERT_AFTER" "    - url: .
      start_path: content/$LANG
      branches: HEAD" "$filepath"
  fi
done

# ── 5. patch language-switcher.js ────────────────────────────────────────────

echo "==> [5/7] Adding $LANG to language-switcher.js..."

SWITCHER_FILE="$REPO_ROOT/supplemental-ui/js/language-switcher.js"

if grep -q "'$LANG':" "$SWITCHER_FILE" || grep -q "\"$LANG\":" "$SWITCHER_FILE"; then
  echo "    language-switcher.js already has '$LANG', skipping"
else
  # Find the last language entry line (e.g. "    ja: { label: ...") and insert after it
  LAST_LANG_LINE=$(grep -n "label:.*flag:" "$SWITCHER_FILE" | tail -1 | cut -d: -f1)
  if [[ -n "$LAST_LANG_LINE" ]]; then
    # Ensure the previous last entry has a trailing comma
    if ! sed -n "${LAST_LANG_LINE}p" "$SWITCHER_FILE" | grep -q ',$'; then
      awk -v n="$LAST_LANG_LINE" 'NR==n{sub(/}[[:space:]]*$/, "},"); sub(/\x27[[:space:]]*$/, "\x27,")} 1' "$SWITCHER_FILE" > "$SWITCHER_FILE.tmp" && mv "$SWITCHER_FILE.tmp" "$SWITCHER_FILE"
    fi
    insert_after_line "$LAST_LANG_LINE" "    $LANG: { label: '$NATIVE_NAME', flag: '$FLAG' }," "$SWITCHER_FILE"
  fi
fi

# ── 6. patch gh-pages.yml ────────────────────────────────────────────────────

echo "==> [6/7] Adding $LANG validation to gh-pages.yml..."

GH_PAGES_FILE="$REPO_ROOT/.github/workflows/gh-pages.yml"

if grep -q "modules/$LANG/index.html" "$GH_PAGES_FILE"; then
  echo "    gh-pages.yml already validates '$LANG', skipping"
else
  # Add validation check after the Japanese validation
  insert_after_match "test -f www/modules/ja/index.html" "          test -f www/modules/$LANG/index.html || { echo \"$NAME version not built\"; exit 1; }" "$GH_PAGES_FILE"

  # Add image validation
  insert_after_match "test -d www/modules/ja/_images" "          test -d www/modules/$LANG/_images || { echo \"$NAME images missing\"; exit 1; }" "$GH_PAGES_FILE"
fi

# ── 7. run initial translation ───────────────────────────────────────────────

echo "==> [7/7] Running initial translation..."
echo ""

MODEL_ARG=""
if [[ -n "$MODEL" ]]; then
  MODEL_ARG="--model $MODEL"
fi

"$REPO_ROOT/scripts/translate.sh" --lang "$LANG" $MODEL_ARG

echo ""
echo "==> Language '$LANG' ($NAME) has been added successfully."
echo ""
echo "Next steps:"
echo "  1. Review the translated content in content/$LANG/"
echo "  2. Build locally: antora site.yml"
echo "  3. Commit and push"
