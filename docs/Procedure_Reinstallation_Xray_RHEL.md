# JFrog Xray 3.88 — Réparation RabbitMQ & Réinstallation (nœud unique, RHEL 9.6, PostgreSQL externe)

> Contexte : Xray 3.88 sur RedHat 9.6, ne redémarre plus, suspicion d'un problème RabbitMQ. Base PostgreSQL déjà installée et prête.

**⚠️ À lire d'abord :** dans 90 % des cas, un blocage RabbitMQ se règle **sans réinstaller Xray**. Faites d'abord le diagnostic et les correctifs de la Partie 1. Ne passez à la réinstallation (Partie 3) que si la Partie 1 échoue. Conservez vos chemins (`$JFROG_HOME` = `/opt/jfrog/xray` par défaut).

---

## Partie 0 — Diagnostic rapide

Avant tout, identifiez le message d'erreur exact dans les logs :

```bash
tail -n 200 $JFROG_HOME/xray/var/log/console.log
# logs RabbitMQ dédiés
ls -l $JFROG_HOME/xray/var/log/
tail -n 100 $JFROG_HOME/xray/var/log/rabbitmq*.log 2>/dev/null
```

Vérifiez l'état des processus et des services :

```bash
systemctl status xray.service
ps aux | grep -E "erl|epmd|rabbit|beam"
# état du cluster RabbitMQ
cd /opt/jfrog/xray/app/third-party/rabbitmq/sbin && ./rabbitmqctl cluster_status
```

Le message d'erreur oriente vers le bon correctif ci-dessous.

---

## Partie 1 — Correctifs RabbitMQ (selon la doc JFrog)

### Cas A — `Exception (403) "username or password not allowed"`
Le mot de passe RabbitMQ ne correspond pas entre `rabbitmq.conf` et `system.yaml`.

1. Testez la connexion depuis l'utilisateur Xray :
   ```bash
   curl --user guest:guest http://localhost:15672/api/vhosts
   ```
2. Si échec, réinitialisez le mot de passe `guest` :
   ```bash
   cd /opt/jfrog/xray/app/third-party/rabbitmq/sbin
   ./rabbitmqctl change_password guest guest
   ```
3. Alignez le même couple identifiant/mot de passe dans `rabbitmq.conf`
   (`$JFROG_HOME/xray/app/bin/rabbitmq/`) **et** dans `system.yaml` :
   ```yaml
   shared:
     rabbitMq:
       erlangCookie:
         value: JFXR_RABBITMQ_COOKIE
       url: amqp://localhost:5672/
       username: guest
       password: guest
   ```
4. Redémarrez Xray.

### Cas B — `Exception (504) "channel/connection is not open"` ou erreur Mnesia
Log typique : `Error while waiting for Mnesia tables: {timeout_waiting_for_tables, ...}` → **tables Mnesia corrompues**.

```bash
# 1. Arrêter Xray
systemctl stop xray.service

# 2. Sauvegarder puis vider le répertoire mnesia
mv $JFROG_HOME/xray/var/data/rabbitmq/mnesia $JFROG_HOME/xray/var/data/rabbitmq/mnesia.bak

# 3. Redémarrer Xray (RabbitMQ recrée les tables)
systemctl start xray.service
```

> ⚠️ La suppression du répertoire `mnesia` efface les files d'attente et exchanges RabbitMQ. Si une indexation était en cours, il faudra ré-indexer les artefacts concernés. **Aucune donnée Xray (PostgreSQL) n'est touchée.**

### Cas C — `no access to this vhost`
Survient après un disque plein, un arrêt incorrect, ou un problème de permissions sur le vhost `/`. Vérifiez l'espace disque (`df -h`) et suivez l'article KB JFrog dédié (lien en sources).

### Cas D — `connection refused / dial tcp 127.0.0.1:5672` (cookie Erlang non concordant)
RabbitMQ ne démarre pas car le cookie Erlang créé par Xray ne correspond pas à celui de RabbitMQ.

```bash
# Vérifier le cluster
cd /opt/jfrog/xray/app/third-party/rabbitmq/sbin && ./rabbitmqctl cluster_status

# Arrêter Xray et TUER tous les process résiduels
systemctl stop xray.service
ps aux | grep -E "erl|epmd|rabbit|erlang"   # puis kill -9 <PID> pour chacun
```

Faites correspondre le contenu des fichiers `.erlang.cookie` aux 3 emplacements (valeur attendue `JFXR_RABBITMQ_COOKIE`) :
`/root/.erlang.cookie`, `/opt/jfrog/xray/.erlang.cookie`, `/opt/jfrog/xray/app/third-party/rabbitmq/.erlang.cookie`.
Puis dans `system.yaml`, `shared.rabbitMq.erlangCookie.value: JFXR_RABBITMQ_COOKIE`.
Sauvegardez et videz ensuite `$JFROG_HOME/xray/var/data/rabbitmq/mnesia`, puis redémarrez Xray.

> **Note Xray 3.8x (concerne votre version) :** depuis la 3.8x, `stop`/`restart` de Xray **n'agit plus sur RabbitMQ** ; au `start`, si RabbitMQ n'est pas lancé, Xray le démarre. Pour que le script arrête/redémarre aussi RabbitMQ, mettez dans `system.yaml` :
> ```yaml
> shared:
>   rabbitMq:
>     autoStop: true
> ```

---

## Partie 2 — Préparer la réinstallation (si la Partie 1 a échoué)

