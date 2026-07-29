<?php

namespace CadotEu\Scrapper\Service;

use CadotEu\Scrapper\Event\ScrapperExampleEvent;
use Symfony\Contracts\EventDispatcher\EventDispatcherInterface;

/**
 * Exemple de service qui notifie le reste de l'application (et donc
 * les autres bundles) en dispatchant un événement Symfony.
 *
 * Autowired automatiquement grâce à services.yaml : injecte-le simplement
 * dans n'importe quel service/contrôleur via ScrapperNotifier $notifier.
 */
class ScrapperNotifier
{
    public function __construct(
        private readonly EventDispatcherInterface $eventDispatcher,
    ) {}

    /**
     * @param array<string, mixed> $data
     */
    public function notify(array $data): void
    {
        $event = new ScrapperExampleEvent($data);
        $this->eventDispatcher->dispatch($event, ScrapperExampleEvent::NAME);
    }
}
