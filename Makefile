BOOTSTRAP_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := help
.PHONY: help make-kind make-gcp

help:
	@echo "Доступные команды:"
	@echo "  make make-kind  - Установить инструменты для локального Kind-окружения"
	@echo "  make make-gcp   - Установить GCP, GKE и Terraform-инструменты"

make-kind:
	@bash "$(BOOTSTRAP_DIR)kind/setup-kind.sh"

make-gcp:
	@bash "$(BOOTSTRAP_DIR)gcp/setup-gcp.sh"
