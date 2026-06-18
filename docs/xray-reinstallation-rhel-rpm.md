# Guide de Réinstallation JFrog Xray 3.88 sur RHEL (Package RPM)

**Version Xray** : 3.88.x  
**OS** : Red Hat Enterprise Linux (RHEL 7/8/9)  
**Méthode** : Package RPM + systemctl  
**Date** : Juin 2026

---

## Prérequis avant de commencer

| Élément | Requis |
|---|---|
| Artifactory 7.x | ✅ Doit être démarré et accessible |
| PostgreSQL 13-15 | ✅ Base `xray_db` + user `xray_user` existants |
| Package RPM Xray 3.88 | ✅ Disponible sur le serveur |
| Accès root ou sudo | ✅ Obligatoire |
| joinKey Artifactory | ✅ Disponible dans Administration → Security → Join Key |

---

## Étape 1 — Arrêter le service Xray

```bash
# Arrêter via systemctl
sudo systemctl stop xray.service

# Vérifier que le service est bien arrêté
sudo systemctl status xray.service
# Résultat attendu : "inactive (dead)"
```

---

## Étape 2 — Tuer les processus résiduels

```bash
# Tuer tous les processus liés à Xray, RabbitMQ et Erlang
pkill -u xray -9
pkill -f rabbitmq -9
pkill -f erl -9

# Vérifier qu'aucun processus ne reste
ps aux | grep -E "xray|rabbit|erl" | grep -v grep
# Résultat attendu : aucune ligne
```

---

## Étape 3 — Sauvegarder la configuration

```bash
# Sauvegarder system.yaml (contient DB, joinKey, URL Artifactory)
export JFROG_HOME=/opt/jfrog
cp $JFROG_HOME/xray/var/etc/system.yaml /tmp/system.yaml.bak

# Vérifier la sauvegarde
cat /tmp/system.yaml.bak
```

> ⚠️ **Ne pas sauter cette étape** — le RPM peut écraser `system.yaml` lors de la réinstallation.

---

## Étape 4 — Supprimer l'Erlang système

```bash
# Vérifier si Erlang système est installé
rpm -q erlang
rpm -qa | grep -i erlang

# Supprimer si présent (forcer sans vérification des dépendances)
sudo rpm -e --nodeps erlang

# Vérifier la suppression
rpm -q erlang
# Résultat attendu : "package erlang is not installed"
erl -version
# Résultat attendu : "command not found"
```

> ⚠️ **Cause principale du problème de démarrage** : un Erlang système en conflit avec l'Erlang bundled de Xray empêche RabbitMQ de démarrer silencieusement.

---

## Étape 5 — Nettoyer les données RabbitMQ (Mnesia)

```bash
# Supprimer le cache Mnesia (données RabbitMQ corrompues)
rm -rf $JFROG_HOME/xray/var/data/rabbitmq/mnesia/

# Vérifier la suppression
ls $JFROG_HOME/xray/var/data/rabbitmq/
```

> ⚠️ **Obligatoire** — sans ce nettoyage, RabbitMQ refuse de redémarrer même avec le bon Erlang.

---

## Étape 6 — Désinstaller l'ancien package RPM Xray

```bash
# Voir le nom exact du package installé
rpm -qa | grep -i xray

# Désinstaller
sudo rpm -e jfrog-xray
# ou avec yum
sudo yum remove jfrog-xray -y

# Vérifier la désinstallation
rpm -q jfrog-xray
# Résultat attendu : "package jfrog-xray is not installed"
```

---

## Étape 7 — Nettoyer les logs

```bash
# Supprimer les anciens logs pour repartir proprement
rm -rf $JFROG_HOME/xray/var/log/*

# Vérifier
ls $JFROG_HOME/xray/var/log/
```

---

## Étape 8 — Vérifier les ports libres

```bash
# Tous les ports Xray/RabbitMQ doivent être libres
ss -tlnp | grep -E "8082|8046|8047|8049|5672|4369|25672"
# Résultat attendu : aucune ligne
```

Si un port est occupé :
```bash
# Trouver quel processus occupe le port (ex: 5672)
sudo fuser 5672/tcp
sudo kill -9 <PID>
```

---

## Étape 9 — Installer le package RPM Xray 3.88

```bash
# Vérifier le nom du fichier RPM
ls -lh jfrog-xray-*.rpm

# Installer avec yum (gère les dépendances)
sudo yum localinstall jfrog-xray-3.88.4-linux.x86_64.rpm -y
# ou directement avec rpm
sudo rpm -ivh jfrog-xray-3.88.4-linux.x86_64.rpm

# Vérifier l'installation
rpm -q jfrog-xray
```

---

## Étape 10 — Installer l'Erlang bundled APRÈS le RPM

> ⚠️ **Critique** — cette étape doit être faite APRÈS l'installation du RPM et AVANT le démarrage du service.

```bash
# Aller dans le répertoire Erlang bundled
cd $JFROG_HOME/xray/app/third-party/rabbitmq

# Lister les packages disponibles
ls -lh erlang-*.rpm

# Installer l'Erlang bundled
sudo rpm -ivh erlang-*.rpm

# Vérifier la version installée
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell
# Résultat attendu pour Xray 3.88 : "25"

# Vérifier via RPM
rpm -q erlang
# Résultat attendu : "erlang-25.0.3-1.el8"
```

---

## Étape 11 — Restaurer system.yaml

