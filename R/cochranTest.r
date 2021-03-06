#' @title Cochran \emph{C} Test 
#' @description
#' Detects and removes replicate outliers in data series based on the Cochran \emph{C} test for homogeneity in variance.
#' @usage
#' cochranTest(X,id,fun='sum',alpha=0.05)
#' @param X input \code{data.frame} or \code{matrix}
#' @param id \code{factor} of the replicate identifiers
#' @param fun function to aggregate data: 'sum' (default), 'mean', 'PC1' or 'PC2'
#' @param alpha \emph{p}-value of the Cochran \emph{C} test
#' @author Antoine Stevens
#' @return a \code{list} with components:
#' \itemize{
#'  \item{'\code{X}'}{ input \code{matrix} from which outlying observations (rows) have been removed}
#'  \item{'\code{outliers}'}{ numeric \code{vector} giving the row indices of the input data that have been flagged as outliers}
#' }
#' @details 
#' The Cochran \emph{C} test is test whether a single estimate of variance is significantly larger than a a group of variances.
#' It can be computed as:
#' \deqn{RMSD = \sqrt{\frac{1}{n} \sum_{i=1}^n {(y_i - \ddot{y}_i)^2}}}
#' where \eqn{y_i} is the value of the side variable of the \eqn{i}th sample, \eqn{\ddot{y}_i} is the value of the side variable of the nearest neighbor 
#' of the \eqn{i}th sample and \eqn{n} is the total number of observations 
#' 
#' For multivariate data, the variance \eqn{S_i^2} can be computed on aggregated data, using a summary function (\code{fun} argument)
#' such as \code{sum}, \code{mean}, or first principal components ('PC1' and 'PC2').
#' 
#' An observation is considered to have an outlying variance if the Cochran \emph{C} statistic is higher than an upper limit critical value \eqn{C_{UL}}
#' which can be evaluated with ('t Lam, 2010):
#' 
#' \deqn{ C_{UL}(\alpha,n,N) = \left [1+\frac{N-1}{F_{c}(\alpha/N,(n-1),(N-1)(n-1))} \right ]^{-1}}
#' 
#' where \eqn{\alpha} is the \emph{p}-value of the test, \eqn{n} is the (average) number of replicates and \eqn{F_c} is the critical value of the Fisher's \eqn{F} ratio.
#' 
#' The replicates with outlying variance are removed and the test can be applied iteratively until no outlying variance is detected under the given \emph{p}-value.
#' Such iterative procedure is implemented in \code{cochranTest}, allowing the user to specify whether a set of replicates 
#' should be removed or not from the dataset by graphical inspection of the outlying replicates.
#' The user has then the possibility to (i) remove all replicates at once, (ii) remove one or more replicates by giving their indices or
#' (iii) remove nothing.
#' @note The test assumes a balanced design (i.e. data series have the same number of replicates).
#' @references 
#' Centner, V., Massart, D.L., and De Noord, O.E., 1996. Detection of inhomogeneities in sets of NIR spectra. Analytica Chimica Acta 330, 1-17.
#' 
#' R.U.E. 't Lam (2010). Scrutiny of variance results for outliers: Cochran's test optimized. Analytica Chimica Acta 659, 68-84.
#' 
#' \url{http://en.wikipedia.org/wiki/Cochran's_C_test}
#' 
#' @export

cochranTest <- function(X, id, fun = "sum", alpha = 0.05) {
    
    if (!is.factor(id)) 
        stop("id should be a factor")
    id <- id[drop = T]
    pval <- 0
    X2 <- NULL
    n <- nrow(X)
    X <- data.frame(ID = 1:n, X, check.names = F)
    
    while (pval <= alpha) {
        
        x <- switch(fun, sum = {
            apply(X[, -1], 1, sum)
        }, mean = {
            apply(X[, -1], 1, mean)
        }, PC1 = {
            prcomp(X[, -1], center = T, .scale = F)$x[, 1]
        }, PC2 = {
            prcomp(X[, -1], center = T, .scale = F)$x[, 2]
        })
        
        vars <- tapply(x, id, var)  # variances
        pval <- Cul(max(vars)/sum(vars), mean(table(id)), length(vars))
        if (pval > alpha) 
            break
        print(paste("Cochran p value for max variance = ", pval, sep = ""))
        maxvar <- which(id == levels(id)[which.max(vars)])
        matplot(x = as.numeric(colnames(X[, -1])), y = t(X[maxvar, -1]), type = "l", xlab = "", ylab = "", main = levels(id)[which.max(vars)])
        legend("topleft", lty = 1:length(maxvar), col = 1:length(maxvar), legend = 1:length(maxvar))
        out <- readline("Which replicate is an outlier \nthat you want to remove\n(-1 = all; 0 = none; >0 = (comma separated) index of the replicate(s) to remove )\n:")
        out <- as.numeric(strsplit(out, ",")[[1]])
        if (out[1]) {
            if (out[1] == -1) {
                out <- 1:length(maxvar)
            }
            X <- X[-maxvar[out], ]
            id <- id[-maxvar[out]][drop = T]
        } else {
            # keep those that have been flagged but are not outliers
            X2 <- rbind(X2, X[maxvar, ])
            X <- X[-maxvar, ]
            id <- id[-maxvar][drop = T]
        }
    }
    X <- rbind(X, X2)
    list(X = X[, -1], outliers = which(!1:n %in% X$ID))
} 
