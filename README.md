# MTESS - Déployer formulaire FRW (GitHub Action)

GitHub Action pour déployer des formulaires FRW vers les environnements MTESS.

## Utilisation

```yaml
- uses: MTESSDev/github-action-mtess-frw-deploiement@main
  with:
    repertoire: ${{ github.workspace }}/formulaires
    environnement: QA
    noPublicSystemeAutorise: ${{ secrets.FRW_NO_PUBLIC_SYSTEME }}
    apiKey: ${{ secrets.FRW_API_KEY }}
```

## Paramètres

| Paramètre | Requis | Défaut | Description |
|---|---|---|---|
| `repertoire` | Non | `${{ github.workspace }}` | Répertoire contenant les formulaires à déployer |
| `environnement` | Non | `QA` | Environnement cible : `QA`, `PROD`, ou une URL complète |
| `noPublicSystemeAutorise` | Oui | — | GUID du système autorisé |
| `apiKey` | Oui | — | Clée d'API du système |

## Environnements disponibles

| Valeur | URL |
|---|---|
| `QA` | https://formulaires.it.mtess.gouv.qc.ca |
| `PROD` | https://formulaires.mtess.gouv.qc.ca |
| URL complète | Utilise l'URL fournie directement |

## Configuration des secrets

Les valeurs sensibles doivent être configurées comme secrets dans votre dépôt GitHub :
**Settings → Secrets and variables → Actions → New repository secret**

- `FRW_API_KEY` — Clée d'API de votre système
- `FRW_NO_PUBLIC_SYSTEME` — Numéro public de système autorisé (GUID)

## Exemple complet

```yaml
name: Déployer formulaires

on:
  push:
    branches: [main]

jobs:
  deployer:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - uses: MTESSDev/github-action-mtess-frw-deploiement@main
        with:
          repertoire: ${{ github.workspace }}/formulaires
          environnement: PROD
          noPublicSystemeAutorise: ${{ secrets.FRW_NO_PUBLIC_SYSTEME }}
          apiKey: ${{ secrets.FRW_API_KEY }}
```

## Support

Pour du support, contactez DTN - MonDossier - MTESS ou ouvrez une [issue](https://github.com/MTESSDev/github-action-mtess-frw-deploiement/issues).
