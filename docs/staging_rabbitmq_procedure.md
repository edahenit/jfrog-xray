# Staging Xray 3.137 — remise en route mono-nœud et évolution cluster

## 1. Débloquer le mono-nœud maintenant

### 1.1 Repartir d'un system.yaml propre
Remplacez le `system.yaml` copié depuis la 3.88 par le fichier fourni (`system.yaml`), en adaptant les valeurs `<...>`. N'y réinjectez que : connexion PostgreSQL, `jfrogUrl`, `joinKey`.

### 1.2 Ne conserver que la master key de l'ancienne install
La master key est le seul élément réellement nécessaire pour déchiffrer les données de la base 3.88.

```bash
# Vérifier que la master key est présente et lisible
ls -l $JFROG_HOME/xray/var/etc/security/master.key
# Permissions attendues : 600, propriétaire xray
chown xray:xray $JFROG_HOME/xray/var/etc/security/master.key
chmod 600 $JFROG_HOME/xray/var/etc/security/master.key
```

### 1.3 Laisser RabbitMQ se régénérer
Si un état RabbitMQ incohérent a été introduit (cookie hérité sans mnesia correspondant), on repart propre :

```bash
# Arrêter Xray
systemctl stop xray.service   # ou ./xray.sh stop selon le mode d'installation

# Tuer d'éventuels process résiduels de l'utilisateur xray (port 25672 bloqué)
pkill -u xray beam.smp 2>/dev/null || true
pkill -u xray epmd 2>/dev/null || true

# Repartir d'un mnesia neuf (RabbitMQ le régénère au démarrage)
mv $JFROG_HOME/xray/var/data/rabbitmq/mnesia \
   $JFROG_HOME/xray/var/data/rabbitmq/mnesia.bak.$(date +%F) 2>/dev/null || true

# Redémarrer
systemctl start xray.service
```

### 1.4 Vérifier le démarrage
```bash
# Log RabbitMQ
tail -f $JFROG_HOME/xray/var/log/rabbitmq/*.log

# Statut du broker (toujours en tant qu'utilisateur xray)
sudo -u xray $JFROG_HOME/xray/app/third-party/rabbitmq/sbin/rabbitmqctl status
sudo -u xray $JFROG_HOME/xray/app/third-party/rabbitmq/sbin/rabbitmqctl cluster_status

# Log applicatif Xray
tail -f $JFROG_HOME/xray/var/log/xray-server.log
```

## 2. Diagnostic express si le démarrage échoue encore

```bash
grep -iE "BOOT FAILED|disabled_required_feature_flag|classic_mirrored|cookie|auth|mnesia|inconsistent|25672|erlang" \
  $JFROG_HOME/xray/var/log/rabbitmq/*.log | tail -20
```

| Message dans le log | Cause | Action |
|---|---|---|
| `Could not auth` / cookie | Cookie Erlang incohérent | Laisser régénérer (étape 1.3) |
| `inconsistent` / mnesia | État mnesia hérité | Purger mnesia (étape 1.3) |
| `25672` / port in use | Process RabbitMQ résiduel | Tuer les process (étape 1.3) |
| parsing / IP invalide | system.yaml hérité | Repartir du fichier propre (étape 1.1) |
| version Erlang/OTP | Package Erlang incomplet | Vérifier Erlang 26 sur le serveur |

Vérifier la version d'Erlang du serveur :
```bash
erl -version    # Xray 3.137 attend Erlang 26
```

## 3. Ajout du 2e nœud (plus tard, pour la HA)

> À ne faire qu'une fois le mono-nœud stable et validé.

### 3.1 Sur le 1er nœud — déclarer son identité
Ajouter au `system.yaml` :
```yaml
shared:
  rabbitMq:
    autoStop: true
    active:
      node:
        name: <hostname-court-noeud-1>
    erlangCookie:
      value: <COOKIE_PARTAGE>
    url: "amqp://localhost:5672/"
```

### 3.2 Sur le 2e nœud — rejoindre le cluster
- Copier **la même master key** que le nœud 1 dans `etc/security/master.key`.
- Utiliser **le même cookie Erlang** (`erlangCookie.value`).
- Pointer vers le nœud actif via `active.node.name` :
```yaml
shared:
  rabbitMq:
    autoStop: true
    active:
      node:
        name: <hostname-noeud-1>     # le nœud actif à rejoindre
    erlangCookie:
      value: <MEME_COOKIE_QUE_NOEUD_1>
    url: "amqp://localhost:5672/"
```

### 3.3 Exigences cluster à respecter
- **master.key identique** sur les deux nœuds (obligatoire).
- **Cookie Erlang identique** sur les deux nœuds (obligatoire pour l'authentification).
- **Même version** Xray (3.137) et **même version Erlang** (26) sur les deux nœuds.
- **Feature flags** activés sur chaque nœud après jonction :
  ```bash
  sudo -u xray $JFROG_HOME/xray/app/third-party/rabbitmq/sbin/rabbitmqctl enable_feature_flag all
  ```
- Résolution de hostname fonctionnelle entre les deux nœuds (short hostname par défaut ; activer le long hostname si FQDN requis).

### 3.4 Rappel architecture (production)
Sur un cluster à 2 nœuds avec Quorum Queues, il n'y a **aucune tolérance de panne** (« mode dégradé » selon JFrog). Pour une vraie HA, JFrog recommande **3 nœuds RabbitMQ dédiés en mode split**. Pour du staging, un mono-nœud ou un 2-nœuds de test reste acceptable si l'objectif est fonctionnel et non la résilience.

## 4. Points de vigilance

- Toujours exécuter `rabbitmqctl` en tant qu'utilisateur `xray` (sinon le cookie CLI ne correspond pas).
- Conserver la sauvegarde `mnesia.bak.*` jusqu'à validation complète.
- Ne pas copier tout le répertoire `var/` d'une ancienne install vers un serveur neuf : cela greffe cookie + mnesia + config obsolètes. Copier uniquement `master.key`.
