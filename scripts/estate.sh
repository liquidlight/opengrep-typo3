#!/bin/sh
# Scans every git checkout in a folder with the image and summarises the findings, to see what a rule
# change would flag across all sites before releasing it.
#
# Usage: scripts/estate.sh <image> <sites folder> <output folder>
#
# Scans each checkout as it is, so put every site on an up-to-date main first.
set -u

IMAGE=$1
SITES=$2
SCRIPTS=$(cd "$(dirname "$0")" && pwd)

# docker run needs an absolute path to mount
mkdir -p "$3"
OUT=$(cd "$3" && pwd)
printf 'site\tbranch\tlast_commit\tseconds\texit\n' > "$OUT/meta.tsv"

for dir in "$SITES"/*/; do
	site=$(basename "$dir")
	[ -d "$dir/.git" ] || continue

	branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
	last=$(git -C "$dir" log -1 --format=%cs)
	start=$(date +%s)
	docker run --rm -v "$dir":/src:ro -v "$OUT":/out "$IMAGE" \
		opengrep-typo3 scan --fail-on none --summary-only --output-dir "/out/$site" \
		> "$OUT/$site.log" 2>&1
	code=$?
	seconds=$(($(date +%s) - start))

	printf '%s\t%s\t%s\t%s\t%s\n' "$site" "$branch" "$last" "$seconds" "$code" >> "$OUT/meta.tsv"
	echo "$site: $(tail -1 "$OUT/$site.log") (${seconds}s)"
done

python3 "$SCRIPTS/collate.py" "$OUT"
