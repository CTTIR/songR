#' Create a song_model Object
#'
#' Internal constructor for S3 class \code{"song_model"}.
#'
#' @param result List returned from C++ \code{song_fit_cpp()} or
#'   \code{song_update_cpp()}.
#' @param parameters List of hyperparameters used.
#' @param n_input Number of input data points.
#' @param D Input dimensionality.
#' @return An S3 object of class \code{"song_model"}.
#' @noRd
new_song_model <- function(result, parameters, n_input, D) {
  structure(
    list(
      Y = result$Y,
      C = result$C,
      E = result$E,
      E_s = result$E_s,
      adj = if (!is.null(result$adj)) result$adj else result$E,
      E_q = if (!is.null(result$E_q)) result$E_q else rep(0, nrow(result$C)),
      assignments = as.integer(result$assignments),
      embedding = result$embedding,
      parameters = parameters,
      n_epochs = result$n_epochs,
      converged = if (!is.null(result$converged)) result$converged else FALSE,
      n_input = n_input,
      D = D
    ),
    class = "song_model"
  )
}
