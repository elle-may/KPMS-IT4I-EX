#!/bin/bash
#PBS -N rf
#PBS -l select=1:ncpus=128,walltime=00:05:00
#PBS -q qexp
#PBS -e rf_cv_edit.e
#PBS -o rf_cv_edit.o

cd ~/KPMS-IT4I-EX
pwd

module purge
module load R
echo "loaded R"


time Rscript EX4_edit.R 64
