<?php

namespace CadotEu\Scrapper\Service;

use Symfony\Component\Panther\Client;
use SapiStudio\SeleniumStealth\SeleniumStealth;

class ScrapperBrowser
{
    public function __construct()
    {
        $client = Client::createChromeClient();
        $b = (new SeleniumStealth($client))->makeStealth();
    }
}
