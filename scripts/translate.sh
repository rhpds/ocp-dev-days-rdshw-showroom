#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/i18n/config.yaml"
STATUS_FILE="$REPO_ROOT/i18n/translation-status.json"
EN_ROOT="$REPO_ROOT/content/en/modules/ROOT"

# Defaults
LANG=""
MODEL=""
SPECIFIC_FILE=""
DRY_RUN=false
CLEAN_ORPHANS=false
FORCE=false
REVIEW_GUIDE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") --lang <code> [OPTIONS]

Detect stale translations and update them via opencode run.

Options:
  --lang <code>        Target language code (required, e.g. ja)
  --model <id>         Override the default model (e.g. translate/gpt-5.4-mini)
  --file <path>        Translate only this file (relative to modules/ROOT/)
  --dry-run            Show what would be translated without calling the API
  --clean-orphans      Remove translated files whose English source no longer exists
  --review-guide       Apply changed guide rules to existing translations
  --force              Force re-translation of all files, ignoring staleness status
  -h, --help           Show this help
EOF
  exit 0
}

# ── arg parsing ──────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang)        LANG="$2"; shift 2 ;;
    --model)       MODEL="$2"; shift 2 ;;
    --file)        SPECIFIC_FILE="$2"; shift 2 ;;
    --dry-run)     DRY_RUN=true; shift ;;
    --clean-orphans) CLEAN_ORPHANS=true; shift ;;
    --force)       FORCE=true; shift ;;
    --review-guide) REVIEW_GUIDE=true; shift ;;
    -h|--help)     usage ;;
    *)             echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$LANG" ]]; then
  echo "Error: --lang is required" >&2
  exit 1
fi

# ── dependency checks ────────────────────────────────────────────────────────

for cmd in jq yq git opencode; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is required but not found in PATH" >&2
    exit 1
  fi
done

# ── load config ──────────────────────────────────────────────────────────────

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: config not found at $CONFIG_FILE" >&2
  exit 1
fi

if ! yq -e ".target_languages.$LANG" "$CONFIG_FILE" &>/dev/null; then
  echo "Error: language '$LANG' not found in $CONFIG_FILE" >&2
  echo "Available languages: $(yq -r '.target_languages | keys | join(", ")' "$CONFIG_FILE")"
  exit 1
fi

LANG_NAME=$(yq -r ".target_languages.$LANG.name" "$CONFIG_FILE")
LANG_NATIVE=$(yq -r ".target_languages.$LANG.native_name" "$CONFIG_FILE")

# Load skip patterns into an array (bash 3.x compatible)
SKIP_PATTERNS=()
while IFS= read -r line; do
  SKIP_PATTERNS+=("$line")
done < <(yq -r '.skip_patterns[]' "$CONFIG_FILE")

# Load preserve terms as comma-separated string
PRESERVE_TERMS=$(yq -r '.preserve_terms | join(", ")' "$CONFIG_FILE")

LANG_ROOT="$REPO_ROOT/content/$LANG/modules/ROOT"
GUIDE_FILE="$REPO_ROOT/content/$LANG/translation-guide.yml"
GUIDE_HASH="none"
GUIDE_RULES=""
if [[ -f "$GUIDE_FILE" ]]; then
  yq '.' "$GUIDE_FILE" >/dev/null
  GUIDE_HASH=$(git hash-object "$GUIDE_FILE")
  GUIDE_RULES="Language-specific translation guide (content/$LANG/translation-guide.yml):
$(cat "$GUIDE_FILE")
Follow its rules, glossary, and applicable exceptions. Specific exceptions take precedence over general rules; language-specific terminology takes precedence over generic terminology advice. Preserve executable code, resource identifiers, and AsciiDoc structure. Open questions are informational, not new requirements."
fi

# Relative paths in prompts must resolve consistently, including when invoked elsewhere.
cd "$REPO_ROOT"

# ── init status file ─────────────────────────────────────────────────────────

