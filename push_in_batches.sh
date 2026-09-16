#!/bin/bash
# Commits and pushes files from a directory in size-limited batches,
# retrying each push a few times before giving up - built for a slow,
# variable connection where even a modest push can occasionally time out.
#
# Usage: ./push_in_batches.sh <directory> <max_MB_per_batch> <label>
# Example: ./push_in_batches.sh examples/caa/dat 10 "dat files"

set -e

dir="$1"
max_mb="$2"
label="$3"
max_bytes=$((max_mb * 1024 * 1024))
max_retries=3

if [ -z "$dir" ] || [ -z "$max_mb" ] || [ -z "$label" ]; then
  echo "Usage: $0 <directory> <max_MB_per_batch> <label>"
  exit 1
fi

# Critical: start from a genuinely clean, unstaged index. Without this,
# anything left staged from an earlier "git reset --soft" (or any other
# reason) silently rides along into this script's very first commit,
# regardless of how small a batch it thinks it's adding.
git reset >/dev/null

# Build batches (largest files first, so each big one gets its own batch).
# Only untracked files - a file already committed in an earlier run of
# this script would otherwise be picked up again, "git add" as a no-op,
# then "git commit" fails with "nothing to commit" since it genuinely
# didn't change - which, combined with `set -e` above, silently ended
# the whole script right there instead of moving on to the real work.
mapfile -t all_files < <(git ls-files --others --exclude-standard "$dir" | \
  while read -r f; do echo "$(stat -c%s "$f") $f"; done | sort -rn | awk '{print $2}')

if [ ${#all_files[@]} -eq 0 ]; then
  echo "No files found under $dir - nothing to do."
  exit 0
fi

batch=()
batch_size=0
batch_num=0

flush_batch() {
  if [ ${#batch[@]} -eq 0 ]; then
    return 0
  fi
  batch_num=$((batch_num + 1))
  echo ""
  echo "=== Batch $batch_num: ${#batch[@]} file(s), ~$((batch_size / 1024 / 1024)) MB ==="

  git add "${batch[@]}"
  git commit -m "Add caa dataset: $label, batch $batch_num"

  attempt=1
  while [ $attempt -le $max_retries ]; do
    echo "--- Push attempt $attempt/$max_retries for batch $batch_num ---"
    if git push; then
      echo "--- Batch $batch_num pushed successfully ---"
      return 0
    fi
    echo "--- Attempt $attempt failed, waiting 10s before retry ---"
    sleep 10
    attempt=$((attempt + 1))
  done

  echo ""
  echo "!!! Batch $batch_num failed after $max_retries attempts. !!!"
  echo "!!! The commit is safe locally - nothing lost. Re-run this"
  echo "!!! script once your connection is better; it will pick up"
  echo "!!! from the next un-added files automatically. !!!"
  exit 1
}

for f in "${all_files[@]}"; do
  size=$(stat -c%s "$f")
  if [ ${#batch[@]} -gt 0 ] && [ $((batch_size + size)) -gt $max_bytes ]; then
    flush_batch
    batch=()
    batch_size=0
  fi
  batch+=("$f")
  batch_size=$((batch_size + size))
done
flush_batch

echo ""
echo "=== All batches for '$label' pushed successfully ==="
