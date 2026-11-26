# opengrep for TYPO3

[opengrep](https://github.com/opengrep/opengrep) Docker image with security rules for TYPO3 projects: the community rules for PHP, JavaScript, TypeScript and secrets, plus rules for TYPO3's APIs, TypoScript and Fluid templates.

Images are published to the GitHub Container Registry for `linux/amd64` and `linux/arm64`.

## Tags

| Tag | Built from |
| --- | --- |
| `1.2.3`, `1.2`, `1` | Release tags (`v1.2.3`) |
| `main` | The `main` branch, for trying out changes before a release |

## Usage

### GitLab CI

```yaml
sast:opengrep:
  image: ghcr.io/liquidlight/opengrep-typo3:1
  script:
    - opengrep-typo3 ci
  artifacts:
    when: always
    reports:
      codequality: gl-code-quality-opengrep.json
```

`opengrep-typo3 ci` behaves differently depending on the pipeline:

- **Merge requests** fail when the merge request adds an `ERROR` finding. Findings that are already on the target branch don't count. It fetches the history back to the merge base itself, so `GIT_DEPTH: 1` is fine. It then scans the whole project for the Code Quality report, so the merge request widget can show new and fixed findings.
- **Other pipelines** (the default branch) only write the report and never fail on findings.

| Variable | Default | Purpose |
| --- | --- | --- |
| `OPENGREP_JOBS` | `4` | Files scanned in parallel |
| `OPENGREP_DEEPEN_BY` / `OPENGREP_DEEPEN_ATTEMPTS` | `50` / `10` | How far back to look for a merge request's merge base. If it isn't found, the job only reports |
| `OPENGREP_EXTRA_FLAGS` | | Extra `opengrep scan` options, e.g. `--exclude=some/path` |

### Locally

From a project's root:

```bash
docker run --rm -v "$PWD":/src ghcr.io/liquidlight/opengrep-typo3:1
```

This prints the findings, writes `opengrep.json` and `gl-code-quality-opengrep.json`, and exits 1 when there are `ERROR` findings. Run `opengrep-typo3 scan --help` for the options.

## What fails the job

| Severity | Merge request |
| --- | --- |
| `ERROR` | Fails when the merge request adds it |
| `WARNING` | Reported |
| `INFO` | Reported |

## Ignoring findings

- **A wrong finding:** add a comment with the rule ID and the reason, on the line above or at the end of the line. This works in PHP, JavaScript, TypoScript and Fluid (`<!-- nosemgrep: ... -->`):

  ```php
  // nosemgrep: typo3-tainted-file-path - realpath() above keeps the file inside the uploads folder
  $handle = fopen($file, 'rb');
  ```

- **Vendored code** the default excludes miss: add the paths to a `.semgrepignore` file in the project root, which uses `.gitignore` syntax. It adds to the excludes below rather than replacing them.

The default excludes are minified files, `lib/`, `libs/` and `vendor/` folders, `node_modules`, `.ddev`, `Tests/`, `*.spec.ts`, `*.test.ts` and lock files. Only files tracked by git are scanned.

## Rules

### TYPO3

| Rule | Severity | Finds |
| --- | --- | --- |
| `typo3-tainted-sql` | ERROR | Request data in QueryBuilder or Connection SQL without `createNamedParameter()` |
| `typo3-tainted-file-path` | ERROR | Request data used as a file path |
| `typo3-tainted-exec` | ERROR | Request data in a shell command |
| `typo3-tainted-html-response` | ERROR | Request data written to an HTML response without escaping |
| `typo3-recaptcha-secret-committed` | ERROR | A committed reCAPTCHA secret key (Google's test key is allowed) |
| `typo3-tainted-redirect` | WARNING | Request data deciding a redirect target |
| `typo3-tainted-ssrf` | WARNING | Request data deciding which URL the server fetches |
| `typo3-sql-string-concatenation` | WARNING | A variable concatenated into SQL. The taint rules can't follow data from one file to another, e.g. from a controller into a repository |
| `typo3-unserialize-without-allowed-classes` | WARNING | `unserialize()` without `allowed_classes` |
| `typo3-insecure-system-setting` | WARNING | `trustedHostsPattern` of `.*` or `devIPmask` of `*` |
| `typo3-html-sanitizer-disabled` | WARNING | `htmlSanitize = 0` in TypoScript |
| `typo3-rte-allows-dangerous-tags` | WARNING | RTE or parseFunc allowing `script`, `iframe`, `object` or `embed` |
| `typo3-viewhelper-escape-output-disabled` | INFO | ViewHelpers with `$escapeOutput = false` |
| `typo3-encryption-key-committed` | INFO | A committed TYPO3 `encryptionKey` |

The taint rules treat these as request data: `$_GET`, `$_POST`, `$_REQUEST` and `$_COOKIE`; `GeneralUtility::_GP()` and its variants; PSR-7 query, body, cookie and upload data and headers; Extbase `getArgument(s)()`; and the arguments of Extbase `*Action()` methods, except `int`, `float` and `bool` ones.

### Fluid

| Rule | Finds |
| --- | --- |
| `typo3-fluid-raw-in-attribute` | `f:format.raw()` inside an HTML attribute |
| `typo3-fluid-variable-in-event-handler` | A variable inside an `on*` attribute, where Fluid's escaping doesn't protect it |
| `typo3-fluid-raw-inside-script` | `f:format.raw` in a `<script>` block, except after `f:format.json()` |
| `typo3-fluid-htmlentities-decode` | `f:format.htmlentitiesDecode`, which turns escaped text back into HTML |
| `typo3-fluid-raw-on-plain-text-field` | `f:format.raw` on header, title, name, label or alt fields |
| `typo3-fluid-debug-output` | `<f:debug>` left in a template |

All Fluid rules are `WARNING`. ke_search's `searchword` and `resultrow.title` are allowed raw, as ke_search escapes them itself.

### Community

The PHP, JavaScript, TypeScript and secrets rules from [opengrep-rules](https://github.com/opengrep/opengrep-rules), at the commit pinned in [`community.yaml`](community.yaml). That file also lists the rules left out and the severities changed, with the reason for each.

## Development

```bash
make lint     # Run every linter (editorconfig, shellcheck, hadolint, actionlint, yamllint, ruff)
make fix      # Fix the Python formatting and lint issues ruff can fix
make test     # Build the rules and run their tests
make image    # Build the image as opengrep-typo3:local
make estate   # Scan every site in ~/Sites with the image (SITES=... to change)
```

- **Rules** live in `rules/typo3/` and `rules/fluid/`. Each `<name>.yaml` has test fixtures next to it with the same name (`<name>.php`, `<name>.html`, `<name>.typoscript`), marked with `ruleid: <id>` and `ok: <id>` comments. The image build fails if a rule is invalid or a fixture doesn't match.
- **YAML anchors** can be used to share taint sources between rules. `scripts/build-rules.py` expands them, as opengrep can't read them.
- **Rule IDs** come from the folder the rules are in inside the image (`/rules`), e.g. `rules.typo3.typo3-tainted-sql`. GitLab tracks Code Quality findings by fingerprint, so keep the folder and the rule IDs stable.
- **Before releasing a rule change,** run `make estate` with every site on an up-to-date `main`. It shows what the change would flag across all sites.

### Updating opengrep and the community rules

Dependabot keeps the GitHub Actions (pinned to commits) and the Dockerfile's base images up to date. opengrep and the community rules are updated by hand, so their release notes get read:

- **opengrep:** change `OPENGREP_VERSION` in the `Dockerfile`. The build checks the binary's signature from opengrep's release workflow.
- **Community rules:** change `commit` in `community.yaml`. The build fails if a disabled rule, or one whose severity is changed, no longer exists.

Then run `make estate`, and release with a new tag:

```bash
git tag v1.1.0 && git push origin v1.1.0
```

The first push creates the package on ghcr as private. Make it public in the package settings, or GitLab runners can't pull it.

## Licence

Licensed under the [GNU General Public License v3.0](LICENSE) or later.

The image also contains:
- the [opengrep](https://github.com/opengrep/opengrep) binary (LGPL-2.1)
- the community rules from [opengrep-rules](https://github.com/opengrep/opengrep-rules) (LGPL-2.1 with the Commons Clause, which doesn't allow selling them)

Neither is stored in this repository.