### 2.1 Sauvegardes indispensables
```bash
# Configuration et secrets (NE PAS perdre la master.key / join.key)
cp -a $JFROG_HOME/xray/var/etc /sauvegarde/xray-etc-$(date +%F)
# Le system.yaml contient toute votre config (URL PostgreSQL, jfrogUrl, join key)
cp $JFROG_HOME/xray/var/etc/system.yaml /sauvegarde/
```
Notez votre **base PostgreSQL existante** : hôte, port (5432), nom de base (`xraydb`), utilisateur (`xray`), mot de passe. La réinstallation **réutilise cette base** — ne la recréez pas si elle contient déjà vos données.

### 2.2 Vérifier la compatibilité PostgreSQL
Xray 3.88 supporte PostgreSQL **13.x → 15.x** (min 13). Vérifiez votre version :
```bash
psql -d xraydb -U xray -W -c "SELECT version();"
```

### 2.3 Installer l'extension `pg_trgm` (obligatoire depuis Xray 3.70.x)
Sur une PostgreSQL externe, cette extension n'est pas toujours présente :
```sql
-- connecté à xraydb en tant que superutilisateur
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### 2.4 (Si la base est vide) créer utilisateur + base
À ne faire **que** si vous repartez d'une base neuve :
```sql
CREATE USER xray WITH PASSWORD 'password';
CREATE DATABASE xraydb WITH OWNER=xray ENCODING='UTF8'
  lc_collate='en_US.utf8' lc_ctype='en_US.utf8' template=template0;
GRANT ALL PRIVILEGES ON DATABASE xraydb TO xray;
```

---

## Partie 3 — Réinstallation de Xray (RPM, nœud unique, RHEL 9.6)

> Méthode RPM = la plus adaptée à RedHat. Récupérez l'archive `jfrog-xray-3.88.x-rpm.tar.gz` correspondant **exactement** à votre version actuelle pour rester aligné avec le schéma de base.

### 3.1 Pré-requis système
Limite de descripteurs de fichiers dans `/etc/security/limits.conf` :
```properties
xray hard nofile 100000
xray soft nofile 100000
postgres hard nofile 100000
postgres soft nofile 100000
```

### 3.2 Extraire l'archive
```bash
tar -xvf jfrog-xray-3.88.x-rpm.tar.gz
cd jfrog-xray-3.88.x-rpm
```

### 3.3 Installer les dépendances RabbitMQ (Erlang + socat)
RHEL 9 → utilisez les paquets `el9` :
```bash
rpm -ivh --replacepkgs ./third-party/rabbitmq/socat-<version>.el9.x86_64.rpm
rpm -ivh --replacepkgs ./third-party/rabbitmq/erlang-<version>.el9.x86_64.rpm
```
*(socat n'est plus requis à partir de Xray 3.109.x — pour 3.88 il l'est.)*

### 3.4 Installer db-util (indexation paquets OS)
```bash
hash db_dump 2>/dev/null || rpm -ivh --replacepkgs ./third-party/misc/<db-utils-version>.x86_64.rpm
```

### 3.5 Installer le paquet Xray (en root)
```bash
rpm -Uvh --replacepkgs ./xray/xray.rpm
```

### 3.6 Restaurer / configurer system.yaml
Replacez votre `system.yaml` sauvegardé dans `$JFROG_HOME/xray/var/etc/`, ou repartez du template. Sections clés à pointer vers votre **PostgreSQL existant** :

```yaml
shared:
  jfrogUrl: "http://<adresse-artifactory>:8082"
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: "postgres://<hote-pg>:5432/xraydb?sslmode=disable"
    username: xray
    password: <mot_de_passe>
  rabbitMq:
    erlangCookie:
      value: JFXR_RABBITMQ_COOKIE
    url: amqp://localhost:5672/
```

- **`jfrogUrl`** : URL de votre machine Artifactory / load balancer.
- **`join.key`** : récupérable dans l'UI JFrog → *Administration → User Management → Settings → Join Key* (ou réutilisez celui de votre sauvegarde).
- **URL base** : format `postgres://<hôte>:<port>/xraydb?sslmode=disable` (mettez `sslmode=verify-ca` si TLS).

### 3.7 Démarrer et vérifier
```bash
systemctl start xray.service
systemctl status xray.service
tail -f $JFROG_HOME/xray/var/log/console.log
```
Accès : `http://<jfrogUrl>/ui/` → module **Administration → Xray**.

---

## Récapitulatif de décision

| Symptôme dans les logs | Action |
|---|---|
| `403 username or password` | Partie 1 — Cas A (réaligner mot de passe) |
| `504 channel/connection` ou `timeout_waiting_for_tables` Mnesia | Partie 1 — Cas B (vider mnesia) |
| `no access to this vhost` | Partie 1 — Cas C (disque/permissions) |
| `connection refused 5672` / cookie | Partie 1 — Cas D (cookie Erlang + mnesia) |
| Aucun correctif ne fonctionne, binaires corrompus | Parties 2 & 3 (réinstallation RPM) |

La base PostgreSQL n'est jamais supprimée par ces opérations : vos données Xray (vulnérabilités, politiques, indexation) sont préservées tant que vous ne recréez pas `xraydb`.

---

### Sources (documentation officielle JFrog)
- [XRAY: How to troubleshoot RabbitMQ related issues which prevents Xray startup](https://jfrog.com/help/r/xray-how-to-troubleshoot-rabbitmq-related-issues-which-prevents-xray-startup)
- [Xray Single Node Manual RPM Installation](https://docs.jfrog.com/installation/docs/xray-single-node-manual-rpm-installation)
- [PostgreSQL for Xray](https://docs.jfrog.com/installation/docs/postgresql-for-xray)
- [JFrog Xray System YAML](https://jfrog.com/help/r/jfrog-installation-setup-documentation/xray-system-yaml)
- [Set up an Xray PostgreSQL Database in Single Node](https://jfrog.com/help/r/jfrog-installation-setup-documentation/set-up-an-xray-postgresql-database-in-single-node)
