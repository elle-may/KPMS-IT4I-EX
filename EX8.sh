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

## --args blas fork
time mpirun -np 2 Rscript EX8.R