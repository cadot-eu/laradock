<?php

namespace CadotEu\Scrapper\Event;

use Symfony\Contracts\EventDispatcher\Event;

/**
 * Événement émis par ScrapperBundle.
 *
 * D'autres bundles/services de l'application peuvent s'y abonner
 * (via un EventSubscriber ou l'attribut #[AsEventListener]) pour
 * réagir ou récupérer les données transportées, sans dépendance directe
 * envers ScrapperBundle.
 */
class ScrapperExampleEvent extends Event
{
    public const NAME = 'scrapper.example';

    /**
     * @param array<string, mixed> $data
     */
    public function __construct(
        private readonly array $data,
    ) {
    }

    /**
     * @return array<string, mixed>
     */
    public function getData(): array
    {
        return $this->data;
    }
}
