#!/usr/bin/env bash
set -euo pipefail

# Provisioniert Admins und Teacher in lldap + ZFS.
# CSV-Format: uid,username,fullname,role  (role ∈ admin|teacher)
# Datasets unter tank/data/staff/<user>, NICHT auf homes-Pool.
# Initial-Passwort: 16 Zufallszeichen, wird auf stdout ausgegeben.

LLDAP="http://172.20.90.12:17170"
PASS="NgarumaVTC"
LDAP_URL="ldap://172.20.90.12:3890"
LDAP_DN="dc=ngarumavtc,dc=lan"
LDAP_ADMIN="uid=admin,ou=people,${LDAP_DN}"
GID=100
ZFS_BASE="tank/data/staff"
ADMIN_GROUP_ID=1
TEACHER_GROUP_ID=5
CSV="$(dirname "$(realpath "$0")")/staff.csv"

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

declare -A INITIAL_PW

while IFS=, read -r uid username fullname role; do
  [[ "$uid" == "uid" ]] && continue
  uid="${uid//\"/}"; username="${username//\"/}"; fullname="${fullname//\"/}"; role="${role//\"/}"
  home="${username}"; home_path="/staff/${home}"

  case "$role" in
    admin)   group_id="$ADMIN_GROUP_ID";   group_name="lldap_admin"   ;;
    teacher) group_id="$TEACHER_GROUP_ID"; group_name="lldap_teacher" ;;
    *) echo "  unbekannte Rolle '$role' fuer $username, skip" >&2; continue ;;
  esac

  echo "==> $username ($fullname, uid=$uid, $role)"

  # ZFS-Dataset
  if ! zfs list "${ZFS_BASE}/${home}" &>/dev/null; then
    zfs create "${ZFS_BASE}/${home}"
    echo "  ZFS: erstellt (${ZFS_BASE}/${home})"
  else
    echo "  ZFS: existiert bereits"
  fi
  chown "${uid}:${GID}" "${home_path}" && chmod 700 "${home_path}"
  echo "  Home: ${home_path} -> ${uid}:${GID} 700"

  # User anlegen via lldap GraphQL
  fn="${fullname%% *}"; ln="${fullname#* }"
  [ "$fn" = "$ln" ] && ln="$role"
  RESP=$(gql "{\"query\":\"mutation{createUser(user:{id:\\\"${username}\\\",email:\\\"${username}@ngarumavtc.lan\\\",displayName:\\\"${fullname}\\\",firstName:\\\"${fn}\\\",lastName:\\\"${ln}\\\"}){id}}\"}")
  if echo "$RESP" | grep -q '"id"'; then
    echo "  LDAP: angelegt"
    NEW_USER=1
  elif echo "$RESP" | grep -qi 'already\|exist\|duplicate\|unique'; then
    echo "  LDAP: existiert bereits"
    NEW_USER=0
  else
    echo "  LDAP FEHLER: $RESP" >&2
    continue
  fi

  # Posix-Attribute
  ATTR_RESP=$(gql "{\"query\":\"mutation{updateUser(user:{id:\\\"${username}\\\",insertAttributes:[{name:\\\"uidnumber\\\",value:[\\\"${uid}\\\"]},{name:\\\"gidnumber\\\",value:[\\\"${GID}\\\"]}]}){ok}}\"}")
  if echo "$ATTR_RESP" | grep -q '"ok":true'; then
    echo "  Posix-Attribute: OK"
  else
    echo "  Posix-Attribute WARNUNG: $ATTR_RESP" >&2
  fi

  # Gruppen-Zuordnung
  GROUP_RESP=$(gql "{\"query\":\"mutation{addUserToGroup(userId:\\\"${username}\\\",groupId:${group_id}){ok}}\"}")
  if echo "$GROUP_RESP" | grep -q '"ok":true'; then
    echo "  Gruppe ${group_name}: OK"
  elif echo "$GROUP_RESP" | grep -qi 'already'; then
    echo "  Gruppe ${group_name}: bereits Mitglied"
  else
    echo "  Gruppe WARNUNG: $GROUP_RESP" >&2
  fi

  # Initial-Passwort nur fuer neue User generieren
  if [ "$NEW_USER" = "1" ]; then
    INITIAL_PW["$username"]=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
  fi

done < "$CSV"

# Passwoerter setzen
if [ "${#INITIAL_PW[@]}" -gt 0 ]; then
  echo "==> Initial-Passwoerter setzen..."
  CMDS=""
  for u in "${!INITIAL_PW[@]}"; do
    CMDS+="ldappasswd -x -H '${LDAP_URL}' -D '${LDAP_ADMIN}' -w '${PASS}' -s '${INITIAL_PW[$u]}' 'uid=${u},ou=people,${LDAP_DN}' && echo '  ${u}: OK'; "
  done
  nix-shell -p openldap --run "$CMDS"

  echo
  echo "==> AUSDRUCKEN UND PERSOENLICH UEBERREICHEN:"
  echo "-------------------------------------------------"
  for u in "${!INITIAL_PW[@]}"; do
    printf "  %-12s  Initial-Passwort: %s\n" "$u" "${INITIAL_PW[$u]}"
  done
  echo "-------------------------------------------------"
fi

echo "Fertig."
