#!/usr/bin/env bash
#
# create-symfony-bundle.sh
# Génère ou supprime un bundle Symfony autonome (style CodeLab / AbstractBundle).
# Prévu pour être lancé depuis la racine de ton projet Symfony.
#
# Usage : ./create-symfony-bundle.sh
#

set -euo pipefail

echo "=== Gestionnaire de bundles Symfony ==="
echo
echo "1) Créer un nouveau bundle"
echo "2) Supprimer un bundle existant"
read -rp "Choix [1] : " MODE
MODE="${MODE:-1}"
echo

# ============================================================================
# MODE 2 : SUPPRESSION D'UN BUNDLE
# ============================================================================
if [[ "$MODE" == "2" ]]; then

    TARGET_DIR_DEL="./bundles"
    read -rp "Dossier contenant les bundles [${TARGET_DIR_DEL}] : " INPUT_DIR
    TARGET_DIR_DEL="${INPUT_DIR:-$TARGET_DIR_DEL}"

    if [[ -d "$TARGET_DIR_DEL" ]]; then
        echo "Bundles trouvés dans $TARGET_DIR_DEL :"
        find "$TARGET_DIR_DEL" -mindepth 1 -maxdepth 1 -type d -printf "  - %f\n" 2>/dev/null || true
        echo
    fi

    read -rp "Nom du dossier du bundle à supprimer (ex: MyakuHealthCheck) : " DEL_NAME
    if [[ -z "$DEL_NAME" ]]; then
        echo "Erreur : nom obligatoire." >&2
        exit 1
    fi

    BUNDLE_ROOT="${TARGET_DIR_DEL}/${DEL_NAME}"

    if [[ ! -d "$BUNDLE_ROOT" ]]; then
        echo "Erreur : $BUNDLE_ROOT introuvable." >&2
        exit 1
    fi

    PACKAGE_NAME=""
    if [[ -f "$BUNDLE_ROOT/composer.json" ]] && command -v python3 >/dev/null 2>&1; then
        PACKAGE_NAME=$(python3 -c "import json;print(json.load(open('${BUNDLE_ROOT}/composer.json')).get('name',''))" 2>/dev/null || true)
    fi

    echo
    echo "Récapitulatif de la suppression :"
    echo "  Dossier  : $BUNDLE_ROOT"
    echo "  Package  : ${PACKAGE_NAME:-inconnu}"
    echo

    read -rp "Confirmer la suppression DÉFINITIVE ? [y/N] " CONFIRM_DEL
    if [[ ! "$CONFIRM_DEL" =~ ^[Yy]$ ]]; then
        echo "Annulé."
        exit 0
    fi

    # Nettoyage du composer.json de l'appli (repository path + require)
    APP_COMPOSER="./composer.json"
    if [[ -f "$APP_COMPOSER" && -n "$PACKAGE_NAME" ]]; then
        if ! command -v python3 >/dev/null 2>&1; then
            echo "⚠️  python3 introuvable : nettoie manuellement le composer.json de l'appli." >&2
        else
            BUNDLE_ABS=$(realpath "$BUNDLE_ROOT")
            cp "$APP_COMPOSER" "${APP_COMPOSER}.bak"

            RESULT=$(python3 - "$APP_COMPOSER" "$BUNDLE_ABS" "$PACKAGE_NAME" <<'PYEOF'
import json, os, sys

app_composer_path, bundle_abs, package_name = sys.argv[1:4]
app_dir = os.path.dirname(os.path.abspath(app_composer_path))

with open(app_composer_path, "r", encoding="utf-8") as f:
    data = json.load(f)

def points_to_bundle(repo):
    if repo.get("type") != "path":
        return False
    candidate = os.path.normpath(os.path.join(app_dir, repo.get("url", "")))
    return candidate == bundle_abs

repos = data.get("repositories", [])
new_repos = [r for r in repos if not points_to_bundle(r)]
repo_removed = len(new_repos) != len(repos)
if new_repos:
    data["repositories"] = new_repos
elif "repositories" in data:
    del data["repositories"]

require_removed = False
if "require" in data and package_name in data["require"]:
    del data["require"][package_name]
    require_removed = True

with open(app_composer_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
    f.write("\n")

print(f"repo_removed={int(repo_removed)}")
print(f"require_removed={int(require_removed)}")
PYEOF
)
            echo "$RESULT"
            echo "✅ composer.json de l'appli nettoyé (backup : ${APP_COMPOSER}.bak)"
        fi
    fi

    rm -rf "$BUNDLE_ROOT"
    echo "✅ Dossier supprimé : $BUNDLE_ROOT"
    echo

    if [[ -f "$APP_COMPOSER" ]]; then
        read -rp "Lancer 'composer update' maintenant pour nettoyer vendor/ ? [y/N] " RUN_COMPOSER
        if [[ "$RUN_COMPOSER" =~ ^[Yy]$ ]]; then
            if command -v composer >/dev/null 2>&1; then
                composer update
            else
                echo "⚠️  composer introuvable dans le PATH, commande non exécutée." >&2
            fi
        fi
    fi

    echo "Terminé."
    exit 0
fi

# ============================================================================
# MODE 1 : CRÉATION D'UN BUNDLE
# ============================================================================

# --- 1. Questions ---------------------------------------------------------

read -rp "Nom du vendor [cadot.eu]                    : " VENDOR
VENDOR="${VENDOR:-cadot.eu}"
read -rp "Nom du bundle, sans 'Bundle' (ex: MyakuHealthCheck) : " BUNDLE_NAME
read -rp "Description courte                        : " DESCRIPTION
read -rp "Nom de l'auteur [cadot.eu]                  : " AUTHOR
AUTHOR="${AUTHOR:-cadot.eu}"
read -rp "Dossier de destination [./bundles]         : " TARGET_DIR
TARGET_DIR="${TARGET_DIR:-./bundles}"

if [[ -z "$VENDOR" || -z "$BUNDLE_NAME" ]]; then
    echo "Erreur : vendor et nom du bundle sont obligatoires." >&2
    exit 1
fi

# --- 2. Normalisation des noms --------------------------------------------

# vendor en minuscule-kebab pour composer.json (ex: devexploris)
VENDOR_SLUG=$(echo "$VENDOR" | tr '[:upper:]' '[:lower:]' | tr ' _' '--')

# BUNDLE_NAME en PascalCase (au cas où l'utilisateur tape en minuscule/espaces)
PASCAL_NAME=$(echo "$BUNDLE_NAME" | sed -E 's/[-_ ]+/ /g' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}}1' | tr -d ' ')

