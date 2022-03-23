#!/usr/bin/Rscript
library(randomForest)
library(parallel)

data(LetterRecognition, package = "mlbench")
set.seed(seed = 123, "L'Ecuyer-CMRG")

# number rows: 20000
n = nrow(LetterRecognition)

# split into train and test set, ratio 0.2:0.8
n_test = floor(0.2 * n)
i_test = sample.int(n, n_test)
train = LetterRecognition[-i_test, ]
test = LetterRecognition[i_test, ]

# obtain number of cores
nc = as.numeric(commandArgs(TRUE)[1])
cat("Running with", nc, "cores\n")
ntree = lapply(splitIndices(200, nc), length)
nfolds = 10
mtry_val = 1:(ncol(train) - 1)
folds = sample( rep_len(1:nfolds, nrow(train)), nrow(train) )
cv_df = data.frame(mtry = mtry_val, incorrect = rep(0, length(mtry_val)))
cv_pars = expand.grid(mtry = mtry_val, f = 1:nfolds)
fold_err = function(i, cv_pars, folds, train) {
  mtry = cv_pars[i, "mtry"]
  fold = (folds == cv_pars[i, "f"])
  rf.all = randomForest(lettr ~ ., train[!fold, ], ntree = ntree,
                        mtry = mtry, norm.votes = FALSE)
  pred = predict(rf.all, train[fold, ])
  sum(pred != train$lettr[fold])
}

system.time({
  cv_err = parallel::mclapply(1:nrow(cv_pars), fold_err, cv_pars, folds = folds,
                              train = train, mc.cores = nc) 
  err = tapply(unlist(cv_err), cv_pars[, "mtry"], sum)
})
pdf(paste0("rf_cv_mc", nc, ".pdf")); plot(mtry_val, err/(n - n_test)); dev.off()

#ntree = lapply(splitIndices(500, nc), length)
rf = function(x) randomForest(lettr ~ ., train, ntree=ntree)
rf.out = mclapply(ntree, rf, mc.cores = nc)
rf.all = do.call(combine, rf.out)

crows = splitIndices(nrow(test), nc) 
rfp = function(x) as.vector(predict(rf.all, test[x, ])) 
cpred = mclapply(crows, rfp, mc.cores = nc) 
pred = do.call(c, cpred)
correct = sum(pred == test$lettr)

#rf.all = randomForest(lettr ~ ., train, ntree = ntree)
#pred = predict(rf.all, test)

mtry = mtry_val[which.min(err)]
rf2 = function(x) randomForest(lettr ~ ., train, ntree=ntree, mtry = mtry)
rf2.out = mclapply(ntree, rf2, mc.cores = nc)
rf2.all = do.call(combine, rf2.out)

#crows = splitIndices(nrow(test), nc) 
rfp2 = function(x) as.vector(predict(rf2.all, test[x, ])) 
cpred2 = mclapply(crows, rfp2, mc.cores = nc) 
pred2 = do.call(c, cpred2)
correct2 = sum(pred2 == test$lettr)

#rf.all = randomForest(lettr ~ ., train, ntree = ntree, mtry = mtry)
pred2 = do.call(c, cpred2)
correct2 = sum(pred2 == test$lettr)
cat("Proportion Correct: ", correct2/n_test, "(mtry = ", floor((ncol(test) - 1)/3),
    ") with cv:", correct2/n_test, "(mtry = ", mtry, ")\n", sep = "")