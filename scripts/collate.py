"""Summarises an estate scan (scripts/estate.sh) by rule and by site, and writes every finding to findings.csv."""

import collections
import csv
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
meta = {row['site']: row for row in csv.DictReader((out / 'meta.tsv').open(), delimiter='\t')}
severities = ['ERROR', 'WARNING', 'INFO']

rows = []
for site in meta:
	report = out / site / 'opengrep.json'
	if not report.exists():
		continue
	for result in json.loads(report.read_text())['results']:
		rows.append(
			{
				'site': site,
				'rule': result['check_id'].split('.')[-1],
				'severity': result['extra']['severity'],
				'path': result['path'],
				'line': result['start']['line'],
				'code': ' '.join(result['extra']['lines'].split())[:200],
			}
		)

with (out / 'findings.csv').open('w', newline='') as handle:
	writer = csv.DictWriter(handle, fieldnames=['site', 'rule', 'severity', 'path', 'line', 'code'])
	writer.writeheader()
	writer.writerows(rows)

print(f'\n{len(rows)} findings in {len({row["site"] for row in rows})} of {len(meta)} sites')

failed = [site for site, row in meta.items() if row['exit'] != '0']
if failed:
	print(f'Scan failed (see <site>.log): {", ".join(failed)}')

print('\nBy rule:')
by_rule = collections.defaultdict(list)
for row in rows:
	by_rule[(row['severity'], row['rule'])].append(row)
for (severity, rule), items in sorted(by_rule.items(), key=lambda item: (severities.index(item[0][0]), -len(item[1]))):
	print(f'  {severity:7} {rule:45} {len(items):4} in {len({item["site"] for item in items}):2} sites')

print('\nSites with ERROR findings (these would fail a merge request that adds them):')
errors = collections.defaultdict(list)
for row in rows:
	if row['severity'] == 'ERROR':
		errors[row['site']].append(f'{row["rule"]} {row["path"]}:{row["line"]}')
for site, items in sorted(errors.items()):
	print(f'  {site} ({meta[site]["branch"]})')
	for item in items:
		print(f'    {item}')