# Use an isolated status copy during dry runs, including first-run bootstrapping.
if [[ "$DRY_RUN" == true ]]; then
  STATUS_SNAPSHOT=$(mktemp)
  if [[ -f "$STATUS_FILE" ]]; then
    cp "$STATUS_FILE" "$STATUS_SNAPSHOT"
  else
    echo '{}' > "$STATUS_SNAPSHOT"
  fi
  STATUS_FILE="$STATUS_SNAPSHOT"
  trap 'rm -f "$STATUS_SNAPSHOT" "$STATUS_SNAPSHOT.tmp"' EXIT
fi
if [[ ! -f "$STATUS_FILE" ]]; then
  echo '{}' > "$STATUS_FILE"
fi
if ! jq -e --arg lang "$LANG" '.[$lang]' "$STATUS_FILE" &>/dev/null; then
  jq --arg lang "$LANG" '.[$lang] = {}' "$STATUS_FILE" > "$STATUS_FILE.tmp"
  mv "$STATUS_FILE.tmp" "$STATUS_FILE"
fi

# ── helpers ──────────────────────────────────────────────────────────────────

should_skip() {
  local rel_path="$1"
  for pattern in "${SKIP_PATTERNS[@]}"; do
    # Convert glob to regex for matching
    local regex
    regex=$(echo "$pattern" | sed 's/\./\\./g; s/\*\*/DOUBLESTAR/g; s/\*/[^\/]*/g; s/DOUBLESTAR/.*/g')
    if [[ "$rel_path" =~ ^$regex$ ]]; then
      return 0
    fi
  done
  return 1
}

get_source_commit() {
  local file_path="$1"
  git -C "$REPO_ROOT" log -1 --format=%H -- "$file_path" 2>/dev/null || echo ""
}

get_stored_commit() {
  local rel_path="$1"
  jq -r --arg lang "$LANG" --arg path "$rel_path" \
    '.[$lang][$path].source_commit // ""' "$STATUS_FILE"
}

source_has_changed() {
  local source_path="$1"
  local stored_commit="$2"
  local previous_blob current_blob
  # Merges, cherry-picks, and reverts can change the last commit without changing
  # the source text. Compare content before scheduling a model call.
  previous_blob=$(git -C "$REPO_ROOT" rev-parse --verify "$stored_commit:$source_path" 2>/dev/null) || return 0
  current_blob=$(git -C "$REPO_ROOT" hash-object "$REPO_ROOT/$source_path")
  [[ "$previous_blob" != "$current_blob" ]]
}

update_status() {
  local rel_path="$1"
  local source_commit="$2"
  local model_used="$3"
  local guide_hash="${4-$GUIDE_HASH}"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  jq --arg lang "$LANG" \
     --arg path "$rel_path" \
     --arg commit "$source_commit" \
     --arg time "$now" \
     --arg model "$model_used" \
     --arg guide "$guide_hash" \
     '.[$lang][$path] = {source_commit: $commit, translated_at: $time, model: $model, guide_hash: $guide}' \
     "$STATUS_FILE" > "$STATUS_FILE.tmp"
  mv "$STATUS_FILE.tmp" "$STATUS_FILE"
}

files_are_identical() {
  local en_file="$1"
  local target_file="$2"
  [[ -f "$target_file" ]] && diff -q "$en_file" "$target_file" &>/dev/null
}

