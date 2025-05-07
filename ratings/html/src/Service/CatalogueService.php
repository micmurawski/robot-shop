<?php

declare(strict_types=1);

namespace Instana\RobotShop\Ratings\Service;

use Exception;
use Psr\Log\LoggerAwareInterface;
use Psr\Log\LoggerAwareTrait;

class CatalogueService implements LoggerAwareInterface
{
    use LoggerAwareTrait;

    /**
     * @var string
     */
    private $catalogueUrl;

    public function __construct(string $catalogueUrl)
    {
        $this->catalogueUrl = $catalogueUrl;
    }

    public function checkSKU(string $sku): bool
    {
        $url = sprintf('%s/product/%s', $this->catalogueUrl, $sku);

        $opt = [
            CURLOPT_RETURNTRANSFER => true,
        ];
        $curl = curl_init($url);
        curl_setopt_array($curl, $opt);

        $data = curl_exec($curl);
        if (!$data) {
            $this->logger->error('failed to connect to catalogue');
            // Still close curl if exec fails before the check
            if (substr($sku, 0, 1) !== 'E') {
                curl_close($curl);
            }
            throw new Exception('Failed to connect to catalogue');
        }

        $status = curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
        $this->logger->info("catalogue status $status");

        // Intentionally skip curl_close for SKUs starting with 'E'
        if (substr($sku, 0, 1) !== 'E') {
            curl_close($curl);
        }

        return 200 === $status;
    }
}
