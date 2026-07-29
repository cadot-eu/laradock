<?php

namespace CadotEu\Scrapper\Controller;

use CadotEu\Scrapper\Service\ScrapperNotifier;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class ExampleController extends AbstractController
{
    public function __construct(
        private readonly ScrapperNotifier $notifier,
    ) {
    }

    #[Route('/scrapper', name: 'scrapper_example')]
    public function __invoke(): Response
    {
        $this->notifier->notify(['message' => 'ScrapperBundle a quelque chose à partager']);

        return new Response('Bundle ScrapperBundle opérationnel ! Événement dispatché.');
    }
}