# Nom de classe final : PascalName + Bundle
CLASS_NAME="${PASCAL_NAME}Bundle"

# Slug kebab-case pour le nom composer (ex: myaku-health-check)
KEBAB_NAME=$(echo "$PASCAL_NAME" | sed -E 's/([a-z0-9])([A-Z])/\1-\2/g' | tr '[:upper:]' '[:lower:]')

# Namespace PHP : Vendor\PascalName (le vendor est capitalisé, sans points/tirets pour rester un identifiant PHP valide)
VENDOR_NS=$(echo "$VENDOR" | sed -E 's/[-_. ]+/ /g' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}}1' | tr -d ' ')
NAMESPACE="${VENDOR_NS}\\\\${PASCAL_NAME}"
NAMESPACE_TESTS="${VENDOR_NS}\\\\${PASCAL_NAME}\\\\Tests"

PACKAGE_NAME="${VENDOR_SLUG}/${KEBAB_NAME}"
BUNDLE_ROOT="${TARGET_DIR}/${PASCAL_NAME}"

# Nom d'événement style "mon_bundle.example"
EVENT_SNAKE_NAME="${KEBAB_NAME//-/_}"
EVENT_CLASS_NAME="${PASCAL_NAME}ExampleEvent"
NOTIFIER_CLASS_NAME="${PASCAL_NAME}Notifier"

echo
echo "Récapitulatif :"
echo "  Package composer : $PACKAGE_NAME"
echo "  Classe du bundle : $CLASS_NAME"
echo "  Namespace        : ${VENDOR_NS}\\${PASCAL_NAME}"
echo "  Dossier créé      : $BUNDLE_ROOT"
echo

if [[ -e "$BUNDLE_ROOT" ]]; then
    echo "Erreur : le dossier $BUNDLE_ROOT existe déjà." >&2
    exit 1
fi

