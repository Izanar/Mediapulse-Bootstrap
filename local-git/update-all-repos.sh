#!/usr/bin/env bash
# Обновление (pull/clone) 4 репозиториев MediaPulse.
# Конфликты при слиянии разрешаются в пользу удалённого (облачного) репозитория.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${BASE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

REPOS=(
  "Mediapulse-App|git@github.com:Izanar/Mediapulse-App.git"
  "Mediapulse-Bootstrap|git@github.com:Izanar/Mediapulse-Bootstrap.git"
  "Mediapulse-Gitops|git@github.com:Izanar/Mediapulse-Gitops.git"
  "Mediapulse-Infra|git@github.com:Izanar/Mediapulse-Infra.git"
)

echo "=========================================="
echo "🔄 MediaPulse: актуализация репозиториев"
echo "📁 Базовая директория: $BASE_DIR"
echo "=========================================="

failed=()

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name url <<< "$entry"
  dir="$BASE_DIR/$name"

  echo
  echo "---- $name ----"

  if [ ! -d "$dir/.git" ]; then
    echo "📦 Репозиторий не найден — клонируем из облака..."
    if git clone "$url" "$dir"; then
      echo "✅ Клонирован: $name"
    else
      echo "❌ Ошибка клонирования: $name"
      failed+=("$name")
    fi
    continue
  fi

  (
    cd "$dir" || exit 1

    branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
    [ -z "$branch" ] && branch="main"
    echo "🌿 Текущая ветка: $branch"

    echo "⬇️  Fetch origin..."
    git fetch origin --prune || exit 1

    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      echo "⚠️ Удалённая ветка origin/$branch не найдена — пропускаем."
      exit 0
    fi

    stashed=0
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
      echo "📦 Есть локальные изменения — сохраняем в stash..."
      if git stash push -u -m "auto-stash before update"; then
        stashed=1
      fi
    fi

    echo "🔀 Слияние origin/$branch (конфликты -> theirs/remote)..."
    if git merge --no-edit -X theirs "origin/$branch"; then
      echo "✅ Обновлено: $name"
    else
      echo "⚠️ Автоматическое слияние не завершилось — применяем версию из облака..."
      git diff --name-only --diff-filter=U 2>/dev/null | while IFS= read -r f; do
        [ -z "$f" ] && continue
        if git cat-file -e "origin/$branch:$f" 2>/dev/null; then
          git checkout --theirs -- "$f" 2>/dev/null || true
        else
          git rm -f -- "$f" 2>/dev/null || true
        fi
      done
      git add -A
      git commit -m "chore: merge origin/$branch (remote wins)" --no-verify 2>/dev/null || true
      echo "✅ Конфликты разрешены в пользу удалённого репозитория."
    fi

    if [ "$stashed" = "1" ]; then
      if git stash pop; then
        echo "📦 Локальные изменения восстановлены из stash."
      else
        echo "⚠️ Stash не применён автоматически (конфликт) — сохранён в списке stash."
      fi
    fi
  )

  rc=$?
  if [ $rc -ne 0 ]; then
    echo "❌ Ошибка обновления: $name"
    failed+=("$name")
  fi
done

echo
echo "=========================================="
if [ ${#failed[@]} -eq 0 ]; then
  echo "🎉 Все репозитории актуализированы."
else
  echo "⚠️ Ошибки в репозиториях: ${failed[*]}"
  exit 1
fi
