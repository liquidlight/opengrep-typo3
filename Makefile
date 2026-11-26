IMAGE ?= opengrep-typo3:local
SITES ?= $(HOME)/Sites

# Linters run from pinned images, so nothing needs installing locally
DOCKER_RUN = docker run --rm -v "$(CURDIR)":/mnt -w /mnt
EDITORCONFIG = mstruebing/editorconfig-checker:4.0.2
SHELLCHECK = koalaman/shellcheck-alpine:v0.10.0
HADOLINT = hadolint/hadolint:v2.15.1-alpine
ACTIONLINT = rhysd/actionlint:1.7.12
RUFF = ghcr.io/astral-sh/ruff:0.17.3-alpine
PYTHON = python:3.13-alpine
YAMLLINT_VERSION = 1.38.0

.PHONY: lint lint-editorconfig lint-shell lint-docker lint-actions lint-yaml lint-python fix image test estate

# Runs every linter
lint: lint-editorconfig lint-shell lint-docker lint-actions lint-yaml lint-python

lint-editorconfig:
	$(DOCKER_RUN) $(EDITORCONFIG) editorconfig-checker

lint-shell:
	$(DOCKER_RUN) $(SHELLCHECK) shellcheck scripts/opengrep-typo3 scripts/estate.sh

lint-docker:
	$(DOCKER_RUN) $(HADOLINT) hadolint Dockerfile

lint-actions:
	$(DOCKER_RUN) $(ACTIONLINT) -color

lint-yaml:
	$(DOCKER_RUN) $(PYTHON) sh -c "pip install --quiet --root-user-action=ignore yamllint==$(YAMLLINT_VERSION) && yamllint --strict ."

lint-python:
	$(DOCKER_RUN) $(RUFF) ruff check --no-cache scripts
	$(DOCKER_RUN) $(RUFF) ruff format --no-cache --check scripts

# Fixes what the linters can fix themselves
fix:
	$(DOCKER_RUN) $(RUFF) ruff check --no-cache --fix scripts
	$(DOCKER_RUN) $(RUFF) ruff format --no-cache scripts

# Builds the image; fails if a rule is invalid or its tests fail
image:
	docker build -t $(IMAGE) .

# Builds and tests the rules only
test:
	docker build --target rules .

# Scans every site in $(SITES) with the image and summarises the findings in build/estate
estate: image
	scripts/estate.sh $(IMAGE) $(SITES) build/estate
