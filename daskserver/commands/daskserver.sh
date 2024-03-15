#!/bin/bash

set -e -u

# Get dir of the script
get_dir () {
  local SOURCE="${BASH_SOURCE[0]}"
  while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    local DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
    local SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  local DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  echo "$DIR"
}

function get () {
  echo $2 | cut -d' ' -f$1
}

function printHelp () {
  >&2 cat <<EOF
USAGE: daskserver VENV

Start a dask scheduler and array of workers on all available nodes using the provided
venv.
 
Args:
  VENV   name of the kpy-managed venv to run dask

EOF
}

parse_args () {
  local params=
  err () {
    echo "Error: Unsupported flag $1" >&2
    exit 1
  }
  while [[ -n "${1:-}" && ! "$1" == "--" ]]; do
    case "$1" in
      -h | --help )
        printHelp
        exit 0
        ;;
      -* | --* )
        ${PARSER:-err}
        ;;
      * )
        params="$params $1"
        ;;
    esac;
    shift;
  done
  if [[ "${1:-}" == '--' ]]; then shift; fi
  params="$params ${*}"
  echo "$params"
}

export bin="$(get_dir)"
export lib="$(dirname "$bin")/lib"
params="$(parse_args "$@")"

if [[ -z "$(get 1 "$params")" ]]; then
  printHelp
  exit 0
fi

example_salloc="salloc --nodes 2 --tasks-per-node=2 --mem=16000M --cpus-per-task=3 --time=0-01:00"
if [[ -z "${SLURM_JOB_ID:-}" ]]; then
  >&2 cat <<EOF 
daskserver must be run on a compute node. Start an interactive session first using a
command like the following:

  $example_salloc
EOF
  exit 1
fi

if [[ "$SLURM_NTASKS" -eq 1 ]]; then
  >&2 cat <<EOF

daskserver should typically be run with more than one task to take full advantage of
parallelization. Request multiple tasks with a command like the following:

  $example_salloc
EOF
fi

export DASK_SCHEDULER_ADDR="$(hostname)"
export DASK_SCHEDULER_PORT=34567
export ENVNAME="$(get 1 "$params")"

srun -N 2 -n 2 "$lib"/config_virtualenv.sh # set both -N and -n to the number of nodes


source $(kpy _kpy_wrapper)
set +eu
kpy activate $ENVNAME
set -eu

dask scheduler --host $DASK_SCHEDULER_ADDR --port $DASK_SCHEDULER_PORT &
sleep 5

srun $lib/launch_dask_workers.sh &
dask_cluster_pid=$!
sleep 5
echo "CLient address: tcp://$DASK_SCHEDULER_ADDR:$DASK_SCHEDULER_PORT"
echo "Dashboard address: http://$DASK_SCHEDULER_ADDR:8787"


