#' Incrementally Update a SONG Model with New Data
#'
#' Adds new data to an existing SONG model. This is the key differentiator
#' of SONG over t-SNE and UMAP: training continues from the existing model.
#' Coding vectors, edges and embedding positions may change. The supplied
#' object is unchanged; use [predict.song_model()] for frozen projection.
#'
#' @param object A \code{"song_model"} object to update.
#' @param X_new Numeric matrix of new data (\code{n_new x D}). Must have
#'   the same number of columns as the original training data.
#' @param epochs Integer. Number of additional training epochs (default: 50).
#' @param alpha Numeric or \code{NULL}. Initial learning rate for the update.
#'   If \code{NULL}, uses the original learning rate (default: NULL).
#' @param verbose Logical. Whether to print progress (default: TRUE).
#' @param ... Ignored.
#' @param seed Optional integer seed for update training. `NULL` preserves the
#'   existing random-stream behavior; the original fit seed is not reused.
#' @param feature_manifest The unchanged manifest supplied at training, if any.
#'   Named features must follow training order. See [song()] for the contract.
#'
#' @return An updated \code{"song_model"} object with grown codebook
#'   incorporating the new data. `embedding` and `assignments` describe only
#'   `X_new`; `n_input` counts all training rows across updates.
#' @details
#' `lineage` schema 1.0.0 records a revision, a deterministic SHA-256 model
#' identifier and its parent identifier. Identifiers bind the ordered projection
#' codebook, coordinates, feature contract and revision ancestry, not the full
#' training history or authenticity of a manually modified object.
#' Each update requires reprojection of all earlier observations with the new
#' model before combining coordinates. Earlier input rows are not retained or
#' automatically reprojected. Initial revisions start at 1. Updates to legacy
#' models start a new revision history at 1 with `parent_history` set to
#' `legacy_unversioned` and a parent projection fingerprint. Save the model
#' together with any exported projection to retain its version.
#' Coincident embedding positions reflect prototype assignment; they do not
#' establish cell contact or physical spatial distance.
#'
#' @export
#' @examples
#' model <- song(as.matrix(iris[1:100, 1:4]), epochs = 5L, seed = 42)
#' model <- update(model, as.matrix(iris[101:150, 1:4]), epochs = 5L)
#'
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
#'
#' @seealso \code{\link{song}}, \code{\link{predict.song_model}}
update.song_model <- function(object, X_new, epochs = 50L,
                              alpha = NULL, verbose = TRUE, ..., feature_manifest = NULL,
                              seed = NULL) {
  .song_check_lineage(object)
  X_new <- validate_input(X_new)
  epochs <- as.integer(epochs)

  if (ncol(X_new) != object$D) {
    cli::cli_abort("New data must have {object$D} columns (got {ncol(X_new)}).")
  }

  if (is.null(alpha)) {
    alpha <- object$parameters$alpha
  }

  .song_check_features(object, X_new, feature_manifest)

  params <- object$parameters
  n_new  <- nrow(X_new)

  # Python incremental: prototypes += prototypes * prot_inc_portion (50%)
  max_protos <- as.integer(ceiling(nrow(object$C) * 1.5))

  # Reconstruct adj with diagonal if needed (backward compat)
  adj_mat <- if (!is.null(object$adj)) {
    object$adj
  } else {
    a <- object$E
    diag(a) <- 1
    a
  }

  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1L || is.na(seed) ||
          !is.finite(seed) || seed != trunc(seed) || abs(seed) > .Machine$integer.max) {
      cli::cli_abort("`seed` must be NULL or a finite integer.")
    }
    set.seed(as.integer(seed))
  }

  result <- song_update_cpp(
    X_new          = X_new,
    W              = object$C,
    Y              = object$Y,
    adj_in         = adj_mat,
    E_q_in         = object$E_q,
    d_out          = params$d,
    im_neix        = params$k,
    epsilon        = params$epsilon,
    max_its        = epochs,
    lrst           = alpha,
    a_param        = params$a,
    b_param        = params$b,
    spread_factor  = params$spread_factor,
    ns_rate        = params$neg_sample_rate,
    min_strength   = params$e_min,
    max_prototypes = max_protos,
    lr_sigma       = if (!is.null(params$lr_sigma)) params$lr_sigma else 5.0,
    verbose        = verbose,
    seed           = if (!is.null(seed)) as.integer(seed) else -1L
  )

  params$epochs <- params$epochs + epochs
  params$update_seed <- seed
  model <- new_song_model(result, params, object$n_input + n_new, object$D,
                          object$feature_contract)
  model$lineage <- .song_model_lineage(model, parent = object)
  model
}

#' Project New Points into a SONG Embedding
#'
#' Maps new data points into an existing SONG embedding by assigning each
#' point to its nearest coding vector and returning that coding vector's
#' embedding coordinates. This does not train or mutate the model.
#' Multiple points assigned to one prototype have identical coordinates; these
#' coordinates are not physical locations or evidence of contact.
#'
#' @param object A trained \code{"song_model"} object.
#' @param newdata Numeric matrix of new data (\code{n_new x D}).
#' @param ... Ignored.
#' @param feature_manifest The unchanged manifest supplied at training, if any.
#'   Named features must follow training order. See [song()] for the contract.
#'
#' @return A numeric matrix (\code{n_new x d}) of embedding coordinates.
#'
#' @export
#' @examples
#' model <- song(as.matrix(iris[1:120, 1:4]), epochs = 5L, seed = 42)
#' new_coords <- predict(model, newdata = as.matrix(iris[121:150, 1:4]))
#'
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
#'
#' @seealso \code{\link{song}}, \code{\link{update.song_model}}
predict.song_model <- function(object, newdata, ..., feature_manifest = NULL) {
  newdata <- validate_input(newdata)

  if (ncol(newdata) != object$D) {
    cli::cli_abort("newdata must have {object$D} columns (got {ncol(newdata)}).")
  }

  .song_check_features(object, newdata, feature_manifest)

  # Find nearest coding vector for each new point
  nn_idx <- batch_knn_search_cpp(newdata, object$C, 1L)

  # Map to embedding coordinates (nn_idx is 0-indexed from C++)
  object$Y[nn_idx[, 1] + 1L, , drop = FALSE]
}
