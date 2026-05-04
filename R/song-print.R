#' Print a SONG Model
#'
#' Prints a concise summary of a \code{"song_model"} object.
#'
#' @param x A \code{"song_model"} object.
#' @param ... Ignored.
#' @return Invisible \code{x}.
#' @export
#' @examples
#' model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42)
#' print(model)
#'
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
print.song_model <- function(x, ...) {
  n_coding <- nrow(x$C)
  n_edges <- sum(x$E_s[upper.tri(x$E_s)] > 0)
  converge_str <- if (x$converged) "converged" else "max epochs"

  cat("SONG model\n")
  cat("  Input:", x$n_input, "points in", x$D, "dimensions\n")
  cat("  Coding vectors:", n_coding, "\n")
  cat("  Edges:", n_edges, "\n")
  cat("  Output dimensionality:", x$parameters$d, "\n")
  cat("  Epochs:", x$n_epochs, paste0("(", converge_str, ")"), "\n")
  invisible(x)
}

#' Summarize a SONG Model
#'
#' Provides a detailed summary of a \code{"song_model"} object, including
#' quantization error and edge statistics.
#'
#' @param object A \code{"song_model"} object.
#' @param ... Ignored.
#' @return Invisible \code{object}.
#' @export
#' @examples
#' model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42)
#' summary(model)
#'
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
summary.song_model <- function(object, ...) {
  n_coding <- nrow(object$C)
  es_upper <- object$E_s[upper.tri(object$E_s)]
  edge_vals <- es_upper[es_upper > 0]
  n_edges <- length(edge_vals)
  converge_str <- if (object$converged) "converged" else "max epochs"

  cat("SONG model summary\n")
  cat("==================\n")
  cat("  Input:", object$n_input, "points in", object$D, "dimensions\n")
  cat("  Coding vectors:", n_coding, "\n")
  cat("  Compression ratio:", sprintf("%.1f:1", object$n_input / n_coding), "\n")
  cat("  Edges:", n_edges, "\n")
  if (n_edges > 0) {
    cat("  Mean edge strength:", sprintf("%.4f", mean(edge_vals)), "\n")
  }
  cat("  Output dimensionality:", object$parameters$d, "\n")
  cat("  Epochs:", object$n_epochs, paste0("(", converge_str, ")"), "\n")
  cat("\nParameters:\n")
  cat("  k =", object$parameters$k,
      "| epsilon =", object$parameters$epsilon,
      "| spread_factor =", object$parameters$spread_factor, "\n")
  cat("  a =", object$parameters$a,
      "| b =", object$parameters$b,
      "| alpha =", object$parameters$alpha, "\n")
  invisible(object)
}
