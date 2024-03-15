#!/bin/bash

module load python/3.10
source $(kpy _kpy_wrapper)
kpy load $ENVNAME

deactivate