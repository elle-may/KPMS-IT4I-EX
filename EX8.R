#' svdmod
#' 
#' Computes SVD for each image label in training data
#' Returns SVDs truncated to either k components or percent variability
#' 
svdmod = function(data, labels, k = NULL, pct = NULL, plots = FALSE) {
  ## trains svd model for each label
  
  if(is.null(k) & is.null(pct)) 
    stop("svdmod: At least one of k and pct must be provided")
  
  ulabels = unique(labels)
  models = setNames(vector("list", length(ulabels)), ulabels)
  
  ## train on each label data
  for(label in ulabels) {
    labdat = unname(as.matrix(data[labels == label, ]))
    udv = La.svd(labdat)
    
    if(!is.null(k)) { # k components
      ik = 1:k
    } else { # pct variability
      cvar = cumsum(udv$d^2)
      ik = 1:(which(100*cvar/cvar[length(cvar)] >= pct))[1]
    }
    mod = list(d = udv$d[ik], u = udv$u[, ik], vt = udv$vt[ik, ], 
               k = length(ik), pct = 100*sum(udv$d[ik]^2)/sum(udv$d^2))
    models[[label]] = mod
  }
  if(plots) lapply(models, function(x) plot(1:length(x$d), cumsum(x$d^2)))
  models
}

#' predict_svdmod
#' 
#' Computes classification of new images in test data
#' 
predict_svdmod = function(test, models) {
  np = nrow(test)
  pred = rep(NA, np)
  mnames = names(models)
  mloss = matrix(NA, nrow = np, ncol = length(mnames))
  colnames(mloss) = mnames
  
  y = as.matrix(test)   ## removed loop and set y as matrix
  for(m in mnames) {
    vt = models[[m]]$vt
    yhat = y %*% t(vt) %*% vt  ## transpose of t(vt) %*% vt %*% y
    mloss[, m] = rowSums((y - yhat)^2)/ncol(y) ## rowSums instead of sum
  }
  pred = apply(mloss, 1, function(x) mnames[which.min(x)]) ## apply over rows
  pred
}

#' image_ggplot
#' 
#' Produces a facet plot of first few basis vectors as images
#' 
image_ggplot = function(images, ivals, title) {
  library(ggplot2)
  image = rep(ivals, 28*28)
  lab = rep("component", 28*28)
  image = factor(paste(lab, image, sep = ": "))
  col = rep(rep(1:28, 28), each = length(ivals))
  row = rep(rep(1:28, each = 28), each = length(ivals))
  im = data.frame(image = image, row = row, col = col, 
                  val = as.numeric(images[ivals, ]))
  print(
    ggplot(im, aes(row, col, fill = val)) + geom_tile() + facet_wrap(~ image) +
      ggtitle(title)
  )
}

#' model_report
#' 
#' reports a summary for each label model of basis vectors
#' optionally plots basis images
#' 
model_report = function(models, kplot = 0) {
  for(m in names(models)) {
    mk = min(kplot, models[[m]]$k)
    cat("Model", m, ": size ", models[[m]]$k, " var captured ", 
        models[[m]]$pct, " %\n", sep = "") 
    if(kplot) image_ggplot(models[[m]]$vt, 1:mk, paste("Digit", m))
  }
}

library(parallel)
library(ggplot2)
library(pbdMPI)
library(pbdIO)
source("../KPMS-IT4I-EX/mnist/mnist_read.R")
source("../KPMS-IT4I-EX/code/flexiblas_setup.r")
comm.set.seed(seed = 123, diff = TRUE)
blas_threads = as.numeric(commandArgs(TRUE)[2])
fork_cores = as.numeric(commandArgs(TRUE)[3])
setback("OPENBLAS")
setthreads(blas_threads)

## Begin CV (This CV is with mclapply. Exercise 8 needs MPI parallelization.)
## set up cv parameters

my_rank = comm.rank()
nfolds = 10
pars = seq(80.0, 95, .2)## par values to fit
my_test_rows = comm.chunk(nrow(test), form = "vector")
my_train_rows = nrow(train)

folds = sample( rep_len(1:nfolds, nrow(train)), nrow(train) ) ## random folds
cv = expand.grid(par = pars, fold = 1:nfolds)  ## all combinations

my_index = comm.chunk(nrow(cv), form = "vector")
comm.print(cv)
comm.print(my_index)
comm.print(pars)
comm.print(nrow(cv))
comm.print(my_train_rows)
comm.print(dim(cv))
comm.print(dim(my_index))
comm.print(dim(pars))
comm.print(dim(my_train_rows))
## function for parameter combination i
fold_err = function(i, cv, folds, train) {
  par = cv[i, "par"]
  fold = (folds == cv[i, "fold"])
  models = svdmod(train[!fold, ], train_lab[!fold], pct = par)
  predicts = predict_svdmod(train[fold, ], models)
  sum(predicts != train_lab[fold])
}

## apply fold_err() over parameter combinations
my_cv_err = lapply(1:nrow(cv), fold_err, cv = my_index, folds = nfolds, train = my_train_rows)

## sum fold errors for each parameter value
cv_err = allgather(my_cv_err)`  
cv_err_par = tapply(unlist(cv_err), cv[, "par"], sum)


## recompute with optimal pct
models = svdmod(my_train_rows, train_lab, pct = 85)
pdf("BasisImages.pdf")
model_report(models, kplot = 9)
dev.off()
predicts = predict_svdmod(my_test_rows, models)
correct = reduce(sum(my_pred == test_lab[my_test_rows]))
#correct <- sum(predicts == test_lab)
cat("Proportion Correct:", correct/nrow(my_test_rows), "\n")
finalize()