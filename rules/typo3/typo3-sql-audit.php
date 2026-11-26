<?php

class ItemRepository extends Repository
{
	public function findBySearch(string $search, int $limit)
	{
		$queryBuilder = $this->connectionPool->getQueryBuilderForTable('tx_items');

		// ruleid: typo3-sql-string-concatenation
		$queryBuilder->where('title LIKE "%' . $search . '%"');

		// ruleid: typo3-sql-string-concatenation
		$queryBuilder->orderBy('sorting ' . $this->direction);

		// ok: typo3-sql-string-concatenation
		$queryBuilder->where('uid = ' . (int)$search);

		// ok: typo3-sql-string-concatenation
		$queryBuilder->where('title = ' . $queryBuilder->createNamedParameter($search));

		// ok: typo3-sql-string-concatenation
		$queryBuilder->orderBy('sorting ' . self::DIRECTION);

		return $queryBuilder->executeQuery();
	}
}
