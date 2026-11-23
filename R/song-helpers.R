#' Validate Input Data for SONG
#'
#' Checks that input data is a valid numeric matrix suitable for SONG.
#'
#' @param X Input data, expected to be a numeric matrix.
#' @return A numeric matrix (coerced from data.frame if necessary).
#' @noRd
validate_input <- function(X, call = rlang::caller_env(), min_rows = 2L) {
  if (is.data.frame(X)) {
    if (!all(vapply(X, is.numeric, logical(1)))) {
      cli::cli_abort("All columns in the data.frame must be numeric.", call = call)
    }
    X <- as.matrix(X)
  }

  if (!is.matrix(X) || !is.numeric(X) || is.complex(X)) {
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

  if (nrow(X) < min_rows) {
    cli::cli_abort("X must have at least {min_rows} rows.", call = call)
  }
  if (ncol(X) < 1L) {
    cli::cli_abort("X must have at least one feature column.", call = call)
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
  n_assigned <- length(object$assignments)
  if (length(color_by) == n_assigned) {
    # One pass over the points: group the labels by assigned coding vector.
    groups <- split(color_by, factor(object$assignments, levels = seq_len(n_coords)))
    mapped <- vapply(groups, function(labels) {
      tbl <- table(labels)
      if (sum(tbl) == 0) return(NA_character_)
      names(tbl)[which.max(tbl)]
    }, character(1), USE.NAMES = FALSE)
    return(as.factor(mapped))
  }

  cli::cli_abort(
    "color_by must have length equal to number of coding vectors \\
     ({n_coords}) or input points in the current batch ({n_assigned}).",
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
  check(.song_count(d, 1), "`d` must be a positive integer")
  check(.song_count(k, 1) && k >= as.double(d) + 1, "`k` must be >= d + 1 and an integer")
  check(.song_scalar(epsilon) && epsilon > 0 && epsilon < 1, "`epsilon` must be in (0, 1)")
  check(.song_scalar(alpha) && alpha > 0, "`alpha` must be positive and finite")
  check(.song_scalar(a) && a > 0, "`a` must be positive and finite")
  check(.song_scalar(b) && b > 0, "`b` must be positive and finite")
  check(
    .song_scalar(spread_factor) && spread_factor > 0 && spread_factor < 1,
    "`spread_factor` must be in (0, 1)"
  )
  check(
    .song_count(neg_sample_rate, 1),
    "`neg_sample_rate` must be a positive integer"
  )
  check(.song_scalar(e_min) && e_min > 0, "`e_min` must be positive and finite")
  check(.song_count(epochs, 1), "`epochs` must be a positive integer")
  invisible(NULL)
}

# Run native training and report divergence as an R condition. Coding vectors
# overflow when the learning rate overshoots (alpha >= 2) or the features are
# on an extreme scale; Armadillo then fails while sorting NaN distances.
.song_native <- function(result, call = rlang::caller_env()) {
  diverged <- function() {
    cli::cli_abort(
      c("Training diverged: the coding vectors became nonfinite.",
        "i" = "Lower {.arg alpha} or rescale the input features."),
      class = "song_error_diverged", call = call
    )
  }
  result <- tryCatch(result, error = function(e) {
    if (grepl("detected NaN", conditionMessage(e), fixed = TRUE)) diverged()
    stop(e)
  })
  if (!all(is.finite(result$C)) || !all(is.finite(result$Y))) diverged()
  result
}

# Place coding vectors without assigned points in the refined (dispersed)
# layout: at the edge-weighted mean of their occupied graph neighbours, or at
# the occupied coding vector nearest in input space when they have none.
.song_place_unassigned <- function(Y, occupied, E_s, C) {
  empty <- which(!occupied)
  filled <- which(occupied)
  if (length(empty) == 0L || length(filled) == 0L) {
    return(Y)
  }
  for (cv in empty) {
    weight <- E_s[cv, filled]
    if (any(weight > 0)) {
      Y[cv, ] <- colSums(Y[filled, , drop = FALSE] * weight) / sum(weight)
    } else {
      offset <- sweep(C[filled, , drop = FALSE], 2L, C[cv, ], "-")
      Y[cv, ] <- Y[filled[which.min(rowSums(offset^2))], ]
    }
  }
  Y
}

.song_scalar <- function(x) {
  is.numeric(x) && !is.complex(x) && length(x) == 1L && !is.na(x) && is.finite(x)
}

.song_count <- function(x, min = 0, max = .Machine$integer.max) {
  .song_scalar(x) && x >= min && x <= max && x == trunc(x)
}

.song_check_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("`{name}` must be TRUE or FALSE.")
  }
}

.song_check_seed <- function(seed) {
  if (!is.null(seed) && !.song_count(seed, -.Machine$integer.max)) {
    cli::cli_abort("`seed` must be NULL or a finite integer.")
  }
}

.song_check_decay <- function(lr_sigma) {
  if (!.song_scalar(lr_sigma) || lr_sigma < 0) {
    cli::cli_abort("`lr_sigma` must be finite and non-negative.")
  }
}

# Reject damaged saved objects before passing their dimensions to native code.
.song_check_model <- function(object, update = FALSE) {
  finite_matrix <- function(x) {
    is.matrix(x) && is.numeric(x) && !is.complex(x) && all(is.finite(x))
  }
  valid <- is.list(object) && .song_count(object$D, 1) &&
    finite_matrix(object$C) && nrow(object$C) > 0L && ncol(object$C) == object$D &&
    finite_matrix(object$Y) && nrow(object$Y) == nrow(object$C) && ncol(object$Y) > 0L
  if (valid && update) {
    adj <- if (is.null(object$adj)) object$E else object$adj
    valid <- is.list(object$parameters) && .song_count(object$parameters$d, 1) &&
      ncol(object$Y) == object$parameters$d && finite_matrix(adj) &&
      identical(dim(adj), rep(nrow(object$C), 2L)) &&
      is.numeric(object$E_q) && !is.complex(object$E_q) &&
      length(object$E_q) == nrow(object$C) && all(is.finite(object$E_q)) &&
      .song_scalar(object$n_input) && object$n_input >= 1 &&
      object$n_input == trunc(object$n_input)
  }
  if (!valid) {
    cli::cli_abort("The stored model has invalid dimensions or nonfinite values.",
                   class = "song_error_model")
  }
  invisible(NULL)
}
