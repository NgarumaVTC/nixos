#!/usr/bin/env bash
set -euo pipefail

LLDAP="http://172.20.90.12:17170"
PASS="NgarumaVTC"
LDAP_URL="ldap://172.20.90.12:3890"
LDAP_DN="dc=ngarumavtc,dc=lan"
LDAP_ADMIN="uid=admin,ou=people,${LDAP_DN}"
GID=100
ZFS_BASE="tank/data/homes"
CSV="$(dirname "$(realpath "$0")")/students.csv"

TOKEN=$(curl -sf "${LLDAP}/auth/simple/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"admin\",\"password\":\"${PASS}\"}" \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
[ -z "$TOKEN" ] && { echo "lldap login fehlgeschlagen" >&2; exit 1; }

gql() {
  curl -sf "${LLDAP}/api/graphql" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$1"
}

LDAPPASSWD_USERS=()

while IFS=, read -r id nickname firstNames lastName sex trade entryDate; do
  [[ "$id" == "id" ]] && continue
  id="${id//\"/}"; nickname="${nickname//\"/}"; firstNames="${firstNames//\"/}"; lastName="${lastName//\"/}"
  uid=$((10000 + id)); username="student${uid}"; home="/home/${username}"

  echo "==> $username ($nickname $lastName, geboren als $firstNames)"

  # ZFS-Dataset + Home
  if ! zfs list "${ZFS_BASE}/${username}" &>/dev/null; then
    zfs create -o mountpoint="${home}" "${ZFS_BASE}/${username}"
    echo "  ZFS: erstellt"
  else
    echo "  ZFS: existiert bereits"
  fi
  chown "${uid}:${GID}" "${home}" && chmod 700 "${home}"
  echo "  Home: ${home} → ${uid}:${GID} 700"

  # User anlegen via lldap GraphQL
  RESP=$(gql "{\"query\":\"mutation{createUser(user:{id:\\\"${username}\\\",email:\\\"${username}@ngarumavtc.lan\\\",displayName:\\\"${nickname}\\\",firstName:\\\"${nickname}\\\",lastName:\\\"${lastName}\\\"}){id}}\"}")
  if echo "$RESP" | grep -q '"id"'; then
    echo "  LDAP: angelegt"
  elif echo "$RESP" | grep -qi 'already\|exist\|duplicate\|unique'; then
    echo "  LDAP: existiert bereits"
  else
    echo "  LDAP FEHLER: $RESP" >&2
    continue
  fi

  # Posix-Attribute (uidNumber / gidNumber)
  ATTR_RESP=$(gql "{\"query\":\"mutation{updateUser(user:{id:\\\"${username}\\\",insertAttributes:[{name:\\\"uidnumber\\\",value:[\\\"${uid}\\\"]},{name:\\\"gidnumber\\\",value:[\\\"${GID}\\\"]}]}){ok}}\"}")
  if echo "$ATTR_RESP" | grep -q '"ok":true'; then
    echo "  Posix-Attribute: OK"
  else
    echo "  Posix-Attribute WARNUNG: $ATTR_RESP" >&2
  fi

  LDAPPASSWD_USERS+=("$username")

done < "$CSV"

# Passwörter setzen — einmal nix-shell für alle User
if [ ${#LDAPPASSWD_USERS[@]} -gt 0 ]; then
  echo "==> Passwörter setzen..."
  CMDS=""
  for u in "${LDAPPASSWD_USERS[@]}"; do
    CMDS+="ldappasswd -x -H '${LDAP_URL}' -D '${LDAP_ADMIN}' -w '${PASS}' -s '${PASS}' 'uid=${u},ou=people,${LDAP_DN}' && echo '  ${u}: OK'; "
  done
  nix-shell -p openldap --run "$CMDS"
fi

echo "Fertig."
