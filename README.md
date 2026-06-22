# Dev Container — Java 25 Enterprise

Environnement de développement conteneurisé avec Java 25, Maven, mvnd et les outils entreprise.  
Compatible **VS Code** (server mode) et **IntelliJ IDEA** (via JetBrains Gateway).

## Prérequis

| Outil | Version min. | Notes |
|-------|-------------|-------|
| [Podman](https://podman.io/) | 4.x+ | Rootless, remplace Docker |
| [VS Code](https://code.visualstudio.com/) | 1.90+ | Avec l'extension **Dev Containers** |
| [JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/) | 2024.1+ | Optionnel, pour IntelliJ |

## Contenu du container

- **Java 25** (Eclipse Temurin)
- **Maven 3.9.9** + **mvnd 1.0.2** (Maven Daemon)
- **OpenShift CLI** (`oc` + `kubectl`)
- **Git**, **SSH server**, outils courants (`curl`, `jq`, `wget`…)

## Démarrage rapide

### 1. Configurer Podman comme runtime

Dans les **VS Code User Settings** (`Cmd+,` / `Ctrl+,`) :

```json
"dev.containers.dockerPath": "podman"
```

### 2. Préparer les certificats entreprise

Créer le dossier sur la machine hôte et y placer vos certificats (`.crt`, `.pem`, `.cer`) :

```bash
# macOS / Linux
mkdir -p ~/certs-entreprise

# Windows (PowerShell)
mkdir "$env:USERPROFILE\certs-entreprise"
```

Les certificats seront automatiquement importés dans le trust store Java (`cacerts`) et système au démarrage du container.

### 3. Ouvrir le projet

**Option A — Depuis un dossier local :**

```
VS Code → Cmd+Shift+P → "Dev Containers: Reopen in Container"
```

**Option B — Clone in Volume (recommandé, meilleure perf macOS/Windows) :**

```
VS Code → Cmd+Shift+P → "Dev Containers: Clone Repository in Container Volume"
→ Coller l'URL du repo
```

Le repo est cloné une seule fois dans un volume Podman persistant. Pas de re-clone au démarrage suivant.

**Option C — Via la CLI `devcontainer` :**

```bash
# Installer le CLI si nécessaire
npm install -g @devcontainers/cli

# Lancer un container avec un nom unique (permet plusieurs projets en parallèle)
devcontainer up \
  --workspace-folder https://url-du-repo.git \
  --id-label devcontainer.name=mon-projet \
  --docker-path podman

# Exemples concrets :
devcontainer up \
  --workspace-folder https://dev.azure.com/org/project/_git/repo-sante \
  --id-label devcontainer.name=refcontrat-sante \
  --docker-path podman

devcontainer up \
  --workspace-folder https://dev.azure.com/org/project/_git/repo-prevoyance \
  --id-label devcontainer.name=refcontrat-prevoyance \
  --docker-path podman

# Lister les containers actifs
podman ps --filter label=devcontainer.name

# Se rattacher à un container existant
devcontainer up \
  --workspace-folder https://url-du-repo.git \
  --id-label devcontainer.name=mon-projet \
  --docker-path podman
# (réutilise le container existant s'il tourne déjà)

# Supprimer un container nommé
podman rm -f $(podman ps -aq --filter label=devcontainer.name=mon-projet)
```

> **Astuce** : le `--id-label devcontainer.name=<nom>` permet de nommer chaque container de manière unique. Vous pouvez ainsi avoir plusieurs projets qui tournent simultanément sans conflit.

## Utilisation avec IntelliJ (JetBrains Gateway)

1. Ouvrir **JetBrains Gateway**
2. **Dev Containers** → **New Dev Container**
3. Sélectionner le dossier du projet contenant ce `.devcontainer/`
4. Gateway utilise le même `devcontainer.json` et se connecte via SSH (port 22)

## Montages optionnels

Plusieurs bind mounts sont commentés dans `devcontainer.json`. Décommenter selon vos besoins :

| Mount | Usage |
|-------|-------|
| `~/.m2/settings.xml` | Settings Maven entreprise (miroirs, serveurs, proxies) |
| `~/.git-credentials` | Fichier de credentials Git (si vous n'utilisez pas GCM) |

> **Note** : le `~/.gitconfig` est monté par défaut (aliases, user.name, user.email…).

## Caches persistants

Les caches Maven et mvnd sont stockés dans des **volumes nommés** Podman, préfixés par le nom du dossier du projet :

- `<projet>-m2-repo` → `~/.m2/repository`
- `<projet>-mvnd-cache` → `~/.mvnd`

Ils survivent aux rebuilds du container. Pour les purger :

```bash
podman volume rm <projet>-m2-repo <projet>-mvnd-cache
```

## Commandes utiles dans le container

```bash
# Build avec Maven
mvn clean package

# Build avec mvnd (plus rapide, daemon résident)
mvnd clean package

# Vérifier les outils
java -version      # Java 25
mvn -version       # Maven 3.9.9
mvnd --version     # mvnd 1.0.2
oc version         # OpenShift CLI
kubectl version    # Kubernetes CLI
```

## Windows — Points d'attention

- **Podman Machine** doit être démarrée : `podman machine start`
- Les chemins hôte sont automatiquement traduits par Podman via WSL
- En cas de problème avec les bind mounts, vérifier que les dossiers source existent sur l'hôte (`%USERPROFILE%\certs-entreprise`, `%USERPROFILE%\.gitconfig`)

## Structure

```
.devcontainer/
├── devcontainer.json       # Configuration principale
├── Dockerfile              # Image custom (Java 25 + outils)
├── scripts/
│   └── setup-certs.sh      # Import auto des certificats entreprise
└── README.md               # Ce fichier
```