# --- 3. Arborescence -------------------------------------------------------

mkdir -p "$BUNDLE_ROOT"/{src/Controller,src/Service,src/Event,config,tests}

# --- 4. composer.json -------------------------------------------------------

cat > "$BUNDLE_ROOT/composer.json" <<EOF
{
    "name": "${PACKAGE_NAME}",
    "description": "${DESCRIPTION}",
    "type": "symfony-bundle",
    "license": "MIT",
    "minimum-stability": "stable",
    "authors": [
        { "name": "${AUTHOR}" }
    ],
    "require": {
        "php": ">=8.2",
        "symfony/http-kernel": "^6.4|^7.0|^8.0",
        "symfony/http-foundation": "^6.4|^7.0|^8.0",
        "symfony/routing": "^6.4|^7.0|^8.0",
        "symfony/dependency-injection": "^6.4|^7.0|^8.0",
        "symfony/config": "^6.4|^7.0|^8.0",
        "symfony/event-dispatcher": "^6.4|^7.0|^8.0",
        "symfony/event-dispatcher-contracts": "^2.5|^3.0"
    },
    "autoload": {
        "psr-4": { "${NAMESPACE}\\\\": "src/" }
    },
    "autoload-dev": {
        "psr-4": { "${NAMESPACE_TESTS}\\\\": "tests/" }
    },
    "keywords": ["symfony", "bundle"]
}
EOF

# --- 5. Classe principale du bundle (AbstractBundle) ------------------------

cat > "$BUNDLE_ROOT/src/${CLASS_NAME}.php" <<EOF
<?php

namespace ${VENDOR_NS}\\${PASCAL_NAME};

use Symfony\Component\Config\Definition\Configurator\DefinitionConfigurator;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;
use Symfony\Component\HttpKernel\Bundle\AbstractBundle;

class ${CLASS_NAME} extends AbstractBundle
{
    public function configure(DefinitionConfigurator \$definition): void
    {
        // Exemple de configuration exposée à l'utilisateur du bundle,
        // à adapter/supprimer selon les besoins :
        //
        // \$definition->rootNode()
        //     ->children()
        //         ->scalarNode('exemple')->defaultNull()->end()
        //     ->end();
    }

    public function loadExtension(array \$config, ContainerConfigurator \$configurator, ContainerBuilder \$container): void
    {
        \$configurator->import('../config/services.yaml');

        // Exemple d'injection d'un paramètre de config dans un service :
        // \$configurator->services()
        //     ->get(MonService::class)
        //     ->arg(0, \$config['exemple']);
    }
}
EOF

# --- 6. config/services.yaml ------------------------------------------------

cat > "$BUNDLE_ROOT/config/services.yaml" <<EOF
services:
    ${VENDOR_NS}\\${PASCAL_NAME}\\:
        resource: '../src/*'
        autowire: true
        autoconfigure: true
        exclude: '../src/{Entity,Exception}'
EOF

# --- 7. Événement d'exemple --------------------------------------------------

cat > "$BUNDLE_ROOT/src/Event/${EVENT_CLASS_NAME}.php" <<EOF
<?php

namespace ${VENDOR_NS}\\${PASCAL_NAME}\\Event;

use Symfony\Contracts\EventDispatcher\Event;

/**
 * Événement émis par ${CLASS_NAME}.
 *
 * D'autres bundles/services de l'application peuvent s'y abonner
 * (via un EventSubscriber ou l'attribut #[AsEventListener]) pour
 * réagir ou récupérer les données transportées, sans dépendance directe
 * envers ${CLASS_NAME}.
 */
class ${EVENT_CLASS_NAME} extends Event
{
    public const NAME = '${EVENT_SNAKE_NAME}.example';

    /**
     * @param array<string, mixed> \$data
     */
    public function __construct(
        private readonly array \$data,
    ) {
    }

    /**
     * @return array<string, mixed>
     */
    public function getData(): array
    {
        return \$this->data;
    }
}
EOF

# --- 8. Service qui dispatch l'événement ------------------------------------

cat > "$BUNDLE_ROOT/src/Service/${NOTIFIER_CLASS_NAME}.php" <<EOF
<?php

namespace ${VENDOR_NS}\\${PASCAL_NAME}\\Service;

