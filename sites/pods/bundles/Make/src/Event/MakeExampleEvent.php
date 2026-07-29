<?php

namespace CadotEu\Make\Event;

use Symfony\Contracts\EventDispatcher\Event;

/**
 * Événement émis par MakeBundle.
 *
 * D'autres bundles/services de l'application peuvent s'y abonner
 * (via un EventSubscriber ou l'attribut #[AsEventListener]) pour
 * réagir ou récupérer les données transportées, sans dépendance directe
 * envers MakeBundle.
 */
class MakeExampleEvent extends Event
{
    public const NAME = 'make.example';

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
