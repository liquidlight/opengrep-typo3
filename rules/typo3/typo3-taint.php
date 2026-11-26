<?php

class SearchController extends ActionController
{
	public function listAction(string $search, int $page = 1)
	{
		$queryBuilder = $this->getQueryBuilder();

		// ruleid: typo3-tainted-sql
		$queryBuilder->where('title LIKE "%' . $search . '%"');

		// ok: typo3-tainted-sql
		$queryBuilder->where($queryBuilder->expr()->like('title', $queryBuilder->createNamedParameter('%' . $search . '%')));

		// ok: typo3-tainted-sql
		$queryBuilder->where('uid = ' . (int)$search);

		// ok: typo3-tainted-sql
		$queryBuilder->where('page = ' . $page);

		$sort = $this->request->getQueryParams()['sort'];
		// ruleid: typo3-tainted-sql
		$queryBuilder->orderBy($sort);

		// ruleid: typo3-tainted-sql
		$queryBuilder->andWhere($queryBuilder->expr()->eq('uid', $GLOBALS['TYPO3_REQUEST']->getQueryParams()['course']));

		// ok: typo3-tainted-sql
		$this->itemRepository->add($search);

		// ok: typo3-tainted-redirect
		return $this->redirectToUri($this->uriBuilder->reset()->setArguments(['query' => $search])->build());
	}

	public function downloadAction()
	{
		$file = GeneralUtility::_GET('file');

		// ruleid: typo3-tainted-file-path
		readfile('/var/www/files/' . $file);

		// ok: typo3-tainted-file-path
		readfile('/var/www/files/' . basename($file));

		// ok: typo3-tainted-file-path
		fopen('/var/www/zips/' . md5($file) . '.zip', 'w');

		// ok: typo3-tainted-redirect
		header('Content-disposition: attachment; filename=' . $file);

		// ruleid: typo3-tainted-redirect
		header('Location: ' . $file);
	}

	public function returnAction(ServerRequestInterface $request)
	{
		// ruleid: typo3-tainted-redirect
		return new RedirectResponse($request->getQueryParams()['return']);
	}

	public function loginAction(ServerRequestInterface $request)
	{
		$returnUrl = $request->getQueryParams()['return'];

		// ok: typo3-tainted-redirect
		return new RedirectResponse('/login/?return_url=' . rawurlencode($returnUrl), 303);
	}

	public function showAction(ServerRequestInterface $request)
	{
		$query = $request->getParsedBody()['q'];

		// ruleid: typo3-tainted-html-response
		return new HtmlResponse('<p>' . $query . '</p>');
	}

	public function escapedAction(ServerRequestInterface $request)
	{
		$query = $request->getParsedBody()['q'];

		// ok: typo3-tainted-html-response
		return new HtmlResponse('<p>' . htmlspecialchars($query) . '</p>');
	}

	public function proxyAction(ServerRequestInterface $request)
	{
		$url = $request->getQueryParams()['url'];

		// ruleid: typo3-tainted-ssrf
		return GeneralUtility::getUrl($url);
	}

	public function convertAction(string $format)
	{
		// ruleid: typo3-tainted-exec
		CommandUtility::exec('convert in.pdf out.' . $format);

		// ok: typo3-tainted-exec
		CommandUtility::exec('convert in.pdf out.' . escapeshellarg($format));
	}
}

class ImportCommand extends Command
{
	protected function execute(InputInterface $input, OutputInterface $output): int
	{
		// ok: typo3-tainted-file-path
		$handle = fopen($input->getArgument('file'), 'r');

		return 0;
	}
}
