<?php

namespace CadotEu\Scrapper\Tests;

use Symfony\Component\Panther\PantherTestCase;
use CadotEu\Scrapper\Service\ScrapperBrowser;

class BrowserTest extends PantherTestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->browserManager = new ScrapperBrowser();
    }
    public function testSomething(): void
    {
        $client = static::createPantherClient();
        $crawler = $client->request('GET', '/');

        $this->assertSelectorTextContains('h1', 'Hello World');
    }
}
