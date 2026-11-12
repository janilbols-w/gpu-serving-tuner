#!/usr/bin/env bash
# 安装 gpu-serving-tuner 到项目级技能目录 <project>/.dsh/skills/
# 只复制技能本体（SKILL.md / references / scripts / templates / examples ...），不含 .git
set -euo pipefail
PROJECT="${1:-$PWD}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$PROJECT/.dsh/skills"
[ -f "$SRC/SKILL.md" ] || { echo "SKILL.md not found next to install.sh" >&2; exit 1; }
mkdir -p "$DEST"
if [ -d "$DEST/gpu-serving-tuner" ]; then chmod -R u+w "$DEST/gpu-serving-tuner" 2>/dev/null || true; rm -rf "$DEST/gpu-serving-tuner"; fi
mkdir -p "$DEST/gpu-serving-tuner"
tar -C "$SRC" --exclude='.git' -cf - . | tar -C "$DEST/gpu-serving-tuner" -xf -
echo "installed: $DEST/gpu-serving-tuner"
echo "next: bash $DEST/gpu-serving-tuner/scripts/init.sh $PROJECT   # 首次初始化 meta"
echo "then open a new session in $PROJECT to load the skill"