```bash
# Vérifier si system.yaml existe encore
cat $JFROG_HOME/xray/var/etc/system.yaml

# Si écrasé par le RPM, restaurer le backup
cp /tmp/system.yaml.bak $JFROG_HOME/xray/var/etc/system.yaml
```

Contenu minimum requis dans `system.yaml` :

```yaml
shared:
  jfrogUrl: "http://<ARTIFACTORY_HOST>:8082"
  security:
    joinKey: "<YOUR_JOIN_KEY>"
  database:
    driver: "org.postgresql.Driver"
    url: "postgres://xray_user:xray_password@<POSTGRES_HOST>:5432/xray_db"
    username: "xray_user"
    password: "xray_password"
  rabbitMq:
    erlangCookie: "XRAY_ERLANG_COOKIE"
```

Valider la syntaxe YAML :
```bash
python3 -c "import yaml; yaml.safe_load(open('$JFROG_HOME/xray/var/etc/system.yaml'))" && echo "✅ YAML OK"
```

> 💡 Le **joinKey** est disponible dans Artifactory : **Administration → Security → Settings → Join Key**

---

## Étape 12 — Vérifier les permissions

```bash
# L'utilisateur xray doit posséder tout le répertoire
sudo chown -R xray:xray $JFROG_HOME/xray/

# Vérifier
ls -lh $JFROG_HOME/
# Résultat attendu : xray xray ... xray/
```

---

## Étape 13 — Recharger systemd et démarrer Xray

```bash
# OBLIGATOIRE après réinstallation RPM
sudo systemctl daemon-reload

# Activer le service au démarrage
sudo systemctl enable xray.service

# Démarrer le service
sudo systemctl start xray.service
```

---

## Étape 14 — Surveiller le démarrage

Ouvrir **2 terminaux** :

**Terminal 1 — journalctl systemd :**
```bash
sudo journalctl -u xray.service -f
```

**Terminal 2 — logs console Xray :**
```bash
tail -f $JFROG_HOME/xray/var/log/console.log
```

**Terminal 3 (optionnel) — logs RabbitMQ :**
```bash
tail -f $JFROG_HOME/xray/var/log/rabbitmq/rabbit@$(hostname).log
```

---

## Étape 15 — Valider le démarrage

```bash
# Statut systemd
sudo systemctl status xray.service
# Résultat attendu : "active (running)"

# Health check API Xray
curl http://<ARTIFACTORY_HOST>:8082/xray/api/v1/system/ping
# Résultat attendu : {"status":"ok"}
```

---

## Résumé des étapes

| # | Étape | Commande clé | Critique |
|---|---|---|---|
| 1 | Arrêter Xray | `systemctl stop xray.service` | ✅ |
| 2 | Tuer processus résiduels | `pkill -u xray -9` | ✅ |
| 3 | Sauvegarder system.yaml | `cp system.yaml /tmp/` | ✅ |
| 4 | Supprimer Erlang système | `rpm -e --nodeps erlang` | ⚠️ Critique |
| 5 | Nettoyer Mnesia RabbitMQ | `rm -rf .../mnesia/` | ⚠️ Critique |
| 6 | Désinstaller ancien RPM Xray | `yum remove jfrog-xray` | ✅ |
| 7 | Nettoyer les logs | `rm -rf .../log/*` | 🔵 Optionnel |
| 8 | Vérifier ports libres | `ss -tlnp \| grep 5672` | ✅ |
| 9 | Installer nouveau RPM Xray | `yum localinstall jfrog-xray-3.88.4.rpm` | ✅ |
| 10 | Installer Erlang bundled | `rpm -ivh erlang-*.rpm` | ⚠️ Critique |
| 11 | Restaurer system.yaml | `cp /tmp/system.yaml.bak ...` | ✅ |
| 12 | Vérifier permissions | `chown -R xray:xray ...` | ✅ |
| 13 | daemon-reload + start | `systemctl daemon-reload && systemctl start xray` | ✅ |
| 14 | Surveiller logs | `tail -f console.log` | ✅ |
| 15 | Health check | `curl .../system/ping` | ✅ |

---

## Problèmes fréquents après réinstallation

### Service démarre mais Xray ne répond pas
```bash
# Vérifier la connexion à Artifactory
curl http://<ARTIFACTORY_HOST>:8082/artifactory/api/system/ping

# Vérifier le joinKey dans system.yaml
grep joinKey $JFROG_HOME/xray/var/etc/system.yaml
```

### RabbitMQ ne démarre pas
```bash
# Vérifier la version Erlang
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

# Nettoyer Mnesia
rm -rf $JFROG_HOME/xray/var/data/rabbitmq/mnesia/
```

### Erreur de connexion PostgreSQL
```bash
# Tester la connexion manuellement
psql -h <POSTGRES_HOST> -U xray_user -d xray_db -c "SELECT version();"
```

### Port déjà utilisé
```bash
sudo fuser -k 5672/tcp
sudo fuser -k 8082/tcp
```

---

## Références

- [Documentation officielle JFrog — Installation Xray](https://docs.jfrog.com/installation/docs/installing-xray)
- [JFrog — Troubleshooting Erlang Issues](https://jfrog.com/help/r/xray-troubleshooting-erlang-issues-during-xray-server-upgrades)
- [JFrog — Xray Install/Upgrade Troubleshooting](https://docs.jfrog.com/installation/docs/xray-installupgrade-troubleshooting)
- [Guide interne — Installation Xray Single Node et Cluster HA](./jfrog-xray-installation-guide.md)

---

*Document généré pour le repo [edahenit/jfrog-xray](https://github.com/edahenit/jfrog-xray)*
