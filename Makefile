#  Copyright 2023 The Nephio Authors.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

.SHELLFLAGS = -ec

GO_VERSION ?= 1.20.2
IMG_REGISTRY ?= registry.nordix.org/nephio

# CONTAINER_RUNNABLE checks if tests and lint check can be run inside container.
ifeq ($(shell command -v podman > /dev/null 2>&1; echo $$?), 0)
CONTAINER_RUNTIME=podman
else
CONTAINER_RUNTIME=docker
endif
CONTAINER_RUNNABLE ?= $(shell command -v $(CONTAINER_RUNTIME) > /dev/null 2>&1; echo $$?)

export CONTAINER_RUNTIME CONTAINER_RUNNABLE

# find all subdirectories with a go.mod file in them
GO_MOD_DIRS = $(shell find . -name 'go.mod' -printf "'%h' ")
# find all subdirectories with a Dockerfile in them
DOCKERFILE_DIRS = $(shell find . -iname 'Dockerfile' -printf "'%h' " )

# This includes the 'help' target that prints out all targets with their descriptions organized by categories
include default-help.mk

##@ Go tests & formatting

.PHONY: unit lint gosec test unit-clean 
unit lint gosec test: ## These targets are delegated to the Makefiles of individual Go modules
	for dir in $(GO_MOD_DIRS); do \
		$(MAKE) -C "$$dir" $@ ; \
	done