#' @keywords internal
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
"_PACKAGE"

#' @useDynLib songR, .registration = TRUE
#' @importFrom Rcpp sourceCpp
NULL

# Register S3 methods for generics in Suggests packages
.onLoad <- function(libname, pkgname) {
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    register_s3_method("ggplot2", "autoplot", "song_model")
  }
}

register_s3_method <- function(pkg, generic, class) {
  fun <- get(paste0(generic, ".", class), envir = parent.env(environment()))
  if (isNamespaceLoaded(pkg)) {
    registerS3method(generic, class, fun, envir = asNamespace(pkg))
  }
  # Register when ggplot2 is eventually loaded
  setHook(
    packageEvent(pkg, "onLoad"),
    function(...) {
      registerS3method(generic, class, fun, envir = asNamespace(pkg))
    }
  )
}
