# Réinstaller JFrog Xray 3.88 — cas d'une version Erlang système différente de la version embarquée

> **Contexte** : Xray 3.88 (nœud unique, RHEL 9.6, PostgreSQL externe déjà prête).
> Un Erlang est installé au niveau **système** dans une version différente de l'Erlang **embarqué** dans l'archive Xray. RabbitMQ (embarqué) refuse alors de démarrer et Xray ne redémarre plus.

**Principe directeur** : RabbitMQ est compilé et validé pour **une version précise d'Erlang**. Si un Erlang système incompatible est présent dans le `PATH`, il peut être chargé à la place du binaire fourni par JFrog → le broker plante au démarrage. La cible est donc simple : **faire en sorte que RabbitMQ utilise exactement l'Erlang du bundle Xray 3.88**, et qu'aucun Erlang système concurrent ne le supplante.

`$JFROG_HOME` = `/opt/jfrog/xray` (par défaut).

---

## Étape 0 — Diagnostic : confirmer le conflit de version

```bash
# Erlang vu dans le PATH système
which erl && erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

# Paquet(s) Erlang installés au niveau système (RPM)
rpm -qa | grep -i erlang

# Version Erlang fournie dans le bundle Xray 3.88
ls -l /opt/jfrog/xray/app/third-party/rabbitmq/
ls -l /opt/jfrog/xray/app/third-party/rabbitmq/erlang* 2>/dev/null

# État du broker (révèle souvent le crash Erlang)
cd /opt/jfrog/xray/app/third-party/rabbitmq/sbin && ./rabbitmqctl cluster_status
```

Signes d'un conflit : `which erl` pointe vers `/usr/bin/erl` (système) au lieu du binaire du bundle, ou un `rpm -qa | grep erlang` qui renvoie une version OTP plus récente que celle attendue par RabbitMQ. Erreur typique côté Xray : `connection refused, dial tcp 127.0.0.1:5672`.

> Xray 3.88 supporte globalement Erlang 19–27.x, mais le RabbitMQ **embarqué** n'est garanti qu'avec la version livrée dans `third-party/rabbitmq/`. C'est cette version-là qui fait foi.

---

## Étape 1 — Sauvegardes avant toute action

```bash
# Config + secrets (NE PAS perdre master.key / join.key)
mkdir -p /sauvegarde/xray-$(date +%F)
cp -a $JFROG_HOME/xray/var/etc /sauvegarde/xray-$(date +%F)/etc
cp $JFROG_HOME/xray/var/etc/system.yaml /sauvegarde/xray-$(date +%F)/

# Données RabbitMQ (seront vidées plus loin)
cp -a $JFROG_HOME/xray/var/data/rabbitmq/mnesia /sauvegarde/xray-$(date +%F)/mnesia.bak 2>/dev/null
```

Notez les paramètres de votre **PostgreSQL externe** (hôte, port 5432, base `xraydb`, utilisateur `xray`, mot de passe). La base n'est **pas** touchée par cette procédure.

---

## Étape 2 — Arrêter Xray et tuer tous les processus Erlang/RabbitMQ résiduels

Un RabbitMQ « zombie » lancé avec le mauvais Erlang empêche un redémarrage propre.

```bash
# Arrêter le service
systemctl stop xray.service

# Repérer et tuer les process résiduels
ps aux | grep -E "erl|epmd|rabbit|beam" | grep -v grep
# Pour chaque PID identifié :
#   kill -9 <PID>

# Vérifier qu'il ne reste rien
ps aux | grep -E "beam|epmd|rabbit" | grep -v grep
```

---

## Étape 3 — Résoudre le conflit Erlang

Choisissez **une** des deux options selon que l'Erlang système est nécessaire à d'autres applications.

### Option A (recommandée) — Aucune autre app n'a besoin d'Erlang : retirer l'Erlang système

```bash
# Désinstaller l'Erlang système conflictuel
rpm -qa | grep -i erlang          # lister les paquets exacts
yum remove erlang erlang-*        # adapter aux noms réels renvoyés ci-dessus

# Réinstaller UNIQUEMENT l'Erlang du bundle Xray 3.88 (paquets el9 pour RHEL 9.6)
cd /chemin/vers/jfrog-xray-3.88.x-rpm        # ou utilisez les RPM déjà présents sous app/third-party
rpm -ivh --replacepkgs ./third-party/rabbitmq/erlang-<version>.el9.x86_64.rpm
# socat est requis pour Xray < 3.109 :
rpm -ivh --replacepkgs ./third-party/rabbitmq/socat-<version>.el9.x86_64.rpm
```

Après réinstallation, revérifiez : `which erl` doit pointer vers la version du bundle, et `erl ... otp_release` doit afficher la version attendue par RabbitMQ.

### Option B — L'Erlang système doit rester : isoler RabbitMQ sur l'Erlang du bundle

Ici on ne supprime rien ; on force RabbitMQ à utiliser **son** Erlang plutôt que celui du système.

1. Localisez le binaire Erlang du bundle :
   ```bash
   ls -d /opt/jfrog/xray/app/third-party/rabbitmq/erlang*/bin 2>/dev/null
   ```
