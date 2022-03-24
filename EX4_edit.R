library(randomForest)
data(LetterRecognition, package = "mlbench")
set.seed(seed = 123, "L'Ecuyer-CMRG")

n = nrow(LetterRecognition)
n_test = floor(0.2 * n)
i_test = sample.int(n, n_test)
train = LetterRecognition[-i_test, ]
test = LetterRecognition[i_test, ]

ntree = 200
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

nc = as.numeric(commandArgs(TRUE)[1])
cat("Running with", nc, "cores\n")
system.time({
  cv_err = parallel::mclapply(1:nrow(cv_pars), fold_err, cv_pars, folds = folds,
                              train = train, mc.cores = nc) 
  err = tapply(unlist(cv_err), cv_pars[, "mtry"], sum)
})
pdf(paste0("rf_cv", nc, ".pdf")); plot(mtry_val, err/(n - n_test)); dev.off()

system.time({
rf = function(x) randomForest(lettr ~ ., train, ntree=x, norm.votes = FALSE)
rf.out = parallel::mclapply(ntree, rf, mc.cores = nc)
rf.all = do.call(combine, rf.out)

crows = parallel::splitIndices(nrow(test), nc) 
rfp = function(x) as.vector(predict(rf.all, test[x, ])) 
cpred = parallel::mclapply(crows, rfp, mc.cores = nc) 
pred = do.call(c, cpred) 

correct <- sum(pred == test$lettr)

mtry = mtry_val[which.min(err)]

rf2 = function(x) randomForest(lettr ~ ., train, ntree=x, mtry = mtry, norm.votes = FALSE)
rf.out2 = parallel::mclapply(ntree, rf2, mc.cores = nc)
rf.all2 = do.call(combine, rf.out2)

rfp2 = function(x) as.vector(predict(rf.all2, test[x, ])) 
cpred2 = parallel::mclapply(crows, rfp2, mc.cores = nc) 
pred2 = do.call(c, cpred2) 


pred_cv2 = predict(rf.all2, test)
correct_cv = sum(pred_cv2 == test$lettr)
})


cat("Proportion Correct: ", correct/n_test, "(mtry = ", floor((ncol(test) - 1)/3),
    ") with cv:", correct_cv/n_test, "(mtry = ", mtry, ")\n", sep = "")