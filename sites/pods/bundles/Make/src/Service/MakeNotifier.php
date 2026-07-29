<?php

namespace CadotEu\Make\Service;

use CadotEu\Make\Event\MakeExampleEvent;
use Symfony\Contracts\EventDispatcher\EventDispatcherInterface;

/**
 * Exemple de service qui notifie le reste de l'application (et donc
 * les autres bundles) en dispatchant un événement Symfony.
 *
 * Autowired automatiquement grâce à services.yaml : injecte-le simplement
 * dans n'importe quel service/contrôleur via MakeNotifier $notifier.
 */
class MakeNotifier
{
    public function __construct(
        private readonly EventDispatcherInterface $eventDispatcher,
    ) {
    }

    /**
     * @param array<string, mixed> $data
     */
    public function notify(array $data): void
    {
        $event = new MakeExampleEvent($data);
        $this->eventDispatcher->dispatch($event, MakeExampleEvent::NAME);
    }
}