2. Dans le fichier d'environnement de Xray `JFROG_HOME/app/bin/xray.default`, faites pointer le `PATH`/`ERL_HOME` de RabbitMQ vers ce binaire **en premier**, par exemple :
   ```bash
   export ERL_HOME=/opt/jfrog/xray/app/third-party/rabbitmq/erlang-<version>
   export PATH=$ERL_HOME/bin:$PATH
   ```
3. Assurez-vous qu'aucun script d'init système (profil shell, `/etc/profile.d`) ne réinjecte l'Erlang système avant celui-ci pour l'utilisateur `xray`.

> L'Option A est plus simple et plus fiable. Ne choisissez l'Option B que si un autre logiciel dépend réellement de l'Erlang système.

---

## Étape 4 — Vérifier le cookie Erlang (cohérence obligatoire)

Une mauvaise version d'Erlang laisse souvent des cookies incohérents. Les `.erlang.cookie` doivent être **identiques** aux 3 emplacements, avec la valeur `JFXR_RABBITMQ_COOKIE` :

```bash
for f in /root/.erlang.cookie /opt/jfrog/xray/.erlang.cookie \
         /opt/jfrog/xray/app/third-party/rabbitmq/.erlang.cookie ; do
  echo "== $f =="; cat "$f" 2>/dev/null; echo
done
```

En cas de divergence, aligner les trois fichiers sur `JFXR_RABBITMQ_COOKIE`, puis dans `system.yaml` :

```yaml
shared:
  rabbitMq:
    erlangCookie:
      value: JFXR_RABBITMQ_COOKIE
```

---

## Étape 5 — Réinitialiser les tables Mnesia

Les tables écrites par une version d'Erlang incompatible peuvent être illisibles ; on repart propre (la base PostgreSQL n'est pas concernée).

```bash
# Xray doit être arrêté (Étape 2)
mv $JFROG_HOME/xray/var/data/rabbitmq/mnesia \
   $JFROG_HOME/xray/var/data/rabbitmq/mnesia.old-$(date +%F)
```

> ⚠️ Vider `mnesia` supprime files d'attente et exchanges RabbitMQ. Si une indexation était en cours, il faudra ré-indexer les artefacts concernés. Aucune donnée Xray (vulnérabilités, politiques) n'est perdue.

---

## Étape 6 — Vérifier la config PostgreSQL externe dans system.yaml

```yaml
shared:
  jfrogUrl: "http://<adresse-artifactory>:8082"
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: "postgres://<hote-pg>:5432/xraydb?sslmode=disable"   # verify-ca si TLS
    username: xray
    password: <mot_de_passe>
```

Rappel : l'extension **`pg_trgm`** est obligatoire depuis Xray 3.70.x sur une PostgreSQL externe :

```sql
-- connecté à xraydb
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

---

## Étape 7 — Démarrer et valider

```bash
systemctl start xray.service
systemctl status xray.service

# Suivre le démarrage
tail -f $JFROG_HOME/xray/var/log/console.log

# Confirmer que RabbitMQ tourne avec le bon Erlang
cd /opt/jfrog/xray/app/third-party/rabbitmq/sbin && ./rabbitmqctl status | grep -i -A2 erlang
```

Accès UI : `http://<jfrogUrl>/ui/` → **Administration → Xray**.

> Spécifique 3.8x : `stop`/`restart` de Xray n'agit plus sur RabbitMQ ; au `start`, Xray démarre RabbitMQ s'il est arrêté. Pour que le script gère aussi l'arrêt de RabbitMQ, mettez `shared.rabbitMq.autoStop: true` dans `system.yaml`.

---

## Récapitulatif express

| Étape | Action | Commande clé |
|---|---|---|
| 0 | Confirmer le conflit | `which erl` vs `ls third-party/rabbitmq/erlang*` |
| 1 | Sauvegarder | `cp -a var/etc`, `cp system.yaml` |
| 2 | Stopper + tuer process | `systemctl stop xray` ; `kill -9` des `beam/epmd/rabbit` |
| 3 | Aligner Erlang | A : `yum remove erlang` + RPM bundle ; B : `ERL_HOME` bundle |
| 4 | Cookie Erlang cohérent | 3 fichiers = `JFXR_RABBITMQ_COOKIE` |
| 5 | Reset Mnesia | `mv .../rabbitmq/mnesia mnesia.old` |
| 6 | PostgreSQL externe + pg_trgm | `system.yaml` + `CREATE EXTENSION pg_trgm` |
| 7 | Démarrer + valider | `systemctl start xray` ; `rabbitmqctl status` |

---

### Sources (documentation officielle JFrog)
- [Xray Single Node Manual RPM Installation](https://docs.jfrog.com/installation/docs/xray-single-node-manual-rpm-installation)
- [Database and Third-Party Applications in Xray (matrice Erlang/RabbitMQ)](https://docs.jfrog.com/installation/docs/database-and-third-party-applications-in-xray_xray-system-requirements-and-platform-support)
- [Troubleshoot RabbitMQ issues which prevents Xray startup](https://jfrog.com/help/r/xray-how-to-troubleshoot-rabbitmq-related-issues-which-prevents-xray-startup)
- [PostgreSQL for Xray](https://docs.jfrog.com/installation/docs/postgresql-for-xray)
