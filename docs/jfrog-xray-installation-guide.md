# JFrog Xray — Guide d'Installation et de Migration
**Repo** : https://github.com/edahenit/jfrog-xray  
**Version couverte** : Xray 3.88.x  
**Date** : Juin 2026

---

# Page 1 — Installation Xray Single Node (nœud unique)

## 1. Vue d'ensemble

JFrog Xray 3.x est une solution d'analyse de sécurité et de conformité qui s'intègre avec JFrog Artifactory.  
Cette page décrit l'installation d'Xray sur **un seul serveur (single node)**, la méthode la plus simple pour les environnements non critiques ou les tests.

---

## 2. Prérequis

### 2.1 Infrastructures requises avant l'installation

| Composant         | Version requise          | Remarque                                                  |
|-------------------|--------------------------|-----------------------------------------------------------|
| Artifactory       | 7.x                      | **Obligatoire** avant l'installation de Xray             |
| PostgreSQL        | 13, 14, 15, 16 ou 17     | Externe ou embarqué dans l'archive Xray                   |
| RabbitMQ          | 3.7 – 4.x                | **Inclus** dans l'archive Xray, pas besoin d'installation séparée |
| Erlang            | 25.0.3 (pour Xray 3.88)  | Bundled avec Xray — supprimer toute version système avant |
| OS supporté       | CentOS 7/8, RHEL 7/8, Debian 10/11, Ubuntu 18.04+ | —       |

> ⚠️ **Attention** : Xray utilise **RabbitMQ**, pas ActiveMQ. RabbitMQ est inclus dans l'archive d'installation.

### 2.2 Ressources minimales recommandées

| Ressource  | Minimum     | Recommandé  |
|------------|-------------|-------------|
| CPU        | 8 cœurs     | 16 cœurs    |
| RAM        | 16 Go       | 32 Go       |
| Disque     | 300 Go SSD  | 500 Go SSD  |

### 2.3 Ports à ouvrir

| Port  | Utilisation                          |
|-------|--------------------------------------|
| 8082  | Communication avec Artifactory / UI  |
| 8046  | Router microservice                  |
| 8047  | Router microservice                  |
| 8049  | Router microservice                  |
| 5672  | RabbitMQ AMQP                        |
| 15672 | RabbitMQ Management UI (optionnel)   |
| 5432  | PostgreSQL                           |

---

## 3. Préparer la base de données PostgreSQL

Avant d'installer Xray, créer une base de données et un utilisateur PostgreSQL dédié :

```sql
-- Se connecter en tant que postgres
CREATE USER xray_user WITH PASSWORD 'xray_password';
CREATE DATABASE xray_db OWNER xray_user;
GRANT ALL PRIVILEGES ON DATABASE xray_db TO xray_user;
```

---

## 4. Télécharger Xray 3.88

```bash
# Télécharger l'archive Linux
wget https://releases.jfrog.io/artifactory/xray-pro/3.x/jfrog-xray-3.88.4-linux.tar.gz
```

Ou depuis le portail JFrog : https://releases.jfrog.io/

---

## 5. Installation (Linux Archive)

### 5.1 Extraire et déplacer l'archive

```bash
export JFROG_HOME=/opt/jfrog
mkdir -p $JFROG_HOME
mv jfrog-xray-3.88.4-linux.tar.gz $JFROG_HOME/
cd $JFROG_HOME
tar -xf jfrog-xray-3.88.4-linux.tar.gz
mv jfrog-xray-3.88.4-linux xray
```

### 5.2 Installer Erlang bundled (important !)

> ⚠️ Supprimer d'abord toute version Erlang système pour éviter les conflits.

**RPM (CentOS/RHEL)** :

```bash
# Supprimer Erlang système
rpm -e --nodeps erlang

# Installer Erlang bundled
cd $JFROG_HOME/xray/app/third-party/rabbitmq
rpm -ivh erlang-25.0.3-1.el8.x86_64.rpm
```

**Debian/Ubuntu** :

```bash
# Supprimer Erlang système
dpkg --purge --force-all esl-erlang

# Installer Erlang bundled
cd $JFROG_HOME/xray/app/third-party/rabbitmq
dpkg -i esl-erlang_25.0.3-1_debian_buster_amd64.deb
```

### 5.3 Configurer system.yaml

