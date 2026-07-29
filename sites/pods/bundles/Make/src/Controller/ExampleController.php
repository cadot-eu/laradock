<?php

namespace CadotEu\Make\Controller;

use CadotEu\Make\Service\MakeNotifier;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class ExampleController extends AbstractController
{
    public function __construct(
        private readonly MakeNotifier $notifier,
    ) {}

    #[Route('/make', name: 'make_example')]
    public function __invoke(): Response
    {
        $this->notifier->notify(['message' => 'MakeBundle a quelque chose à partager']);

        return new Response('Bundle MakeBundle opérationnel ! Événement dispatché.');
    }
}
