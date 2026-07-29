# ScrapperBundle

scrapping par panther avec event

## Installation

En local, ajoute ceci au `composer.json` de ton application Symfony :

```json
"repositories": [
    { "type": "path", "url": "./bundles/Scrapper" }
]
```

Puis :

```bash
composer require cadot.eu/scrapper:@dev
```

Symfony Flex enregistre automatiquement le bundle dans `config/bundles.php`.

## Routing

Ajoute dans `config/routes.yaml` de ton application :

```yaml
scrapper:
    resource: CadotEu\Scrapper\Controller\ExampleController
    type: attribute
```

## Événements : s'abonner depuis un autre bundle/service

ScrapperBundle dispatche `CadotEu\Scrapper\Event\ScrapperExampleEvent`
(nom : `scrapper.example`) via le service `ScrapperNotifier`.

N'importe quel autre bundle ou service de l'application peut s'y abonner
sans dépendre directement de ScrapperBundle, par exemple avec l'attribut
`#[AsEventListener]` :

```php
use CadotEu\Scrapper\Event\ScrapperExampleEvent;
use Symfony\Component\EventDispatcher\Attribute\AsEventListener;

class MonListener
{
    #[AsEventListener(event: ScrapperExampleEvent::class)]
    public function onExample(ScrapperExampleEvent $event): void
    {
        $data = $event->getData();
        // ... récupérer/traiter les infos ici
    }
}
```

Ou via un `EventSubscriberInterface` classique :

```php
use CadotEu\Scrapper\Event\ScrapperExampleEvent;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class MonSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [ScrapperExampleEvent::NAME => 'onExample'];
    }

    public function onExample(ScrapperExampleEvent $event): void
    {
        $data = $event->getData();
        // ...
    }
}
```

Les deux sont autowired/autoconfigured automatiquement par Symfony, aucune
config manuelle de tag n'est nécessaire.
