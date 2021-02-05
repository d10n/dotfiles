#!/bin/bash

usage() {
  exe="$(basename "$0")"
  [[ -z "$1" ]] && cmd=(cat) || cmd=(awk -v "error=$1" '/^Usage:$/{p=1} p{print} p&&/^$/{print error;exit}')
  "${cmd[@]}" <<EOF
$exe: Program description.

Usage:
  $exe [-h|--help]
  $exe [-v|--verbose] --flag=<flag>

Options:
  -h --help       Show this information
  --flag=<flag>   Set flag; must not be set twice
  -v --verbose    Show >=debug output
  -vv --log-trace Show >=trace output
  --log-warn      Show >=warn output
  --log-error     Show only error output
  -q --quiet      Show no output
EOF
}
[[ "$#" -eq 0 ]] && set -- --help

# parameters
params=""
params_array=()
#flag=
#log_level= # 3:error, 4:warn, 5:info, 6:debug, 7:trace
#quiet=

# parse arguments
while (( "$#" )); do
  arg="$1"
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    -v|--verbose|--log-debug)
      log_level=6
      shift
      ;;
    -vv|--log-trace)
      log_level=7
      shift
      ;;
    --log-warn)
      log_level=4
      shift
      ;;
    --log-error)
      log_level=3
      shift
      ;;
    -q|--quiet)
      quiet=1
      shift
      ;;
    --flag|--flag=*)
      [[ -n "${flag+1}" ]] && { usage >&2 'Error: flag already set'; exit 1; }
      if [[ "$1" = "--flag" ]]; then
        flag="$2"
        shift 2 || { usage >&2 'Error: flag value required'; exit 1; }
      else
        flag="${1#*=}"
        shift
      fi
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -[hvf]*)
      TODO
      shift
      ;;
    -*) # unsupported flags
      usage >&2
      printf >&2 '\nError: Unsupported flag %s\n' "$1"
      exit 1
      ;;
    *) # preserve positional arguments
      params="$params $1"
      params_array+=("$1")
      shift
      ;;
  esac
done # set positional arguments in their proper place
eval set -- "$params"

# required
[[ -n "${flag+1}" ]] || { usage >&2 'Error: --flag is required'; exit 1; }

# defaults
quiet="${quiet:-0}"
log_level="${log_level:-5}"

# log:
# exec &> >(tee -a ~/example-template-script.log)

set -euo pipefail

main() {
  printf 'flag: %q\n' "$flag"
  info 'starting'
  act >&1 echo 1
  act >&2 echo 2
}

act() {
  trace "$(printf '%q ' "$@")"
  "$@"
}

error() { printf >&3 '[error] %s\n' "$*"; }
warn() { printf >&4 '[warn] %s\n' "$*"; }
info() { printf >&5 '[info] %s\n' "$*"; }
debug() { printf >&6 '[debug] %s\n' "$*"; }
trace() { printf >&7 '[trace] %s\n' "$*"; }

[[ "$log_level" -lt 5 ]] || [[ "$quiet" -eq 1 ]] || exec 5>&1
for log_level_fd in 3 4 6 7; do
  if [[ "$log_level" -lt "$log_level_fd" ]] || [[ "$quiet" -eq 1 ]]; then
    eval "exec $log_level_fd>/dev/null"
  else
    eval "exec $log_level_fd>&1" # >&2
  fi
done

main "$@"
