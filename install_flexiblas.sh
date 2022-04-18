#!/bin/bash
#PBS -N mnist_svd_cv
#PBS -l select=1:ncpus=128,walltime=00:50:00
#PBS -q qexp
#PBS -e install.e
#PBS -o install.o

cd ~/KPMS-IT4I-EX
pwd

module load R
echo "loaded R"

## --args blas fork
time Rscript install_flexiblas.R --args 4 32