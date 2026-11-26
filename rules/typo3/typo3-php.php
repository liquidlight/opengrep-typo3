<?php

// ruleid: typo3-unserialize-without-allowed-classes
$data = unserialize($serialized);

// ok: typo3-unserialize-without-allowed-classes
$data = unserialize($serialized, ['allowed_classes' => false]);

class RawViewHelper extends AbstractViewHelper
{
	// ruleid: typo3-viewhelper-escape-output-disabled
	protected $escapeOutput = false;
}

class TypedRawViewHelper extends AbstractViewHelper
{
	// ruleid: typo3-viewhelper-escape-output-disabled
	protected bool $escapeOutput = false;
}

class EscapedViewHelper extends AbstractViewHelper
{
	// ok: typo3-viewhelper-escape-output-disabled
	protected $escapeOutput = true;
}

return [
	'SYS' => [
		// ruleid: typo3-insecure-system-setting
		'trustedHostsPattern' => '.*',
		// ruleid: typo3-insecure-system-setting
		'devIPmask' => '*',
		// ok: typo3-insecure-system-setting
		'trustedHostsPattern' => '(www\\.)?example\\.com',
	],
];

// ruleid: typo3-insecure-system-setting
$GLOBALS['TYPO3_CONF_VARS']['SYS']['devIPmask'] = '*';
