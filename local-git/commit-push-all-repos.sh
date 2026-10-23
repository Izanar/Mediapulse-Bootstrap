#!/usr/bin/env bash
# Коммит и пуш изменений во всех 4 репозиториях MediaPulse.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${BASE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

REPOS=(
  "Mediapulse-App"
  "Mediapulse-Bootstrap"
  "Mediapulse-Gitops"
  "Mediapulse-Infra"
)

COMMIT_MESSAGE="${1:-chore: sync local changes $(date '+%Y-%m-%d %H:%M:%S')}"

echo "=========================================="
echo "📤 MediaPulse: коммит и пуш репозиториев"
echo "📁 Базовая директория: $BASE_DIR"
echo "💬 Сообщение коммита: $COMMIT_MESSAGE"
echo "=========================================="

failed=()
unchanged=()

for name in "${REPOS[@]}"; do
  dir="$BASE_DIR/$name"
  echo
  echo "---- $name ----"

  if [ ! -d "$dir/.git" ]; then
    echo "⚠️ Репозиторий не найден — пропускаем."
    continue
  fi

  (
    cd "$dir" || exit 1

    branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
    [ -z "$branch" ] && branch="main"
    echo "🌿 Ветка: $branch"

    git add -A

    if git diff --cached --quiet; then
      echo "ℹ️ Нет изменений для коммита — пропускаем."
      exit 0
    fi

    echo "📝 Коммит..."
    git commit -m "$COMMIT_MESSAGE" || exit 1

    echo "⬆️  Push origin/$branch..."
    git push -u origin "$branch" || exit 1

    echo "✅ Отправлено: $name"
  )

  rc=$?
  if [ $rc -ne 0 ]; then
    # rc=0 with no changes is handled as unchanged below; detect via status? 
    # We mark unchanged only if commit was skipped. Simpler: track separately inside? 
    echo "❌ Ошибка коммита/пуша: $name"
    failed+=("$name")
  fi
done

# Recompute unchanged count is not tracked precisely; keep simple summary
echo
echo "=========================================="
if [ ${#failed[@]} -eq 0 ]; then
  echo "🎉 Готово."
else
  echo "⚠️ Ошибки в репозиториях: ${failed[*]}"
  exit 1
fi
