# MakeBundle

maker de bundle

## Installation

En local, ajoute ceci au `composer.json` de ton application Symfony :

```json
"repositories": [
    { "type": "path", "url": "./bundles/Make" }
]
```

Puis :

```bash
composer require cadot.eu/make:@dev
```

Symfony Flex enregistre automatiquement le bundle dans `config/bundles.php`.

## Routing

Ajoute dans `config/routes.yaml` de ton application :

```yaml
make:
    resource: CadotEu\Make\Controller\ExampleController
    type: attribute
```

## Événements : s'abonner depuis un autre bundle/service

MakeBundle dispatche `CadotEu\Make\Event\MakeExampleEvent`
(nom : `make.example`) via le service `MakeNotifier`.

N'importe quel autre bundle ou service de l'application peut s'y abonner
sans dépendre directement de MakeBundle, par exemple avec l'attribut
`#[AsEventListener]` :

```php
use CadotEu\Make\Event\MakeExampleEvent;
use Symfony\Component\EventDispatcher\Attribute\AsEventListener;

class MonListener
{
    #[AsEventListener(event: MakeExampleEvent::class)]
    public function onExample(MakeExampleEvent $event): void
    {
        $data = $event->getData();
        // ... récupérer/traiter les infos ici
    }
}
```

Ou via un `EventSubscriberInterface` classique :

```php
use CadotEu\Make\Event\MakeExampleEvent;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class MonSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [MakeExampleEvent::NAME => 'onExample'];
    }

    public function onExample(MakeExampleEvent $event): void
    {
        $data = $event->getData();
        // ...
    }
}
```

Les deux sont autowired/autoconfigured automatiquement par Symfony, aucune
config manuelle de tag n'est nécessaire.
