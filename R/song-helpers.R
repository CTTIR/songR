#' Validate Input Data for SONG
#'
#' Checks that input data is a valid numeric matrix suitable for SONG.
#'
#' @param X Input data, expected to be a numeric matrix.
#' @return A numeric matrix (coerced from data.frame if necessary).
#' @noRd
validate_input <- function(X, call = rlang::caller_env()) {
  if (is.data.frame(X)) {
    if (!all(vapply(X, is.numeric, logical(1)))) {
      cli::cli_abort("All columns in the data.frame must be numeric.", call = call)
    }
    X <- as.matrix(X)
  }

  if (!is.matrix(X) || !is.numeric(X)) {
    cli::cli_abort(
      "X must be a numeric matrix or data.frame with numeric columns.",
      call = call
    )
  }

  if (anyNA(X)) {
    cli::cli_abort("X must not contain NA or NaN values.", call = call)
  }

  if (any(is.infinite(X))) {
    cli::cli_abort("X must not contain Inf values.", call = call)
  }

  if (nrow(X) < 2) {
    cli::cli_abort("X must have at least 2 rows.", call = call)
  }

  X
}

#' Resolve and Validate a color_by Vector for Plotting
#'
#' For \code{"embedding"} plots, \code{color_by} must match the number of
#' input points. For \code{"codebook"} and \code{"graph"} plots, it may match
#' either the number of coding vectors (used directly) or the number of input
#' points (mapped to each coding vector via the modal label of its assigned
#' points).
#'
#' @param object A \code{"song_model"} object.
#' @param type Plot type: \code{"embedding"}, \code{"codebook"}, or \code{"graph"}.
#' @param n_coords Number of rows in the coordinate matrix being plotted.
#' @param color_by The user-supplied coloring vector, or \code{NULL}.
#' @return \code{NULL}, the original \code{color_by}, or a coding-vector-length
#'   factor mapped from input-length labels. Throws on length mismatch.
#' @noRd
resolve_color_by <- function(object, type, n_coords, color_by,
                             call = rlang::caller_env()) {
  if (is.null(color_by)) return(NULL)

  if (type == "embedding") {
    if (length(color_by) != n_coords) {
      cli::cli_abort(
        "color_by must have length equal to number of input points ({n_coords}).",
        call = call
      )
    }
    return(color_by)
  }

  # codebook / graph: coding-vector length is used directly
  if (length(color_by) == n_coords) return(color_by)

  # input-point length is mapped to coding vectors via the modal label
  if (length(color_by) == object$n_input) {
    mapped <- vapply(seq_len(n_coords), function(i) {
      pts <- which(object$assignments == i)
      if (length(pts) == 0L) return(NA_character_)
      tbl <- table(color_by[pts])
      names(tbl)[which.max(tbl)]
    }, character(1))
    return(as.factor(mapped))
  }

  cli::cli_abort(
    "color_by must have length equal to number of coding vectors \\
     ({n_coords}) or input points ({object$n_input}).",
    call = call
  )
}

#' Validate SONG Hyperparameters
#'
#' @param d Output dimensionality.
#' @param k Neighborhood size.
#' @param epsilon Edge decay rate.
#' @param alpha Initial learning rate.
#' @param a Output distribution parameter.
#' @param b Output distribution parameter.
#' @param spread_factor Growth spread factor.
#' @param neg_sample_rate Negative sampling rate.
#' @param e_min Minimum edge strength.
#' @param epochs Maximum number of epochs.
#' @return Invisible NULL. Throws errors on invalid parameters.
#' @noRd
validate_params <- function(d, k, epsilon, alpha, a, b, spread_factor,
                            neg_sample_rate, e_min, epochs,
                            call = rlang::caller_env()) {
  check <- function(cond, msg) {
    if (!isTRUE(cond)) cli::cli_abort(msg, call = call)
  }
  check(is.numeric(d) && d >= 1 && d == as.integer(d), "`d` must be a positive integer")
  check(is.numeric(k) && k >= d + 1, "`k` must be >= d + 1")
  check(is.numeric(epsilon) && epsilon > 0 && epsilon < 1, "`epsilon` must be in (0, 1)")
  check(is.numeric(alpha) && alpha > 0, "`alpha` must be positive")
  check(is.numeric(a) && a > 0, "`a` must be positive")
  check(is.numeric(b) && b > 0, "`b` must be positive")
  check(
    is.numeric(spread_factor) && spread_factor > 0 && spread_factor < 1,
    "`spread_factor` must be in (0, 1)"
  )
  check(
    is.numeric(neg_sample_rate) && neg_sample_rate >= 1,
    "`neg_sample_rate` must be a positive integer"
  )
  check(is.numeric(e_min) && e_min > 0, "`e_min` must be positive")
  check(is.numeric(epochs) && epochs >= 1, "`epochs` must be a positive integer")
  invisible(NULL)
}