Éditer le fichier `$JFROG_HOME/xray/var/etc/system.yaml` :

```yaml
shared:
  jfrogUrl: "http://<ARTIFACTORY_HOST>:8082"
  security:
    joinKey: "<YOUR_JOIN_KEY>"  # Depuis l'UI Artifactory > Administration > Security > Join Key
  database:
    driver: "org.postgresql.Driver"
    url: "postgres://xray_user:xray_password@<POSTGRES_HOST>:5432/xray_db"
    username: "xray_user"
    password: "xray_password"
  rabbitMq:
    erlangCookie: "XRAY_ERLANG_COOKIE"
```

> Le **joinKey** est disponible dans l'UI Artifactory :  
> **Administration → Security → Settings → Join Key**

### 5.4 Démarrer Xray

```bash
cd $JFROG_HOME/xray/app/bin
./xray.sh start
```

Ou avec systemd (RPM/Debian) :

```bash
sudo systemctl start xray.service
sudo systemctl enable xray.service
```

### 5.5 Vérifier le démarrage

```bash
# Logs console
tail -f $JFROG_HOME/xray/var/log/console.log

# Vérifier le statut du service
$JFROG_HOME/xray/app/bin/xray.sh status

# Vérifier la connexion à Artifactory
curl -u admin:password http://<ARTIFACTORY_HOST>:8082/xray/api/v1/system/ping
```

---

## 6. Résolution des problèmes courants

### 6.1 Problème de compatibilité Erlang

Si Xray ne démarre pas avec une erreur Erlang :

```bash
# 1. Arrêter Xray
cd $JFROG_HOME/xray/app/bin && ./xray.sh stop

# 2. Supprimer Erlang système
rpm -e --nodeps erlang  # ou dpkg --purge --force-all esl-erlang

# 3. Supprimer le cache Mnesia de RabbitMQ
rm -rf $JFROG_HOME/xray/var/data/rabbitmq/mnesia/

# 4. Installer Erlang bundled
cd $JFROG_HOME/xray/app/third-party/rabbitmq
rpm -ivh erlang-*.rpm  # ou dpkg -i esl-erlang_*.deb

# 5. Redémarrer Xray
cd $JFROG_HOME/xray/app/bin && ./xray.sh start
```

### 6.2 RabbitMQ ne démarre pas (Feature Flags manquants)

Pour les upgrades depuis une version < 3.70 :

```bash
# Activer les feature flags RabbitMQ
$JFROG_HOME/xray/app/third-party/rabbitmq/sbin/rabbitmqctl enable_feature_flag all
```

### 6.3 Xray ne se connecte pas à PostgreSQL

Vérifier `system.yaml` :

```bash
cat $JFROG_HOME/xray/var/etc/system.yaml | grep -A5 database
```

Vérifier la connectivité :

```bash
psql -h <POSTGRES_HOST> -U xray_user -d xray_db -c "SELECT version();"
```

---

## 7. Migration PostgreSQL 13 → 15 pour Xray

> ⚠️ **Xray doit être arrêté avant de migrer la base de données.**

### Procédure :

```bash
# 1. Arrêter Xray
cd $JFROG_HOME/xray/app/bin && ./xray.sh stop

# 2. Backup PostgreSQL 13
pg_dumpall -h <PG13_HOST> -U postgres > /backup/pg13_backup.sql
# ou pour une seule base
pg_dump -h <PG13_HOST> -U xray_user -d xray_db > /backup/xray_db_dump.sql

# 3. Installer PostgreSQL 15 sur le nouveau serveur
# (suivre la documentation PostgreSQL officielle)

# 4. Créer la base cible
psql -h <PG15_HOST> -U postgres -c "CREATE USER xray_user WITH PASSWORD 'xray_password';"
psql -h <PG15_HOST> -U postgres -c "CREATE DATABASE xray_db OWNER xray_user;"

# 5. Restaurer les données
psql -h <PG15_HOST> -U xray_user -d xray_db < /backup/xray_db_dump.sql

# 6. Modifier system.yaml pour pointer vers PostgreSQL 15
sed -i 's/<PG13_HOST>/<PG15_HOST>/g' $JFROG_HOME/xray/var/etc/system.yaml

# 7. Redémarrer Xray
cd $JFROG_HOME/xray/app/bin && ./xray.sh start
```

---

---

