#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") <up|down> [-- <extra docker-compose args>]

Examples:
  # Bring all stacks up (detached)
  ./manage.sh up

  # Tear all stacks down
  ./manage.sh down

  # Tear all down AND remove volumes
  ./manage.sh down -- -v

  # Bring all up with build
  ./manage.sh up -- --build
EOF
  exit 1
}

# must supply up or down
if [[ $# -lt 1 ]]; then usage; fi
action=$1; shift
if [[ "$action" != "up" && "$action" != "down" ]]; then usage; fi

# any remaining args after “--” go to docker compose
extra=()
if [[ $# -ge 1 ]]; then
  # allow: manage.sh up -- --build
  if [[ $1 == "--" ]]; then
    shift
    extra=( "$@" )
  else
    extra=( "$@" )
  fi
fi

# loop through all subdirs with docker-compose.yml
for dir in */; do
  if [[ -f "$dir/docker-compose.yml" ]]; then
    echo "⏬ ${action^} in ${dir%/}…"
    (
      cd "$dir"
      if [[ "$action" == "up" ]]; then
        docker compose up -d "${extra[@]}"
      else
        docker compose down "${extra[@]}"
      fi
    )
  fi
done
