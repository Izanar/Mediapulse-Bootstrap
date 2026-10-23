.PHONY: help make-pull make-push

help: ## Показать доступные команды
	@echo "Доступные команды в mediapulse-bootstrap/local-git:"
	@echo "  make pull - Обновить (pull/clone) все 4 репозитория"
	@echo "  make push - Закоммитить и запушить изменения во всех 4 репозиториях"

pull: ## Актуализировать репозитории (update-all-repos.sh)
	@chmod +x ./update-all-repos.sh
	./update-all-repos.sh

push: ## Коммит и пуш репозиториев (commit-push-all-repos.sh)
	@chmod +x ./commit-push-all-repos.sh
	./commit-push-all-repos.sh
