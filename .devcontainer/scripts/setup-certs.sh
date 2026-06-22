#!/bin/bash
# setup-certs.sh
# Importe les certificats entreprise dans le trust store Java et système.
#
# Usage (exécuté automatiquement au démarrage du container via postStartCommand) :
#   sudo /usr/local/bin/setup-certs.sh
#
# Les certificats doivent être montés dans /usr/local/share/ca-certificates/enterprise/
# au format PEM (.crt ou .pem) ou DER (.cer).

set -euo pipefail

CERT_DIR="/usr/local/share/ca-certificates/enterprise"
JAVA_CACERTS="$(readlink -f "$JAVA_HOME/lib/security/cacerts")"

if [ ! -d "$CERT_DIR" ] || [ -z "$(ls -A "$CERT_DIR" 2>/dev/null)" ]; then
    echo "[setup-certs] Aucun certificat trouvé dans $CERT_DIR, skip."
    exit 0
fi

echo "[setup-certs] Import des certificats depuis $CERT_DIR ..."

for cert in "$CERT_DIR"/*.{crt,pem,cer}; do
    [ -f "$cert" ] || continue
    alias=$(basename "$cert" | sed 's/\.[^.]*$//')
    echo "  → Import: $alias ($(basename "$cert"))"

    # Import dans le trust store Java (cacerts)
    keytool -importcert -noprompt \
        -keystore "$JAVA_CACERTS" \
        -storepass changeit \
        -alias "$alias" \
        -file "$cert" 2>/dev/null || echo "    (déjà présent ou erreur pour $alias)"

    # Copier dans le trust store système (Ubuntu/Debian)
    cp "$cert" /usr/local/share/ca-certificates/ 2>/dev/null || true
done

# Mettre à jour le trust store système
update-ca-certificates --fresh 2>/dev/null || true

echo "[setup-certs] Import terminé."
