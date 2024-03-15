import importlib.resources as impr
import sys
import subprocess as sp

import dask_graham.commands as commands

def main(argv = sys.argv[1:]):
    script = impr.files(commands) / "riatools"
    try:
        sp.run([script] + argv, check=True)
    except sp.CalledProcessError as err:
        sys.exit(1)
