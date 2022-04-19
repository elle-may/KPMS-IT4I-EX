library(parallel)
library(ggplot2)
library(pbdMPI)
source("../KPMS-IT4I-EX/mnist/mnist_read.R")
source("../KPMS-IT4I-EX/code/flexiblas_setup.r")

args <- commandArgs()
print(args)


blas_threads = as.numeric(commandArgs(TRUE)[2])
fork_cores = as.numeric(commandArgs(TRUE)[4])
setback("OPENBLAS")
setthreads(blas_threads)


