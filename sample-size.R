#' Sample Size
#' 
#' @description Calculates the sample size needed to have a particular
#' confidence level (z) for an estimated percentage (p) plus or minus
#' a particular margin of error (e) for a population (N).
#' @param p Estimated percentage with attribute being measured/counted
#' @param N Total population size; Default Inf (if not known)
#' @param e Margin of error; Default 0.05 for +/-5%
#' @param z Confidence level; Default 1.96 for 95% (www.z-table.com)
#' @return Sample size
#' @examples
#' sampleSize(.5) => 384 (50% +/-5% at 95% confidence)
#' sampleSize(.02, 1000)  => 29 (2% +/- 5% at 95% confidence)
#' sampleSize(.02, 1000, .01)  => 430 (2% +/-1% at 95% confidence)
#' sampleSize(.02, 1000, .01, 2.33)  => 516 (2% +/-1% at 98% confidence)
#' 
sampleSize <- function(p, N = Inf, e = 0.05, z = 1.96 ){
  n0 <- z^2*p*(1-p) / e^2           # general sample size
  n <- round(n0 / (1 + (n0 - 1)/N)) # sample size for finite population 
  return(n)
}


