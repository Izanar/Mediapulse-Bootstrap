BOOTSTRAP_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := help
.PHONY: help kind gcp

help:
	@echo "Доступные команды:"
	@echo "  make kind  - Установить инструменты для локального Kind-окружения"
	@echo "  make gcp   - Установить GCP, GKE и Terraform-инструменты"

kind:
	@bash "$(BOOTSTRAP_DIR)kind/setup-kind.sh"

gcp:
	@bash "$(BOOTSTRAP_DIR)gcp/setup-gcp.sh"
