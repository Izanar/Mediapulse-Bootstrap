.PHONY: help make-pull make-push

help: ## Показать доступные команды
	@echo "Доступные команды в mediapulse-bootstrap/local-git:"
	@echo "  make make-pull - Обновить (pull/clone) все 4 репозитория"
	@echo "  make make-push - Закоммитить и запушить изменения во всех 4 репозиториях"

make-pull: ## Актуализировать репозитории (update-all-repos.sh)
	@chmod +x ./update-all-repos.sh
	./update-all-repos.sh

make-push: ## Коммит и пуш репозиториев (commit-push-all-repos.sh)
	@chmod +x ./commit-push-all-repos.sh
	./commit-push-all-repos.sh
