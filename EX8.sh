#!/bin/bash
#PBS -N mnist_svd_cv
#PBS -l select=1:ncpus=128,walltime=00:50:00
#PBS -q qexp
#PBS -e EX8.e
#PBS -o EX8.o

cd ~/KPMS-IT4I-EX
pwd

module load R
echo "loaded R"

module swap libfabric/1.12.1-GCCcore-10.3.0 libfabric/1.13.2-GCCcore-11.2.0 

## --args blas fork
time mpirun --map-by ppr:1:node Rscript EX8.R