translation_rules() {
  cat <<RULES
- Preserve ALL AsciiDoc syntax exactly as-is: section headings (= == ===), include:: directives, xref: targets, image:: references, attribute references like {attribute_name}, [source,...] code blocks, block delimiters (---- **** ==== -- ++++), role annotations ([.tile], [#anchor-id], [%collapsible]), passthrough blocks, conditional directives (ifdef/ifndef/endif)
- For xref: links, translate ONLY the display text inside [...], not the file path or anchor
- For image:: references, translate ONLY the alt text inside [...], not the file path
- Do NOT translate content inside [source,...] code blocks
- Keep these terms in English (do not translate them): $PRESERVE_TERMS
- For UI labels that appear in English in the product (button names, menu items), keep the English term
- For technical terms that practitioners in the target language commonly use in English -- such as deploy, pipeline, container, namespace, cluster, workflow, merge request, rollout, commit, branch, pod, node, operator, registry -- keep the English term or use the appropriate target language term rather than translating it into a formal/literal equivalent that reads like a textbook
- IMPORTANT: Always keep a space before and after inline formatting marks (backticks, asterisks, underscores). AsciiDoc requires word boundaries around inline markup. For example: 'テキスト \`code\` テキスト' not 'テキスト\`code\`テキスト'
- Do not add any commentary, explanations, or markdown fences — just write the translated .adoc file
RULES
  if [[ -n "$GUIDE_RULES" ]]; then
    printf '\n%s\n' "$GUIDE_RULES"
  fi
}

guide_needs_review() {
  local stored
  stored=$(jq -r --arg lang "$LANG" --arg path "$1" \
    '.[$lang][$path].guide_hash // ""' "$STATUS_FILE")
  [[ "$stored" != "$GUIDE_HASH" && ( -n "$stored" || "$GUIDE_HASH" != "none" ) ]]
}

# ── build file manifest ──────────────────────────────────────────────────────

echo "==> Scanning for translatable files..."

declare -a TRANSLATABLE_FILES=()

while IFS= read -r -d '' file; do
  rel_path="${file#"$EN_ROOT/"}"

  if should_skip "$rel_path"; then
    continue
  fi

  if [[ -n "$SPECIFIC_FILE" && "$rel_path" != "$SPECIFIC_FILE" ]]; then
    continue
  fi

  TRANSLATABLE_FILES+=("$rel_path")
done < <(find "$EN_ROOT" -name '*.adoc' -type f -print0 | sort -z)

echo "    Found ${#TRANSLATABLE_FILES[@]} translatable files"

# ── classify files ───────────────────────────────────────────────────────────

declare -a NEW_FILES=()
declare -a STALE_FILES=()
declare -a CURRENT_FILES=()
declare -a GUIDE_REVIEW_FILES=()
declare -a GUIDE_UPDATE_FILES=()

for rel_path in "${TRANSLATABLE_FILES[@]}"; do
  en_file="$EN_ROOT/$rel_path"
  target_file="$LANG_ROOT/$rel_path"
  source_commit=$(get_source_commit "content/en/modules/ROOT/$rel_path")
  stored_commit=$(get_stored_commit "$rel_path")

  if [[ "$FORCE" == true ]]; then
    NEW_FILES+=("$rel_path")
  elif [[ ! -f "$target_file" || -z "$stored_commit" ]]; then
    # No status entry — check if the file is already translated
    if [[ -f "$target_file" && -z "$stored_commit" ]] && ! files_are_identical "$en_file" "$target_file"; then
      # Already translated, bootstrap the status entry
      echo "    Bootstrapping status for already-translated: $rel_path"
      update_status "$rel_path" "$source_commit" "manual" ""
      if [[ "$REVIEW_GUIDE" == true ]] && guide_needs_review "$rel_path"; then
        GUIDE_UPDATE_FILES+=("$rel_path")
      else
        CURRENT_FILES+=("$rel_path")
      fi
    else
      NEW_FILES+=("$rel_path")
    fi
  elif [[ "$stored_commit" != "$source_commit" ]] && source_has_changed "content/en/modules/ROOT/$rel_path" "$stored_commit"; then
    STALE_FILES+=("$rel_path")
  elif [[ "$REVIEW_GUIDE" == true ]] && guide_needs_review "$rel_path"; then
    GUIDE_UPDATE_FILES+=("$rel_path")
  else
    CURRENT_FILES+=("$rel_path")
  fi
  if [[ -f "$target_file" ]] && guide_needs_review "$rel_path"; then
    GUIDE_REVIEW_FILES+=("$rel_path")
  fi
done

# ── detect orphans ───────────────────────────────────────────────────────────

echo "==> Checking for orphaned translations..."

ORPHAN_COUNT=0
for rel_path in $(jq -r --arg lang "$LANG" '.[$lang] | keys[]' "$STATUS_FILE" 2>/dev/null); do
  en_file="$EN_ROOT/$rel_path"
  if [[ ! -f "$en_file" ]]; then
    ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
    target_file="$LANG_ROOT/$rel_path"
    echo "    ORPHAN: $rel_path (English source deleted)"
    if [[ "$CLEAN_ORPHANS" == true && "$DRY_RUN" == false ]]; then
      rm -f "$target_file"
      jq --arg lang "$LANG" --arg path "$rel_path" 'del(.[$lang][$path])' \
        "$STATUS_FILE" > "$STATUS_FILE.tmp"
      mv "$STATUS_FILE.tmp" "$STATUS_FILE"
      echo "      Removed orphaned translation and status entry"
    fi
  fi
done

if [[ $ORPHAN_COUNT -gt 0 && "$CLEAN_ORPHANS" == false ]]; then
  echo "    Use --clean-orphans to remove orphaned translations"
fi

# ── summary ──────────────────────────────────────────────────────────────────

echo ""
echo "==> Translation summary for '$LANG' ($LANG_NAME):"
echo "    New (untranslated): ${#NEW_FILES[@]}"
echo "    Stale (needs update): ${#STALE_FILES[@]}"
echo "    Current (source up to date): $((${#CURRENT_FILES[@]} + ${#GUIDE_UPDATE_FILES[@]}))"
echo "    Orphaned: $ORPHAN_COUNT"
echo "    Guide review needed: ${#GUIDE_REVIEW_FILES[@]}"
echo "    Guide-only updates selected: ${#GUIDE_UPDATE_FILES[@]}"
if [[ ${#GUIDE_REVIEW_FILES[@]} -gt 0 ]]; then
  for f in "${GUIDE_REVIEW_FILES[@]}"; do echo "    [GUIDE REVIEW] $f"; done
  if [[ "$REVIEW_GUIDE" == false ]]; then
    echo "    Guide-only changes are not applied automatically. Use --review-guide to apply them."
  fi
fi
echo ""

if [[ ${#NEW_FILES[@]} -eq 0 && ${#STALE_FILES[@]} -eq 0 && ${#GUIDE_UPDATE_FILES[@]} -eq 0 ]]; then
  echo "==> No source translations need updating (see any guide review flags above)."
  exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "==> Dry run — files that would be translated:"
  if [[ ${#NEW_FILES[@]} -gt 0 ]]; then
    for f in "${NEW_FILES[@]}"; do echo "    [NEW]   $f"; done
  fi
  if [[ ${#STALE_FILES[@]} -gt 0 ]]; then
    for f in "${STALE_FILES[@]}"; do echo "    [STALE] $f"; done
  fi
  if [[ ${#GUIDE_UPDATE_FILES[@]} -gt 0 ]]; then
    for f in "${GUIDE_UPDATE_FILES[@]}"; do echo "    [GUIDE UPDATE] $f"; done
  fi
  exit 0
fi

# ── determine model ──────────────────────────────────────────────────────────

if [[ -z "$MODEL" ]]; then
  MODEL=$(jq -r '.model // "translate/gpt-5.4-mini"' "$REPO_ROOT/opencode.json")
fi

echo "==> Using model: $MODEL"
echo ""

# ── translate new files ──────────────────────────────────────────────────────

for rel_path in "${NEW_FILES[@]+"${NEW_FILES[@]}"}"; do
  en_file="content/en/modules/ROOT/$rel_path"
  target_file="content/$LANG/modules/ROOT/$rel_path"
  source_commit=$(get_source_commit "$en_file")

  echo "--- Translating (new): $rel_path"

  mkdir -p "$(dirname "$REPO_ROOT/$target_file")"

  PROMPT="Read the file $en_file and translate all of its content to $LANG_NAME ($LANG_NATIVE).
Write the translated content to $target_file, creating the file if it does not exist.

Rules:
- Translate all prose text naturally and idiomatically
$(translation_rules)"

  if opencode run --model "$MODEL" "$PROMPT"; then
    update_status "$rel_path" "$source_commit" "$MODEL"
    echo "    Done: $rel_path"
  else
    echo "    ERROR: Translation failed for $rel_path" >&2
  fi

  echo ""
done

# ── translate stale files ────────────────────────────────────────────────────

for rel_path in "${STALE_FILES[@]+"${STALE_FILES[@]}"}" "${GUIDE_UPDATE_FILES[@]+"${GUIDE_UPDATE_FILES[@]}"}"; do
  en_file="content/en/modules/ROOT/$rel_path"
  target_file="content/$LANG/modules/ROOT/$rel_path"
  source_commit=$(get_source_commit "$en_file")
  stored_commit=$(get_stored_commit "$rel_path")

  echo "--- Updating translation: $rel_path"

  # Incremental source updates do not imply that the whole page follows a new guide.
  applied_guide_hash=$(jq -r --arg lang "$LANG" --arg path "$rel_path" \
    '.[$lang][$path].guide_hash // ""' "$STATUS_FILE")
  DIFF_FILE=""

  # Get the diff since last translation
  DIFF=$(git -C "$REPO_ROOT" diff "$stored_commit" HEAD -- "$en_file" 2>/dev/null || echo "")

  if [[ "$REVIEW_GUIDE" == true ]] && guide_needs_review "$rel_path"; then
    applied_guide_hash="$GUIDE_HASH"
    PROMPT="Read the English source $en_file and existing translation $target_file.
Review the entire existing translation against the current translation guide and English source.
Preserve human-reviewed wording wherever it already complies. Apply source changes and only the guide corrections needed; do not rewrite the whole page unnecessarily.
Write the updated translation to $target_file.
If no guide is present, use the generic rules below to review the existing translation.

Rules:
$(translation_rules)"
  elif [[ -z "$DIFF" ]]; then
    applied_guide_hash="$GUIDE_HASH"
    # Can't get diff (commit may have been rebased away), fall back to full translation
    echo "    Warning: could not compute diff, doing full translation"
    PROMPT="Read the file $en_file and translate all of its content to $LANG_NAME ($LANG_NATIVE).
Write the translated content to $target_file, replacing the existing file.

Rules:
- Translate all prose text naturally and idiomatically
$(translation_rules)"
  else
    # Write diff to a temp file so OpenCode can reference it
    DIFF_FILE=$(mktemp)
    echo "$DIFF" > "$DIFF_FILE"

    PROMPT="The English source file $en_file has been updated since the last translation.
The existing translation is at $target_file.

Read both files. Also read the diff at $DIFF_FILE which shows what changed in the English source.

Update the $LANG_NAME ($LANG_NATIVE) translation to reflect the English changes.
Write the updated translation to $target_file, replacing the existing file.

Rules:
- Only update the sections that correspond to changes in the diff — keep unchanged sections exactly as they are in the current translation
- Translate changed prose text naturally and idiomatically
$(translation_rules)"
  fi

  if opencode run --model "$MODEL" "$PROMPT"; then
    update_status "$rel_path" "$source_commit" "$MODEL" "$applied_guide_hash"
    echo "    Done: $rel_path"
  else
    echo "    ERROR: Translation failed for $rel_path" >&2
  fi

  # Clean up temp file if created
  [[ -n "${DIFF_FILE:-}" ]] && rm -f "$DIFF_FILE"

  echo ""
done

# ── sync non-translated files ────────────────────────────────────────────────

echo "==> Syncing technical files and images..."

# Sync technical skip-pattern files (partials and figures); shared prose is translated.
for pattern in "${SKIP_PATTERNS[@]}"; do
  while IFS= read -r -d '' file; do
    rel_path="${file#"$EN_ROOT/"}"
    target="$LANG_ROOT/$rel_path"
    mkdir -p "$(dirname "$target")"
    cp -f "$file" "$target"
  done < <(find "$EN_ROOT" -path "$EN_ROOT/$pattern" -type f -print0 2>/dev/null || true)
done

# Sync images (skip if already symlinked to en)
if [[ -L "$LANG_ROOT/assets/images" ]]; then
  echo "    Images symlinked to en — skipping sync"
elif [[ -d "$EN_ROOT/assets" ]]; then
  mkdir -p "$LANG_ROOT/assets"
  rsync -a --delete "$EN_ROOT/assets/" "$LANG_ROOT/assets/"
fi

echo "    Done"
echo ""
echo "==> Translation complete for '$LANG'."
