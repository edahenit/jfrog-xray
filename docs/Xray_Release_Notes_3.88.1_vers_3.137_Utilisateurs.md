# Notes de version — JFrog Xray 3.88.1 → 3.137

**Public visé :** utilisateurs de Xray (équipes sécurité, développeurs, gestionnaires de politiques)
**Objet :** synthèse des nouveautés fonctionnelles apportées par la mise à niveau, du point de vue de l'utilisation quotidienne. Les aspects purement techniques d'installation et d'exploitation ne sont pas couverts ici.
**Périmètre :** ce document couvre uniquement les fonctionnalités **Xray SCA** (analyse de composition logicielle) réellement utilisées dans votre environnement. Les modules non utilisés sont volontairement exclus :
- **JFrog Advanced Security (JAS)** — analyse contextuelle des CVE, SAST, détection de secrets, sécurité IaC, scan d'expositions.
- **JFrog Curation** — blocage préventif des dépendances open source.

**Sources :** documentation officielle JFrog (voir la section Références en fin de document).

---

## En bref

Cette mise à niveau couvre plus de 40 versions intermédiaires. Pour vous, utilisateur, les changements les plus visibles se concentrent sur quatre domaines :

- Une **détection des vulnérabilités plus précise** (détection de l'image de base, scores CVSS v4).
- Un **nouveau service SBOM** (activation prochaine) qui change la façon de générer et d'exploiter les nomenclatures logicielles.
- Une **nouvelle page d'accueil Xray** offrant une vue unifiée de votre posture de sécurité.
- Des **rapports et exports** plus riches, et de nombreuses améliorations de performance.

---

## 1. Analyse de composition logicielle (SCA) et scan

### Détection de l'image de base (Base Image Detection)
Xray distingue désormais les vulnérabilités provenant de l'**image de base** d'un conteneur de celles introduites par vos **couches applicatives**. Concrètement, vous identifiez plus vite si un problème vient de l'image socle (et relève d'une mise à jour d'image) ou de votre propre contenu, ce qui accélère le tri et la remédiation.

### Support du CVSS v4
En complément du CVSS v3, Xray affiche désormais les scores **CVSS v4** lorsqu'ils sont disponibles. Vous disposez d'une évaluation de gravité plus fine et plus récente pour prioriser vos actions.

### Détection des paquets malveillants et risque opérationnel
Les capacités SCA de détection des **paquets malveillants** et d'évaluation du **risque opérationnel** (paquets obsolètes, peu maintenus, etc.) bénéficient des mises à jour continues de la base de données de vulnérabilités JFrog.

### Couverture de scan élargie
Le périmètre couvert par le scan SCA s'est étendu au fil des versions, incluant notamment les **builds** et les **Release Bundles v2**, pour une visibilité homogène sur l'ensemble de vos artefacts.

### Base de données de vulnérabilités
La base de vulnérabilités continue de s'enrichir, avec une meilleure qualité de données (descriptions, versions corrigées, références). La synchronisation passe par **DB Sync v3** (voir section Performance).

---

## 2. Politiques, watches et violations

- Gestion des **politiques** et **watches** conservée et fiabilisée : vos règles de sécurité et de licence continuent de s'appliquer normalement après la mise à niveau.
- Les **règles d'exclusion (ignore rules)** acceptent désormais des motifs de type *Ant* (par exemple `**/test/**`), ce qui facilite l'exclusion ciblée de chemins.
- Affichage et filtrage des **violations** plus lisibles et plus rapides.

---

## 3. Service SBOM (nouveau — activation prochaine)

Xray introduit un **service SBOM** reposant sur un modèle de données optimisé pour la recherche de CVE, la génération de nomenclatures logicielles (Software Bill of Materials) et l'analyse d'impact. **Cette fonctionnalité sera activée prochainement dans votre environnement.**

Pour vous, cela se traduit par :

- Une **génération de SBOM** plus rapide et plus fiable, aux formats standard du marché.
- Une **analyse d'impact** améliorée : identifier rapidement quels composants et applications sont touchés par une vulnérabilité donnée.
- Une base solide pour répondre aux exigences réglementaires et contractuelles autour des SBOM.

> **Important :** ce service n'est pas actif par défaut. **Son activation est prévue prochainement** dans votre environnement ; elle est réalisée par votre administrateur et s'accompagne d'une migration de données. Une fois activé, les fonctionnalités SBOM enrichies deviennent disponibles dans l'interface et via l'API. Une communication vous sera adressée au moment de l'activation.

---

## 4. Interface et expérience utilisateur

### Nouvelle page d'aperçu Xray (Xray Overview)
Une nouvelle page d'accueil offre une **vue unifiée de votre posture de sécurité** : synthèse des violations, tendances, zones nécessitant votre attention. Elle sert de point d'entrée pour naviguer efficacement dans Xray.

### Améliorations diverses de l'interface
- Affichage et filtrage des **violations** plus lisibles et plus rapides.
- Améliorations d'**accessibilité** (textes alternatifs, lecteurs d'écran).
- Meilleure présentation des résultats de scan et des détails de vulnérabilité.

---

## 5. Rapports, exports et API

- **Génération de SBOM** aux formats standard, exploitable pour vos obligations de conformité.
- Améliorations des **rapports de violations** et de leur export.
- Enrichissement des **API** autour du SBOM et des violations, pour vos intégrations et automatisations.

---

## 6. Performance et fiabilité

De nombreuses optimisations, transparentes pour vous mais perceptibles à l'usage :

- **Indexation** plus rapide des artefacts et des builds.
- Requêtes de **violations** et de recherche accélérées.
- Génération de **SBOM** optimisée.
- Passage à **DB Sync v3** pour la synchronisation de la base de données de vulnérabilités, en remplacement de l'ancienne version.

---

## 7. Foire aux questions

**Mes politiques et watches existantes sont-elles conservées ?**
Oui. Vos politiques, watches et règles d'exclusion sont préservées par la mise à niveau. Il est toutefois recommandé de les revalider après coup.

**Vais-je perdre l'historique de mes scans ?**
Non. Les données de scan et de vulnérabilités sont stockées en base et conservées lors de la mise à niveau.

**Dois-je faire quelque chose pour bénéficier du CVSS v4 ou de la détection d'image de base ?**
Non, ces améliorations sont disponibles automatiquement après la mise à niveau.

**Comment activer la génération de SBOM enrichie ?**
L'activation du service SBOM est réalisée par votre administrateur et est prévue prochainement. Une fois active, les fonctionnalités correspondantes apparaissent automatiquement dans l'interface et l'API, et une communication vous sera adressée.

---

## Références

- Notes de version Xray — https://docs.jfrog.com/releases/docs/xray
- Dépréciations Xray — https://docs.jfrog.com/releases/docs/xray-deprecations
- Activation et suivi de la migration SBOM — https://docs.jfrog.com/security/docs/how-to-enable-and-monitor-sbom-migration-in-xray
- Xray SCA (analyse de composition logicielle) — https://jfrog.com/xray/

---

*Document de synthèse à destination des utilisateurs. Pour les procédures d'installation, de dimensionnement et d'exploitation, se référer au plan d'upgrade dédié et à la documentation d'administration JFrog. Les fonctionnalités réellement disponibles dépendent de votre licence et de la configuration retenue par votre administrateur.*
