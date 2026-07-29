<?php

namespace CadotEu\Scrapper\Service;

use Symfony\Component\Panther\Client;
use SapiStudio\SeleniumStealth\SeleniumStealth;
use Facebook\WebDriver\Chrome\ChromeOptions;

class ScrapperBrowser
{
    private $b;
    public function __construct()
    {
        putenv('HOME=/tmp');

        $profileDir = '/tmp/chrome-profile-' . uniqid();
        mkdir($profileDir, 0777, true);

        $options = new ChromeOptions();
        $options->setBinary('/usr/bin/google-chrome-stable');

        $client = Client::createChromeClient(
            __DIR__ . '/../../drivers/chromedriver',
            [
                '--headless',
                '--no-sandbox',
                '--disable-gpu',
                '--disable-dev-shm-usage',
                '--user-data-dir=' . $profileDir,
            ],
            [
                'capabilities' => $options,
            ],
            9515
        );

        //$crawler = $client->request('GET', 'https://example.com');
        //$this->assertStringContainsString('Example', $crawler->filter('h1')->text());
        $this->b = (new SeleniumStealth($client))->makeStealth();
        $client->quit();
    }
}
