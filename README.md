# Codex Usage for Plasma 6

Un plasmoïde KDE Plasma 6 qui affiche les limites Codex et le nombre de resets disponibles dans votre abonnement ChatGPT. Il utilise l'interface JSON documentée de `codex app-server`; le widget ne lit ni ne copie directement les jetons de `~/.codex/auth.json`.

## Prérequis

- KDE Plasma 6 avec les modules `plasma5support` et `org.kde.quickcharts`
- Python 3
- Codex CLI accessible dans `PATH`
- Une session Codex connectée à ChatGPT (`codex login status`)

## Installation

Avec le paquet prêt à installer :

```bash
kpackagetool6 -t Plasma/Applet -i codex-usage.plasmoid
```

Ou directement depuis les sources de ce dossier :

```bash
kpackagetool6 -t Plasma/Applet -i package
```

Ensuite, ouvrez « Ajouter des composants graphiques » dans Plasma et recherchez **Codex Usage**.

Pour mettre à jour une installation existante :

```bash
kpackagetool6 -t Plasma/Applet -u codex-usage.plasmoid
```

Le widget actualise automatiquement les données toutes les 10 minutes. Le bouton en haut à droite force une actualisation immédiate.

## Vérifier la source de données

```bash
python3 package/contents/code/codex_usage.py
```

La sortie ne contient que les pourcentages, les fenêtres de quota, les dates de remise à zéro et le type d'abonnement. Les identifiants de compte et jetons ne sont jamais réémis.

## Tests du rendu compact

La vue compacte utilise directement le même `PieChartControl` KDE, le même contrat de conteneur et le même halo de lisibilité que le widget de RAM. Ces tests verrouillent ces choix et vérifient son chargement dans une cellule de panneau :

```bash
tests/CompactUsesKdePieChart.sh
tests/CompactTextContrast.sh
qml6 tests/CompactHostProbe.qml
```

## Désinstallation

```bash
kpackagetool6 -t Plasma/Applet -r com.elie.codexusage
```
