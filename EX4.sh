#!/bin/bash
#PBS -N rf
#PBS -l select=1:ncpus=128,walltime=00:05:00
#PBS -q qexp
#PBS -e rf.e
#PBS -o rf.o

cd ~/KPMS-IT4I-EX
pwd

module purge
module load R
echo "loaded R"

install.package("randomForest")
install.package("parallel")


time Rscript EX4.r 4
