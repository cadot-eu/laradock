<?php

namespace CadotEu\Make\Command;

use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'make:bundle',
    description: 'Créer ou supprimer un bundle',
)]
class MakeBundleCommand extends Command
{
    public function __construct()
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addArgument('nom', InputArgument::OPTIONAL, 'nom du bundle')
            ->addOption('rm', null, InputOption::VALUE_NONE, 'Supprimer un bundle')
        ;
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $nom = ucfirst($input->getArgument('nom'));
        if ($input->getOption('rm')) {
            if (!$nom) {
                $nom = $io->choice('Choisir le bundle à supprimer', $this->listeBundles());
            }
            $io->confirm('suppression du bundle ' . $nom, true);
            if (in_array($nom, $this->listeBundles()))
                throw new \RuntimeException("Le bundle n'a pas été effacé.");
            $io->success('Bundle supprimé');
            return Command::SUCCESS;
        }

        if (!$nom) {
            $nom = ucfirst($io->ask('Nom du bundle', null, $this->valider(...)));
        }


        $io->success('You have a new command! Now make it your own! Pass --help to see your options.');

        return Command::SUCCESS;
    }

    private function valider(?string $nom)
    {
        if (empty($nom)) throw new \RuntimeException('Le nom ne peut être vide');
        if (!preg_match('/^[A-Za-z0-9_]+$/', $nom)) throw new \RuntimeException('Lettre, nombre et underscore seulement');
        if (in_array(ucfirst(strtolower($nom)), $this->listeBundles())) throw new \RuntimeException('bundle déjà existant avec ce nom');
    }
    private function listeBundles(): array
    {
        return array_values(array_filter(array_diff(scandir('./bundles'), ['.', '..']), fn($item) => is_dir('./bundles/' . $item)));
    }
}
