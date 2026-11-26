# opengrep release, verified against the signature its release workflow publishes
ARG OPENGREP_VERSION=2.0.0

FROM alpine:3.24 AS opengrep
ARG OPENGREP_VERSION
ARG TARGETARCH
COPY --from=gcr.io/projectsigstore/cosign:v2.4.1 /ko-app/cosign /usr/local/bin/cosign
RUN apk add --no-cache curl \
	&& case "${TARGETARCH}" in \
		amd64) asset=opengrep_linux_x86 ;; \
		arm64) asset=opengrep_linux_aarch64 ;; \
		*) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
	esac \
	&& url="https://github.com/opengrep/opengrep/releases/download/v${OPENGREP_VERSION}/${asset}" \
	&& curl -fsSL -o /opengrep "${url}" \
	&& curl -fsSL -o /opengrep.cert "${url}.cert" \
	&& curl -fsSL -o /opengrep.sig "${url}.sig" \
	&& cosign verify-blob /opengrep \
		--certificate /opengrep.cert \
		--signature /opengrep.sig \
		--certificate-identity https://github.com/opengrep/opengrep/.github/workflows/rolling-release.yml@refs/heads/main \
		--certificate-oidc-issuer https://token.actions.githubusercontent.com \
	&& chmod +x /opengrep

# Builds the rules and fails the image if any rule is invalid or its tests fail
FROM python:3.15-alpine AS rules
RUN apk add --no-cache git && pip install --no-cache-dir pyyaml==6.0.3
COPY --from=opengrep /opengrep /usr/local/bin/opengrep
WORKDIR /build
COPY community.yaml ./
COPY scripts/build-rules.py scripts/
COPY rules rules
RUN python scripts/build-rules.py --out /rules --fixtures \
	&& opengrep scan --validate --config /rules /rules/typo3 \
	&& for pack in /rules/*/; do \
		[ "${pack}" = /rules/community/ ] || opengrep scan --test "${pack}" || exit 1; \
	done \
	&& find /rules -type f ! -name '*.yaml' -delete

FROM alpine:3.24
ARG OPENGREP_VERSION
LABEL org.opencontainers.image.title="opengrep-typo3" \
	org.opencontainers.image.description="opengrep with security rules for TYPO3 projects" \
	org.opencontainers.image.source="https://github.com/liquidlight/opengrep-typo3" \
	org.opencontainers.image.licenses="GPL-3.0-or-later" \
	io.github.opengrep.version="${OPENGREP_VERSION}"
# Projects are mounted or cloned with a different owner, which git otherwise refuses to read
RUN apk add --no-cache git jq \
	&& git config --system --add safe.directory '*'
COPY --from=opengrep /opengrep /usr/local/bin/opengrep
# Rule IDs, and the fingerprints GitLab uses to track findings, are built from this path: don't move it
COPY --from=rules /rules /rules
COPY scripts/opengrep-typo3 /usr/local/bin/opengrep-typo3
WORKDIR /src
CMD ["opengrep-typo3", "scan"]
