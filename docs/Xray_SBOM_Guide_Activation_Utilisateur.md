# Le SBOM arrive dans Xray — guide utilisateur

*Ce que l'activation du SBOM change pour vous, et comment vous en servir*

---

## Bonne nouvelle : le SBOM sera activé le 25 août 2026

La fonctionnalité **SBOM** de Xray sera activée le **25 août 2026** dans notre environnement. Ce guide vous explique, sans jargon, ce que cela veut dire et comment l'utiliser au quotidien.

> **Vous n'avez rien à activer vous-même.** La mise en service est réalisée par l'équipe d'administration le 25 août 2026. Ce guide est là pour que vous soyez prêt le jour J.

---

## D'abord, c'est quoi un SBOM ?

**SBOM** signifie *Software Bill of Materials* — la **nomenclature logicielle**. C'est la liste complète des « ingrédients » qui composent une application :

- ses composants et bibliothèques,
- les versions précises de chacun,
- les licences associées,
- les vulnérabilités connues,
- et même les **dépendances de vos dépendances** (les dépendances transitives).

Imaginez l'étiquette d'un produit alimentaire, mais pour votre code.

---

## Ce que vous pourrez faire une fois le SBOM activé

### 1. Voir la composition complète d'un artefact
Sur n'importe quel artefact scanné, vous verrez la liste de ses composants, avec leurs versions, licences et vulnérabilités — dépendances directes **et** transitives comprises.

### 2. Générer et exporter un SBOM
En quelques clics, vous pourrez produire la nomenclature d'un artefact dans un **format standard**, réutilisable partout (clients, audit, chaîne CI) :

| Format | Quand l'utiliser |
|---|---|
| **CycloneDX** | Orientation sécurité — inclut les informations d'exploitabilité (VEX) |
| **SPDX** | Orientation conformité et gestion des licences |

### 3. Réagir vite en cas de faille
Quand une nouvelle vulnérabilité est annoncée, vous pourrez retrouver **en quelques secondes** tous les artefacts et applications qui contiennent le composant concerné. Fini les heures d'investigation manuelle.

---

## Comment générer un SBOM — pas à pas

### Depuis l'interface Xray

1. Ouvrez l'artefact scanné qui vous intéresse.
2. Affichez ses composants et dépendances.
3. Choisissez l'option d'**export des résultats de scan**.
4. Sélectionnez le **format SBOM** souhaité (CycloneDX ou SPDX).
5. Générez et téléchargez le fichier.

Le fichier obtenu contient la nomenclature complète, prête à être partagée ou archivée.

### Depuis l'API (pour les usages automatisés)

Si vous automatisez vos pipelines, vous pourrez générer un SBOM en une requête :

```bash
curl 'https://<url>/xray/api/v1/component/exportDetails' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <votre_token>' \
  -d '{
    "component_name": "<nom>:<version>",
    "package_type": "build",
    "output_format": "json",
    "cyclonedx": true,
    "cyclonedx_format": "json",
    "sha_256": "<checksum>"
  }' -o sbom.zip
```

Idéal pour produire automatiquement le SBOM d'un build à chaque livraison.

### Avec le JFrog CLI

Le JFrog CLI (`jf`) offre deux approches selon votre besoin.

**Option A — Générer un SBOM lors d'un scan**

L'indicateur `--sbom` n'est pas autonome : il se combine avec l'analyse SCA et le format CycloneDX pour produire une nomenclature complète, incluant toutes les dépendances (pas seulement celles porteuses de vulnérabilités). La forme correcte est :

```bash
# Audit d'un projet local : SCA + SBOM au format CycloneDX
jf audit --sca --sbom --format=cyclonedx

# Rediriger la sortie vers un fichier
jf audit --sca --sbom --format=cyclonedx > sbom.cdx.json
```

Note : `--sbom` requiert le flag `--sca` et un format `cyclonedx` (ou `table` pour un affichage). Vérifiez que votre version du JFrog CLI supporte ces options avec `jf --version`.

**Option B — Exporter le SBOM d'un build déjà publié et scanné**

Pour récupérer le SBOM d'un build existant, on appelle l'API d'export via `jf xr curl` (pratique car le CLI gère l'authentification à votre place) :

```bash
jf xr curl 'api/v1/component/exportDetails' \
  --header 'Content-Type: application/json' \
  --data '{
    "component_name": "<nom-du-build>:<numero>",
    "package_type": "build",
    "output_format": "json",
    "spdx": false,
    "cyclonedx": true,
    "cyclonedx_format": "json",
    "sha_256": "<checksum>"
  }' -o sbom.zip
```

Pour obtenir un SBOM au format **SPDX** plutôt que CycloneDX, inversez les indicateurs : `"spdx": true` et `"cyclonedx": false` (avec `"spdx_format"` parmi `json`, `tag:value` ou `xlsx`).

> 💡 **Astuce CI/CD :** l'option A (`--sbom` lors du scan) est la plus adaptée pour intégrer la génération de SBOM dans un pipeline, car elle ne nécessite pas de connaître à l'avance le checksum du build.

---

## Bon à savoir

- **Vos réglages ne changent pas.** Le SBOM s'ajoute à Xray, il ne modifie ni vos politiques, ni vos watches, ni votre façon de travailler.
- **Les dépendances transitives sont incluses** dans les SBOM exportés — une exigence de plus en plus fréquente côté réglementation.
- **Périmètre :** ce guide couvre l'analyse des dépendances open source (SCA). La vue arborescente interactive des dépendances relève d'un module (Advanced Security) non activé chez nous ; elle n'est donc pas disponible. En revanche, l'export enrichi des dépendances, lui, l'est.
- **Formats standard :** les SBOM produits (CycloneDX, SPDX) sont reconnus dans toute l'industrie et réutilisables par vos clients et vos outils.

---

## Questions fréquentes

**Dois-je activer quelque chose ?**
Non. L'activation est faite par l'administration. Vous en profiterez automatiquement.

**Quand est-ce disponible ?**
Le 25 août 2026. Une communication vous sera adressée le jour de l'activation.

**Est-ce que ça ralentit mes scans ?**
Non. Le moteur SBOM est optimisé ; les performances sont même améliorées.

**Puis-je automatiser la génération de SBOM en CI ?**
Oui, via l'API et la CLI JFrog.

**Une autre question ?**
Contactez l'équipe d'administration Xray.

---

*Guide destiné aux utilisateurs de Xray. Les fonctionnalités réellement disponibles dépendent de notre licence et de la configuration retenue. Pour les aspects techniques d'activation et d'exploitation, l'équipe d'administration dispose d'une documentation dédiée.*
