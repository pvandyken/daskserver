# daskserver

Utility to fire up a dask array on computecanada infrastructure. Works with kpy from [kslurm](https://github.com/pvandyken/kslurm) to manage python environments.

## Instructions

First, start up a job with multiple tasks. Don't use `krun` for this, as that only starts a job with one task. You want multiple to take full advantage of parallelism. The following command serves as a template, adapt the values to suit your needs:

```bash
salloc --nodes 2 --tasks-per-node=2 --mem=16000M --cpus-per-task=3 --time=0-01:00
```

Then run

```bash
daskserver <name of venv>
```

The venv must be one previously saved via `kpy`. It needs to have `dask` and `distributed` _already_ installed, otherwise this routine will fail. You also need `bokeh` if you want the dashboard. You can install both via:

```bash
pip install 'dask[distributed]' bokeh
```

The jupyter notebook or python script that will interact with the server should have the exact same venv installed as the dask server to avoid problems. For `kjupyter`, just use the same venv:

```bash
kjupyter --venv <same venv as dask>
```

Note that the server and workers will run in the background. You'll get control over the terminal back without killing them, but they'll continue to spit output onto the screen. To shut the server down, just exit the slurm job.

```bash
exit
```

## Installation

The app is set up to work with [pipx](https://pipx.pypa.io/latest/installation/):

```bash
pipx install git+https://github.com/pvandyken/daskserver
```