# Page 2 — Installation Xray en Cluster (Haute Disponibilité)

## 1. Vue d'ensemble

Une installation **Xray HA (High Availability)** répartit les microservices Xray sur **plusieurs nœuds** pour garantir la continuité de service.  
Les composants partagés (PostgreSQL, RabbitMQ) sont isolés sur des serveurs dédiés.

---

## 2. Architecture recommandée

```
┌─────────────────────────────────────────────────┐
│             LOAD BALANCER / REVERSE PROXY        │
│              (HAProxy, Nginx, F5…)               │
└──────────────┬──────────────┬────────────────────┘
               │              │
     ┌─────────┴──┐    ┌──────┴─────┐
     │  Xray      │    │  Xray      │   (+ Xray Node 3...)
     │  Node 1    │    │  Node 2    │
     └─────┬──────┘    └──────┬─────┘
           │                  │
    ┌──────┴──────────────────┴──────┐
    │         COMPOSANTS PARTAGÉS    │
    │                                │
    │  ┌──────────┐  ┌────────────┐  │
    │  │PostgreSQL│  │  RabbitMQ  │  │
    │  │ Cluster  │  │  Cluster   │  │
    │  │(Primary+ │  │ (3 Nodes)  │  │
    │  │ Standby) │  │            │  │
    │  └──────────┘  └────────────┘  │
    └────────────────────────────────┘
               │
     ┌─────────┴──────────┐
     │  JFrog Artifactory │
     │  7.x (HA ou single)│
     └────────────────────┘
```

---

## 3. Prérequis cluster

### 3.1 Nombre de serveurs recommandés

| Rôle               | Nb nœuds | Configuration minimale       |
|--------------------|----------|------------------------------|
| Xray App Nodes     | 2–3      | 8 CPU, 16 Go RAM, 300 Go SSD |
| PostgreSQL         | 2        | Primary + Standby (streaming replication) |
| RabbitMQ           | 3        | 4 CPU, 8 Go RAM, 100 Go SSD  |
| Load Balancer      | 1        | HAProxy / Nginx               |

### 3.2 Ports supplémentaires (cluster)

| Port          | Utilisation                                    |
|---------------|------------------------------------------------|
| 35672–35682   | RabbitMQ inter-nœuds (Xray 3.124.x+)          |
| 4369          | Erlang Port Mapper Daemon (EPMD) pour RabbitMQ |
| 25672         | RabbitMQ inter-nœuds (communication cluster)   |
| 5432          | PostgreSQL                                     |

---

## 4. Étape 1 — Installer et configurer PostgreSQL HA

### 4.1 Sur le serveur PostgreSQL Primary

```bash
# Installer PostgreSQL 15
sudo yum install -y postgresql15-server  # RPM
sudo apt-get install -y postgresql-15    # Debian

# Initialiser le cluster
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb

# Configurer postgresql.conf
sudo vim /var/lib/pgsql/15/data/postgresql.conf
```

```ini
listen_addresses = '*'
wal_level = replica
max_wal_senders = 5
max_replication_slots = 5
hot_standby = on
```

```bash
# Créer la base Xray
sudo -u postgres psql -c "CREATE USER xray_user WITH PASSWORD 'xray_password';"
sudo -u postgres psql -c "CREATE DATABASE xray_db OWNER xray_user;"

# Démarrer PostgreSQL
sudo systemctl start postgresql-15
sudo systemctl enable postgresql-15
```

---

## 5. Étape 2 — Installer et configurer le cluster RabbitMQ

> ⚠️ RabbitMQ est inclus dans l'archive Xray — mais pour HA, JFrog recommande de déployer un **cluster RabbitMQ dédié (split mode)**, séparé des nœuds Xray.

### 5.1 Cookie Erlang identique sur tous les nœuds RabbitMQ

```bash
echo "XRAY_ERLANG_COOKIE" > /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
```

### 5.2 Former le cluster (depuis nœuds 2 et 3)

```bash
sudo rabbitmqctl stop_app
sudo rabbitmqctl reset
sudo rabbitmqctl join_cluster rabbit@<RABBITMQ_NODE1_HOSTNAME>
sudo rabbitmqctl start_app

# Vérifier le cluster
sudo rabbitmqctl cluster_status
```

### 5.3 Activer les Quorum Queues (obligatoire pour RabbitMQ 4.x)

