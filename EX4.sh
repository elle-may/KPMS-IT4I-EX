#!/usr/bin/env Rscript
cd ~/KPMS-IT4I-EX
pwd

module purge
module load R
echo "loaded R"

install.package("randomForest")
install.package("parallel")


time Rscript EX4.r 4
