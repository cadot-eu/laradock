<?php

namespace CadotEu\Make;

use Symfony\Component\Config\Definition\Configurator\DefinitionConfigurator;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;
use Symfony\Component\HttpKernel\Bundle\AbstractBundle;

class MakeBundle extends AbstractBundle
{
    public function configure(DefinitionConfigurator $definition): void
    {
        // Exemple de configuration exposée à l'utilisateur du bundle,
        // à adapter/supprimer selon les besoins :
        //
        // $definition->rootNode()
        //     ->children()
        //         ->scalarNode('exemple')->defaultNull()->end()
        //     ->end();
    }

    public function loadExtension(array $config, ContainerConfigurator $configurator, ContainerBuilder $container): void
    {
        $configurator->import('../config/services.yaml');

        // Exemple d'injection d'un paramètre de config dans un service :
        // $configurator->services()
        //     ->get(MonService::class)
        //     ->arg(0, $config['exemple']);
    }
}