```bash
sudo rabbitmqctl enable_feature_flag quorum_queue
sudo rabbitmqctl enable_feature_flag all
```

---

## 6. Étape 3 — Installer Xray sur chaque nœud applicatif

### 6.1 Extraire l'archive (sur chaque nœud Xray)

```bash
export JFROG_HOME=/opt/jfrog
mkdir -p $JFROG_HOME
cd $JFROG_HOME
tar -xf jfrog-xray-3.88.4-linux.tar.gz
mv jfrog-xray-3.88.4-linux xray
```

### 6.2 Installer Erlang bundled

```bash
rpm -e --nodeps erlang
cd $JFROG_HOME/xray/app/third-party/rabbitmq
rpm -ivh erlang-25.0.3-1.el8.x86_64.rpm
```

### 6.3 Configurer system.yaml (sur chaque nœud Xray)

```yaml
shared:
  jfrogUrl: "http://<ARTIFACTORY_HOST>:8082"
  security:
    joinKey: "<YOUR_JOIN_KEY>"
  database:
    driver: "org.postgresql.Driver"
    url: "postgres://xray_user:xray_password@<PG15_PRIMARY>:5432/xray_db"
    username: "xray_user"
    password: "xray_password"
  rabbitMq:
    url: "<RABBITMQ_NODE1>:5672,<RABBITMQ_NODE2>:5672,<RABBITMQ_NODE3>:5672"
    username: "guest"
    password: "guest"
    erlangCookie: "XRAY_ERLANG_COOKIE"

node:
  name: "xray-node-1"   # xray-node-2 sur le 2e nœud, etc.
```

### 6.4 Démarrer Xray séquentiellement

```bash
# Nœud 1 en premier
cd $JFROG_HOME/xray/app/bin && ./xray.sh start

# Vérifier qu'il est healthy avant de continuer
tail -f $JFROG_HOME/xray/var/log/console.log

# Puis Nœud 2, puis Nœud 3
```

---

## 7. Étape 4 — Configurer le Load Balancer (HAProxy)

```
frontend xray_frontend
    bind *:8082
    default_backend xray_backend

backend xray_backend
    balance roundrobin
    option httpchk GET /xray/api/v1/system/ping
    server xray1 <XRAY_NODE1_IP>:8082 check
    server xray2 <XRAY_NODE2_IP>:8082 check
    server xray3 <XRAY_NODE3_IP>:8082 check
```

---

## 8. Vérification du cluster

```bash
# Statut RabbitMQ cluster
rabbitmqctl cluster_status

# Health check Xray via Load Balancer
curl http://<LB_HOST>:8082/xray/api/v1/system/ping

# Logs de chaque nœud
tail -f $JFROG_HOME/xray/var/log/console.log
```

---

## 9. Rolling upgrade du cluster Xray

Pour une mise à jour sans interruption de service :

1. **Arrêter un nœud Xray** (pas les autres).
2. **Mettre à jour Xray** sur ce nœud (remplacer `app/`).
3. **Redémarrer** ce nœud, vérifier qu'il est healthy.
4. **Répéter** pour chaque nœud.

```bash
# Sur chaque nœud, séquentiellement :
cd $JFROG_HOME/xray/app/bin && ./xray.sh stop

export JF_NEW_VERSION=$JFROG_HOME/jfrog-xray-3.124.11-linux
rm -rf $JFROG_HOME/xray/app
cp -fr $JF_NEW_VERSION/app $JFROG_HOME/xray/
rm -rf $JF_NEW_VERSION

cd $JFROG_HOME/xray/app/bin && ./xray.sh start
```

---

## 10. Tableau de surveillance

| Commande | Utilisation |
|----------|-------------|
| `rabbitmqctl cluster_status` | Statut du cluster RabbitMQ |
| `rabbitmqctl list_queues` | File d'attente des messages |
| `psql -c "SELECT * FROM pg_stat_replication"` | Réplication PostgreSQL |
| `tail -f $JFROG_HOME/xray/var/log/xray.log` | Logs applicatifs Xray |
| `curl .../xray/api/v1/system/ping` | Health check Xray |

---

*Document généré pour le repo [edahenit/jfrog-xray](https://github.com/edahenit/jfrog-xray)*  
*Basé sur la documentation officielle JFrog : https://docs.jfrog.com/installation/docs/installing-xray*
