# Ce qui change pour vous avec la nouvelle version de Xray

*Petit guide pour comprendre les nouveautés — sans jargon inutile*

Bonjour,

Notre plateforme de sécurité **JFrog Xray** vient de faire un grand bond en avant. Sur le papier, on passe de la version 3.88 à la 3.137 : plus de quarante versions d'écart. Mais rassurez-vous, vous n'avez rien à réapprendre. La plupart des changements travaillent pour vous en coulisses, et les quelques nouveautés visibles vont plutôt vous simplifier la vie.

Voici, en quelques minutes de lecture, ce que vous allez remarquer.

> **Bon à savoir avant de commencer.** Ce guide ne parle que de ce que vous utilisez au quotidien : l'analyse des dépendances open source (SCA). Les modules que notre organisation n'a pas activés — la sécurité avancée (JAS) et la Curation — ne sont pas abordés ici, pour ne pas vous encombrer avec des fonctions qui ne vous concernent pas.

---

## En deux mots

Si vous ne devez retenir que l'essentiel :

- Xray repère les vulnérabilités **plus finement** qu'avant, et vous fait donc perdre moins de temps sur de fausses alertes.
- Une **nouvelle capacité SBOM arrive bientôt** : de quoi générer facilement la « liste des ingrédients » de vos logiciels.
- Une **nouvelle page d'accueil** vous donne enfin une vue d'ensemble claire de votre situation.
- Et globalement, **tout va plus vite**.

C'est parti pour le détail.

---

## 1. Des analyses plus intelligentes, moins de bruit

### Xray sait maintenant d'où vient le problème

Avant, quand une vulnérabilité apparaissait dans une image de conteneur, il fallait deviner si elle venait de l'image de base (celle que vous n'avez pas écrite) ou de votre propre code. Désormais, **Xray fait la distinction tout seul**. Vous voyez immédiatement si le correctif consiste à mettre à jour l'image socle ou à corriger quelque chose chez vous. Concrètement : moins d'enquête, plus d'action.

### Des scores de gravité plus à jour

Xray affiche maintenant les scores **CVSS v4**, la dernière génération de notation des vulnérabilités, en plus des scores v3 que vous connaissez déjà. Vous priorisez donc vos corrections sur des informations plus fines et plus récentes.

### Xray traque aussi les paquets piégés

Les capacités de détection des **paquets malveillants** et d'évaluation des **paquets à risque** (abandonnés, plus maintenus…) continuent de s'enrichir automatiquement, grâce aux mises à jour permanentes de la base de connaissances JFrog. Vous n'avez rien à faire : ça se met à jour tout seul.

### Une couverture plus large

Le champ d'analyse s'est étendu : vos **builds** et vos **Release Bundles** sont désormais couverts de la même manière que le reste. Une visibilité homogène, sans angle mort.

---

## 2. Vos règles et alertes : rien ne bouge (et c'est voulu)

Bonne nouvelle pour ceux qui ont patiemment configuré leurs politiques : **tout est conservé.** Vos politiques, vos watches et vos règles d'exclusion continuent de fonctionner exactement comme avant.

Deux petites améliorations au passage :

- Les **règles d'exclusion** acceptent maintenant des formats de chemin plus souples (par exemple, exclure d'un coup tout ce qui se trouve dans un dossier de tests). Plus besoin de lister les chemins un par un.
- L'affichage des **violations** est plus lisible et plus rapide à filtrer.

---

## 3. Le SBOM arrive bientôt — et ça va compter

Vous entendrez de plus en plus parler du **SBOM** (*Software Bill of Materials*, littéralement la « nomenclature logicielle »). L'idée est simple : c'est la **liste complète des ingrédients** de vos applications — chaque composant, chaque bibliothèque, chaque version.

Xray introduit un moteur SBOM entièrement repensé, qui apporte :

- Une génération de cette liste **plus rapide et plus fiable**, dans les formats reconnus partout dans l'industrie.
- Une **analyse d'impact** bien meilleure : quand une nouvelle faille est annoncée, vous identifiez en quelques secondes quelles applications sont concernées.
- De quoi répondre sereinement aux **exigences réglementaires** de plus en plus fréquentes sur ce sujet.

> **À retenir :** cette fonctionnalité **sera activée prochainement** chez nous. Elle nécessite une petite préparation côté administration, et vous serez prévenu dès qu'elle sera disponible. En attendant, il n'y a rien à faire de votre côté.

---

## 4. Une interface plus agréable

### Une vraie page d'accueil

Xray vous accueille désormais avec une **vue d'ensemble** de votre sécurité : où en sont vos violations, quelles tendances se dessinent, où porter votre attention en priorité. Fini de chercher : l'essentiel est sous vos yeux dès la connexion.

### Des détails qui comptent

- Les listes de violations sont plus claires et se filtrent plus vite.
- L'accessibilité a été améliorée (meilleure compatibilité avec les lecteurs d'écran, textes alternatifs).
- Les résultats d'analyse et les détails de vulnérabilité sont mieux présentés.

---

## 5. Rapports et automatisations

- Vous pouvez générer des **SBOM** dans les formats standard, directement exploitables pour vos obligations de conformité.
- Les **rapports de violations** et leurs exports ont été améliorés.
- Les **API** se sont enrichies (SBOM, violations), pour ceux qui automatisent leurs intégrations.

---

## 6. Et surtout : tout va plus vite

Beaucoup de travail a été fait « sous le capot ». Vous ne le verrez pas directement, mais vous le sentirez :

- L'**analyse** de vos artefacts et builds est plus rapide.
- Les **recherches** et l'affichage des violations répondent au quart de tour.
- La **génération de SBOM** est optimisée.
- Le mécanisme de mise à jour de la base de vulnérabilités a été modernisé.

---

## Vos questions, nos réponses

**Est-ce que je vais perdre mes réglages ?**
Non. Vos politiques, watches et exclusions sont conservés. Un petit coup d'œil pour revalider après la mise à jour ne fait jamais de mal, mais rien n'est perdu.

**Et mon historique d'analyses ?**
Intact. Tout est conservé.

**Dois-je faire quelque chose pour profiter des nouveautés (CVSS v4, détection d'image de base…) ?**
Non, elles sont là automatiquement. Vous n'avez qu'à en profiter.

**Quand pourrai-je utiliser le SBOM ?**
Très bientôt. L'activation se prépare côté administration, et vous serez informé dès que ce sera prêt.

**J'ai une question qui n'est pas ici…**
N'hésitez pas à contacter l'équipe d'administration Xray. On est là pour ça.

---

*Ce guide présente les nouveautés du point de vue de votre usage quotidien. Les fonctionnalités réellement disponibles dépendent de notre licence et de la configuration retenue. Pour les aspects techniques (installation, exploitation), l'équipe d'administration dispose d'une documentation dédiée.*

*Merci de votre lecture, et bonne découverte de la nouvelle version.*