use ${VENDOR_NS}\\${PASCAL_NAME}\\Event\\${EVENT_CLASS_NAME};
use Symfony\Contracts\EventDispatcher\EventDispatcherInterface;

/**
 * Exemple de service qui notifie le reste de l'application (et donc
 * les autres bundles) en dispatchant un événement Symfony.
 *
 * Autowired automatiquement grâce à services.yaml : injecte-le simplement
 * dans n'importe quel service/contrôleur via ${NOTIFIER_CLASS_NAME} \$notifier.
 */
class ${NOTIFIER_CLASS_NAME}
{
    public function __construct(
        private readonly EventDispatcherInterface \$eventDispatcher,
    ) {
    }

    /**
     * @param array<string, mixed> \$data
     */
    public function notify(array \$data): void
    {
        \$event = new ${EVENT_CLASS_NAME}(\$data);
        \$this->eventDispatcher->dispatch(\$event, ${EVENT_CLASS_NAME}::NAME);
    }
}
EOF

# --- 9. Contrôleur d'exemple (dispatch l'événement) -------------------------

cat > "$BUNDLE_ROOT/src/Controller/ExampleController.php" <<EOF
<?php

namespace ${VENDOR_NS}\\${PASCAL_NAME}\\Controller;

use ${VENDOR_NS}\\${PASCAL_NAME}\\Service\\${NOTIFIER_CLASS_NAME};
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class ExampleController extends AbstractController
{
    public function __construct(
        private readonly ${NOTIFIER_CLASS_NAME} \$notifier,
    ) {
    }

    #[Route('/${KEBAB_NAME}', name: '${KEBAB_NAME//-/_}_example')]
    public function __invoke(): Response
    {
        \$this->notifier->notify(['message' => '${CLASS_NAME} a quelque chose à partager']);

        return new Response('Bundle ${CLASS_NAME} opérationnel ! Événement dispatché.');
    }
}
EOF

# --- 10. README ---------------------------------------------------------------

cat > "$BUNDLE_ROOT/README.md" <<EOF
# ${CLASS_NAME}

${DESCRIPTION}

## Installation

