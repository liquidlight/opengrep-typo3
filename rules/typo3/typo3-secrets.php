<?php

return [
	'EXTENSIONS' => [
		'recaptcha' => [
			// ruleid: typo3-recaptcha-secret-committed
			'private_key' => '6LcFAKExxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
			// ok: typo3-recaptcha-secret-committed
			'private_key' => '6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe',
			// ok: typo3-recaptcha-secret-committed
			'private_key' => getenv('RECAPTCHA_PRIVATE_KEY'),
		],
	],
	'SYS' => [
		// ruleid: typo3-encryption-key-committed
		'encryptionKey' => '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
		// ok: typo3-encryption-key-committed
		'encryptionKey' => getenv('TYPO3_ENCRYPTION_KEY'),
	],
];
