"""Builds the rules the image ships: the community rules chosen in community.yaml, plus the rules in rules/.

The local rules can use YAML anchors to share taint sources; opengrep doesn't support anchors, so they
are expanded here. With --fixtures, each rule file's test fixtures are copied next to it for
`opengrep scan --test`.
"""

import argparse
import pathlib
import subprocess
import sys
import tempfile

import yaml


class NoAliasDumper(yaml.SafeDumper):
	"""Writes anchored values out in full, as opengrep can't read YAML aliases."""

	def ignore_aliases(self, data):
		return True


def dump(data, path):
	path.parent.mkdir(parents=True, exist_ok=True)
	with path.open('w') as handle:
		yaml.dump(data, handle, Dumper=NoAliasDumper, sort_keys=False, width=200, allow_unicode=True)


def fetch(repository, commit, target):
	"""Shallow-fetches a single commit, so the community rules match the pinned version exactly."""
	git = ['git', '-C', str(target)]
	subprocess.run(['git', 'init', '--quiet', str(target)], check=True)
	subprocess.run([*git, 'fetch', '--quiet', '--depth=1', repository, commit], check=True)
	subprocess.run([*git, 'checkout', '--quiet', 'FETCH_HEAD'], check=True)


def build_community(config, source, out):
	disabled = set(config.get('disable', []))
	severity = config.get('severity', {})
	selected = set()

	for pattern in config['include']:
		matches = sorted(path.relative_to(source).as_posix() for path in source.glob(pattern))
		if not matches:
			sys.exit(f'community.yaml: "{pattern}" matches no rule files')
		selected.update(matches)

	# A disable or severity change for a file that's gone upstream would silently stop applying
	for path in sorted(disabled | set(severity)):
		if path not in selected:
			sys.exit(f'community.yaml: {path} is not in the included community rules')

	count = 0
	for path in sorted(selected - disabled):
		data = yaml.safe_load((source / path).read_text())
		if path in severity:
			for rule in data['rules']:
				rule['severity'] = severity[path]
		dump(data, out / 'community' / path)
		count += 1

	return count


def build_local(rules, out, fixtures):
	count = 0
	for path in sorted(rules.rglob('*.yaml')):
		relative = path.relative_to(rules)
		dump(yaml.safe_load(path.read_text()), out / relative)
		count += 1

		if fixtures:
			for fixture in path.parent.glob(path.stem + '.*'):
				if fixture.suffix != '.yaml':
					(out / relative.parent / fixture.name).write_bytes(fixture.read_bytes())

	return count


def main():
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument('--out', required=True, type=pathlib.Path, help='Folder to write the rules to')
	parser.add_argument('--config', default='community.yaml', type=pathlib.Path)
	parser.add_argument('--rules', default='rules', type=pathlib.Path, help='Folder of local rules')
	parser.add_argument(
		'--community',
		type=pathlib.Path,
		help='Existing checkout of the community rules (fetched when omitted)',
	)
	parser.add_argument('--fixtures', action='store_true', help='Copy test fixtures next to the local rules')
	args = parser.parse_args()

	config = yaml.safe_load(args.config.read_text())

	with tempfile.TemporaryDirectory() as temp:
		source = args.community
		if source is None:
			source = pathlib.Path(temp)
			fetch(config['repository'], config['commit'], source)
		community = build_community(config, source, args.out)

	local = build_local(args.rules, args.out, args.fixtures)
	print(f'Built {community} community and {local} local rule files in {args.out}')


if __name__ == '__main__':
	main()