En local, ajoute ceci au \`composer.json\` de ton application Symfony :

\`\`\`json
"repositories": [
    { "type": "path", "url": "./bundles/${PASCAL_NAME}" }
]
\`\`\`

Puis :

\`\`\`bash
composer require ${PACKAGE_NAME}:@dev
\`\`\`

Symfony Flex enregistre automatiquement le bundle dans \`config/bundles.php\`.

## Routing

Ajoute dans \`config/routes.yaml\` de ton application :

\`\`\`yaml
${KEBAB_NAME//-/_}:
    resource: ${VENDOR_NS}\\${PASCAL_NAME}\\Controller\\ExampleController
    type: attribute
\`\`\`

## Événements : s'abonner depuis un autre bundle/service

${CLASS_NAME} dispatche \`${VENDOR_NS}\\${PASCAL_NAME}\\Event\\${EVENT_CLASS_NAME}\`
(nom : \`${EVENT_SNAKE_NAME}.example\`) via le service \`${NOTIFIER_CLASS_NAME}\`.

N'importe quel autre bundle ou service de l'application peut s'y abonner
sans dépendre directement de ${CLASS_NAME}, par exemple avec l'attribut
\`#[AsEventListener]\` :

\`\`\`php
use ${VENDOR_NS}\\${PASCAL_NAME}\\Event\\${EVENT_CLASS_NAME};
use Symfony\Component\EventDispatcher\Attribute\AsEventListener;

class MonListener
{
    #[AsEventListener(event: ${EVENT_CLASS_NAME}::class)]
    public function onExample(${EVENT_CLASS_NAME} \$event): void
    {
        \$data = \$event->getData();
        // ... récupérer/traiter les infos ici
    }
}
\`\`\`

Ou via un \`EventSubscriberInterface\` classique :

\`\`\`php
use ${VENDOR_NS}\\${PASCAL_NAME}\\Event\\${EVENT_CLASS_NAME};
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class MonSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [${EVENT_CLASS_NAME}::NAME => 'onExample'];
    }

    public function onExample(${EVENT_CLASS_NAME} \$event): void
    {
        \$data = \$event->getData();
        // ...
    }
}
\`\`\`

Les deux sont autowired/autoconfigured automatiquement par Symfony, aucune
config manuelle de tag n'est nécessaire.
EOF

# --- 11. .gitignore -----------------------------------------------------------

cat > "$BUNDLE_ROOT/.gitignore" <<'EOF'
/vendor/
composer.lock
.phpunit.result.cache
EOF

# --- 12. Liaison automatique avec l'application Symfony (dossier racine) ----
#
# Ce script est prévu pour être lancé depuis la racine du projet Symfony :
# on cherche donc directement ./composer.json, sans demander de chemin.

echo "✅ Bundle créé dans : $BUNDLE_ROOT"
echo

APP_COMPOSER="./composer.json"

if [[ -f "$APP_COMPOSER" ]]; then
    read -rp "composer.json détecté à la racine. Lier le bundle automatiquement ? [Y/n] " LINK_CONFIRM
    LINK_CONFIRM="${LINK_CONFIRM:-Y}"
    if [[ ! "$LINK_CONFIRM" =~ ^[Yy]$ ]]; then
        APP_COMPOSER=""
    fi
else
    echo "ℹ️  Aucun composer.json trouvé à la racine du projet — étape de liaison ignorée."
    APP_COMPOSER=""
fi

if [[ -n "$APP_COMPOSER" ]]; then

    if [[ ! -f "$APP_COMPOSER" ]]; then
        echo "⚠️  Fichier introuvable : $APP_COMPOSER — étape ignorée." >&2
    elif ! command -v python3 >/dev/null 2>&1; then
        echo "⚠️  python3 introuvable, impossible de modifier le composer.json automatiquement." >&2
        echo "   Ajoute manuellement le repository path (voir README.md du bundle)." >&2
    else
        APP_DIR=$(dirname "$(realpath "$APP_COMPOSER")")
        BUNDLE_ABS=$(realpath "$BUNDLE_ROOT")
        RELATIVE_PATH=$(realpath --relative-to="$APP_DIR" "$BUNDLE_ABS")

        cp "$APP_COMPOSER" "${APP_COMPOSER}.bak"

        if python3 - "$APP_COMPOSER" "$RELATIVE_PATH" "$PACKAGE_NAME" <<'PYEOF'
import json, sys

app_composer_path, relative_path, package_name = sys.argv[1:4]

with open(app_composer_path, "r", encoding="utf-8") as f:
    data = json.load(f)

repos = data.setdefault("repositories", [])
new_repo = {"type": "path", "url": relative_path}
if new_repo not in repos:
    repos.append(new_repo)

require = data.setdefault("require", {})
require[package_name] = "@dev"

with open(app_composer_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
    f.write("\n")
PYEOF
        then
            echo "✅ composer.json de l'appli mis à jour (backup : ${APP_COMPOSER}.bak)"
            echo "   Repository path ajouté : $RELATIVE_PATH"
            echo "   Dépendance ajoutée     : ${PACKAGE_NAME} @dev"

            read -rp "Lancer 'composer update ${PACKAGE_NAME}' maintenant ? [y/N] " RUN_COMPOSER
            if [[ "$RUN_COMPOSER" =~ ^[Yy]$ ]]; then
                if command -v composer >/dev/null 2>&1; then
                    (cd "$APP_DIR" && composer update "$PACKAGE_NAME")
                else
                    echo "⚠️  composer introuvable dans le PATH, commande non exécutée." >&2
                fi
            fi
        else
            echo "⚠️  Échec de la modification automatique (composer.json invalide ?)." >&2
            echo "   Restauration du fichier d'origine." >&2
            cp "${APP_COMPOSER}.bak" "$APP_COMPOSER"
        fi
    fi
fi

# --- 13. Récap final ----------------------------------------------------------

echo
echo "Prochaines étapes restantes :"
echo "  1. cd $BUNDLE_ROOT && git init"
if [[ -z "$APP_COMPOSER" ]]; then
    echo "  2. Dans le composer.json de ton app, ajoute :"
    echo "       \"repositories\": [{ \"type\": \"path\", \"url\": \"${BUNDLE_ROOT}\" }]"
    echo "  3. composer require ${PACKAGE_NAME}:@dev"
fi
echo
