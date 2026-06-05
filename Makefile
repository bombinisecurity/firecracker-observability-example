# Firecracker Minimal Kernel Builder
# Simple Makefile interface for Docker-based kernel builds

KERNEL_VERSION ?= 6.8.12
OUTPUT_DIR ?= ./kernel-output
IMAGE_NAME = firecracker-kernel-builder

.PHONY: help build clean rebuild shell

help:
	@echo "Firecracker Minimal Kernel Builder"
	@echo ""
	@echo "Usage:"
	@echo "  make build          - Build the kernel (default: $(KERNEL_VERSION))"
	@echo "  make rebuild        - Clean and rebuild"
	@echo "  make clean          - Remove output directory"
	@echo "  make shell          - Open shell in build container"
	@echo ""
	@echo "Options:"
	@echo "  KERNEL_VERSION=X.X.X  - Specify kernel version (default: $(KERNEL_VERSION))"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make build KERNEL_VERSION=6.1.0"
	@echo "  make rebuild"

build: check-config
	@echo "Building kernel $(KERNEL_VERSION)..."
	@mkdir -p $(OUTPUT_DIR)
	docker build \
		--build-arg KERNEL_VERSION=$(KERNEL_VERSION) \
		-t $(IMAGE_NAME):$(KERNEL_VERSION) \
		-t $(IMAGE_NAME):latest \
		.
	docker run --rm \
		-v $$(pwd)/$(OUTPUT_DIR):/output-mount \
		$(IMAGE_NAME):$(KERNEL_VERSION)
	@echo ""
	@echo "=== Build Complete ==="
	@ls -lh $(OUTPUT_DIR)/
	@echo ""
	@echo "Kernel: $(OUTPUT_DIR)/vmlinux-$(KERNEL_VERSION)-firecracker-minimal"

rebuild: clean build

clean:
	@echo "Cleaning output directory..."
	rm -rf $(OUTPUT_DIR)

check-config:
	@if [ ! -f firecracker-minimal.config ]; then \
		echo "Error: firecracker-minimal.config not found!"; \
		exit 1; \
	fi

shell:
	@echo "Opening shell in build container..."
	docker run --rm -it \
		-v $$(pwd)/firecracker-minimal.config:/build/linux-$(KERNEL_VERSION)/.config \
		$(IMAGE_NAME):latest \
		/bin/bash

.DEFAULT_GOAL := build
