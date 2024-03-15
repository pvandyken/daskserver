#!/bin/bash

source $(kpy _kpy_wrapper)
kpy activate $ENVNAME

SCHEDULER_CONNECTION_STRING="tcp://$DASK_SCHEDULER_ADDR:$DASK_SCHEDULER_PORT"

if [[ "$SLURM_PROCID" -eq "0" ]]; then
## On the SLURM task with Rank 0, where the Dask scheduler process has already been launched, we launch a smaller worker,
## with 40% of the job's memory and we subtract one core from the task to leave it for the scheduler.
        DASK_WORKER_MEM=0.4
        DASK_WORKER_THREADS=$(($SLURM_CPUS_PER_TASK-1))

else
## On all other SLURM tasks, each worker gets half of the job's allocated memory and all the cores allocated to its task.
        DASK_WORKER_MEM=0.5
        DASK_WORKER_THREADS=$SLURM_CPUS_PER_TASK
fi

dask worker "tcp://$DASK_SCHEDULER_ADDR:$DASK_SCHEDULER_PORT" --no-dashboard --nworkers=1 \
--nthreads=$DASK_WORKER_THREADS --memory-limit=$DASK_WORKER_MEM --local-directory=$SLURM_TMPDIR

sleep 5
echo "dask worker started!"