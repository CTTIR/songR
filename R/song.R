#' Fit a SONG Model for Dimensionality Reduction
#'
#' Performs non-linear dimensionality reduction using the Self-Organizing
#' Nebulous Growths (SONG) algorithm. SONG builds a codebook of coding
#' vectors connected by a topology-preserving graph, then maps the graph
#' into a low-dimensional embedding space. Unlike t-SNE and UMAP, the
#' resulting model supports incremental updates with new data via
#' \code{\link{update.song_model}}.
#'
#' @param X Numeric matrix of input data (\code{n x D}), or a data.frame
#'   with all numeric columns (will be coerced to matrix).
#' @param d Integer. Output dimensionality (default: 2).
#' @param k Integer. Neighbourhood size for the coding-vector graph.
#'   Corresponds to \code{dim + n_neighbors} in the Python reference.
#'   Must be \code{>= d + 1} (default: 3, which matches Python's
#'   \code{n_neighbors = 1} with \code{dim = 2}).
#' @param epsilon Numeric. Edge decay rate, in \code{(0, 1)} (default: 0.9).
#'   Lower values produce sparser, faster-pruning graphs.
#' @param epochs Integer. Number of self-organisation iterations
#'   (default: 50, matching Python's \code{so_steps}).
#' @param alpha Numeric. Initial SO learning rate (default: 1.0). Each sample
#'   moves its nearest coding vector by this fraction of their distance, and
#'   the rate decays over the epochs (see \code{lr_sigma}). Values above 1
#'   overshoot the sample, and large values can make training unstable. There
#'   is no fixed threshold: it depends on the data, \code{epochs} and
#'   \code{lr_sigma}. Coding vectors that become nonfinite or leave the range
#'   of the data by more than a factor of 1000 raise an error of class
#'   \code{song_error_diverged}; a fit that returns without this error is not
#'   thereby shown to be stable.
#' @param a Numeric. Rational-quadratic kernel parameter (default: 1.577,
#'   from \code{find_spread_tightness(spread=1, min_dist=0.1)}).
#' @param b Numeric. Rational-quadratic kernel parameter (default: 0.895).
#' @param spread_factor Numeric. Controls growth threshold
#'   \eqn{\theta = -\ln(D) \cdot \ln(\mathrm{sf})}; higher values produce
#'   more coding vectors. In \code{(0, 1)} (default: 0.5).
#' @param neg_sample_rate Integer. Number of negative samples per positive
#'   edge during repulsion (default: 5).
#' @param max_age Integer. Controls automatic edge pruning: edges weaker
#'   than \code{epsilon^(d + max_age)} are removed (default: 3).
#' @param e_min Numeric or \code{NULL}. Minimum edge strength below which
#'   edges are pruned. \code{NULL} (default) auto-computes as
#'   \code{epsilon^(d + max_age)}, matching the Python reference.
#' @param max_prototypes Integer or \code{NULL}. Maximum number of coding
#'   vectors. \code{NULL} (default) auto-computes as
#'   \code{floor(exp(log(n) / 1.5))}, matching the Python reference. The
#'   codebook graph is stored as a dense matrix, so training memory grows with
#'   the square of this value (at least \code{8 * (max_prototypes + 200)^2}
#'   bytes; the returned model holds further copies of the graph).
#' @param lr_sigma Numeric. Decay constant for the SO learning-rate
#'   schedule: \code{so_lr = alpha * exp(-lr_sigma * (epoch/epochs)^2)}.
#'   Default: 5.0 (matches Python).
#' @param dispersion Logical. If \code{TRUE} (default) and \pkg{uwot} is
#'   available, runs a UMAP refinement step initialised from the SONG
#'   embedding. This follows the Python reference implementation's
#'   \code{transform()} method and dramatically improves visual cluster
#'   separation. Without \pkg{uwot} the step is skipped and the raw SONG
#'   embedding is returned; see Details.
#' @param seed Integer or \code{NULL}. Random seed for reproducibility. A
#'   non-\code{NULL} seed is passed to \code{\link{set.seed}}, so it also
#'   resets the random number stream of the session; with \code{NULL} the
#'   current stream is used and advanced.
#' @param verbose Logical. Whether to print progress per epoch (default: TRUE).
#'
#' @param feature_manifest Optional data frame with exactly these character
#'   columns, in order: `feature`, `compartment`, `statistic`, `unit`, `transform`,
#'   `normalization`. Rows must follow the named input columns. Describe complete
#'   externally applied transform/normalisation recipes, including parameters or
#'   a versioned reference identifier; use `"identity"`/`"none"` when applicable.
#'   The manifest records declarations; it does not apply transformations or
#'   establish that supplied measurements have the declared physical meaning.
#' @details
#' Named training columns are bound in exact order and must also be named in
#' prediction and updates. An explicit manifest must be supplied again, unchanged,
#' to predict or update a model trained with one. Missing/nonfinite measurements
#' are rejected; no feature is silently reordered or imputed. Unnamed training
#' data retains positional compatibility and cannot verify feature semantics.
#' Legacy models without a contract also retain positional behaviour.
#' Integer controls must be scalar, finite, whole numbers within R's integer
#' range; fractional values are rejected rather than truncated. Numeric controls
#' must be finite, and `lr_sigma` must be non-negative.
#'
#' With `dispersion = TRUE` the returned `embedding` is the UMAP-refined layout
#' and `Y` holds, for each coding vector, the centroid of its assigned points in
#' that layout, so that [predict.song_model()] projects into the same
#' coordinates. A coding vector without assigned points is placed at the
#' edge-weighted mean of its occupied graph neighbours, or at the occupied
#' coding vector nearest in input space when it has none. If the refinement
#' fails, for example on very small inputs, a warning is issued and the raw
#' SONG embedding is returned. `parameters$dispersion` records the request,
#' not whether \pkg{uwot} was available. [update.song_model()] continues the
#' core SONG training and does not repeat the refinement.
#'
#' @return An S3 object of class \code{"song_model"} containing:
#' \describe{
#'   \item{Y}{Embedding coordinates of coding vectors (\code{n_coding x d}).}
#'   \item{C}{Coding vectors (\code{n_coding x D}).}
#'   \item{E}{Directed adjacency matrix (\code{n_coding x n_coding}) of edge
#'     strengths, with a zero diagonal.}
#'   \item{E_s}{Symmetric adjacency matrix, \code{(E + t(E)) / 2}.}
#'   \item{adj}{Internal training state: \code{E} with a unit diagonal, used
#'     to continue training in \code{\link{update.song_model}}.}
#'   \item{E_q}{Internal training state: accumulated squared quantisation
#'     error per coding vector, which drives codebook growth.}
#'   \item{assignments}{Integer vector of length \code{n}: nearest CV index.}
#'   \item{embedding}{Embedding coordinates for all input points (\code{n x d}).}
#'   \item{parameters}{List of all hyperparameters used.}
#'   \item{n_epochs}{Number of epochs run in this call.}
#'   \item{converged}{Always \code{FALSE}: training runs for the requested
#'     number of epochs and has no early-stopping criterion.}
#'   \item{n_input}{Number of training observations.}
#'   \item{D}{Number of input features.}
#'   \item{feature_contract}{Versioned feature order, declared metadata and missing-value policy.}
#'   \item{lineage}{Projection version, parent identifier and reprojection policy.}
#' }
#'
#' @export
#' @examples
#' model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42)
#' plot(model, color_by = iris$Species)
#'
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
#'
#' @seealso \code{\link{update.song_model}}, \code{\link{predict.song_model}},
#'   \code{\link{plot.song_model}}
song <- function(
  X,
  d = 2L,
  k = 3L,
  epsilon = 0.9,
  epochs = 50L,
  alpha = 1.0,
  a = 1.577,
  b = 0.895,
  spread_factor = 0.5,
  neg_sample_rate = 5L,
  max_age = 3L,
  e_min = NULL,
  max_prototypes = NULL,
  lr_sigma = 5.0,
  dispersion = TRUE,
  seed = NULL,
  verbose = TRUE,
  feature_manifest = NULL
) {
  # Input validation
  X <- validate_input(X)
  feature_contract <- .song_feature_contract(X, feature_manifest)
  validate_params(d, k, epsilon, alpha, a, b, spread_factor,
                  neg_sample_rate, if (is.null(e_min)) 1 else e_min, epochs)
  if (!.song_count(max_age)) {
    cli::cli_abort("`max_age` must be a non-negative integer.")
  }
  if (!is.null(max_prototypes) &&
        !.song_count(max_prototypes, 1, .Machine$integer.max - 500)) {
    cli::cli_abort("`max_prototypes` must be a positive integer below the native size limit.")
  }
  .song_check_decay(lr_sigma)
  .song_check_flag(dispersion, "dispersion")
  .song_check_flag(verbose, "verbose")
  .song_check_seed(seed)
  d  <- as.integer(d)
  k  <- as.integer(k)
  epochs <- as.integer(epochs)
  neg_sample_rate <- as.integer(neg_sample_rate)
  max_age <- as.integer(max_age)

  n <- nrow(X)
  D <- ncol(X)

  # Adaptive e_min:  Python min_strength = epsilon^(dim + max_age)
  if (is.null(e_min)) {
    e_min <- epsilon^(as.double(d) + max_age)
  }

  # Max prototypes:  Python int(exp(log(n) / 1.5))
  if (is.null(max_prototypes)) {
    max_prototypes <- as.integer(floor(exp(log(n) / 1.5)))
  }
  max_prototypes <- as.integer(max_prototypes)

  validate_params(d, k, epsilon, alpha, a, b, spread_factor,
                  neg_sample_rate, e_min, epochs)

  if (n < as.double(d) + 1) {
    cli::cli_abort("Need at least d + 1 = {as.double(d) + 1} data points, got {n}.")
  }

  if (!is.null(seed)) {
    set.seed(seed)
    cpp_seed <- as.integer(seed)
  } else {
    cpp_seed <- -1L
  }

  # ── Core SONG training (C++) ────────────────────────────────────────────
  result <- .song_native(song_fit_cpp(
    X              = X,
    d_out          = d,
    im_neix        = k,
    epsilon        = epsilon,
    max_its        = epochs,
    lrst           = alpha,
    a_param        = a,
    b_param        = b,
    spread_factor  = spread_factor,
    ns_rate        = neg_sample_rate,
    min_strength   = e_min,
    max_prototypes = max_prototypes,
    lr_sigma       = lr_sigma,
    verbose        = verbose,
    seed           = cpp_seed
  ), scale = max(abs(X)))

  # ── UMAP dispersion step (matches Python transform()) ───────────────────
  has_uwot <- isTRUE(dispersion) && requireNamespace("uwot", quietly = TRUE)
  if (isTRUE(dispersion) && !has_uwot && verbose) {
    cli::cli_inform(c(
      "Skipping the UMAP dispersion step: package {.pkg uwot} is not installed.",
      "i" = "The raw SONG embedding is returned."
    ))
  }
  if (has_uwot) {
    if (verbose) cli::cli_inform("Running UMAP dispersion step...")

    y_raw   <- result$embedding
    # Python uses a plain min-max scaling to [0, 10] for the UMAP init
    # (Y_init = 10 * (Y - Y.min(0)) / (Y.max(0) - Y.min(0))). That is fragile:
    # SONG's repulsion can let a rarely-attracted ("drifter") coding vector
    # drift far, and min-max is then dominated by that single outlier -- it
    # squashes the real structure into a sliver and parks the outlier's points
    # at the edge, where the short (11-epoch) UMAP refinement cannot recover
    # them. Winsorize to the 2nd-98th percentile per dimension so the bulk
    # fills the init range and any outlier merely starts at its edge.
    y_lo    <- apply(y_raw, 2L, stats::quantile, probs = 0.02)
    y_hi    <- apply(y_raw, 2L, stats::quantile, probs = 0.98)
    y_range <- pmax(y_hi - y_lo, 1e-10)
    y_clip  <- y_raw
    for (j in seq_len(ncol(y_raw))) {
      y_clip[, j] <- pmin(pmax(y_raw[, j], y_lo[j]), y_hi[j])
    }
    y_init  <- 10.0 * sweep(sweep(y_clip, 2L, y_lo, "-"), 2L, y_range, "/")

    # Dispersion refines the (frozen) SONG embedding into the 2-D plane with
    # UMAP, initialised from the [0, 10]-scaled SONG layout. The Python
    # reference uses a very gentle refinement (n_epochs = 11, lr = 0.01,
    # min_dist = 0.001) because its raw SONG embedding is already well spread.
    # songR's raw embedding is more collapsed on hard, multi-class data, so a
    # gentle refinement leaves it stranded near one axis. A stronger, standard
    # UMAP refinement (200 epochs, lr = 1.0, min_dist = 0.1) lets the embedding
    # use the full plane and, in benchmarks, improves cluster quality (AMI) on
    # every tested dataset while keeping the SONG structure as the init.
    # n_sgd_threads = 1L pins the SGD to be deterministic regardless of n_threads.
    umap_result <- tryCatch(
      uwot::umap(
        X,
        n_components  = d,
        n_epochs      = 200L,
        init          = y_init,
        min_dist      = 0.1,
        learning_rate = 1.0,
        verbose       = FALSE,
        n_threads     = 1L,
        n_sgd_threads = 1L       # deterministic SGD regardless of n_threads
      ),
      error = function(e) {
        cli::cli_warn(
          "UMAP dispersion failed ({conditionMessage(e)}); \\
           returning raw SONG embedding."
        )
        NULL
      }
    )

    if (!is.null(umap_result)) {
      # Python rescales back:  output = (umap_out * Y_scale / 10) + Y_loc
      # We skip rescaling since the absolute scale doesn't matter for plots.
      result$embedding <- umap_result

      # Update CV positions to centroid of their assigned points. Grouping the
      # row indices once keeps this linear in the number of points.
      Y_refined <- matrix(0.0, nrow = result$n_coding, ncol = d)
      members <- split(
        seq_len(n),
        factor(result$assignments, levels = seq_len(result$n_coding))
      )
      for (cv in seq_len(result$n_coding)) {
        mask <- members[[cv]]
        if (length(mask) > 0L) {
          Y_refined[cv, ] <- colMeans(matrix(umap_result[mask, ], ncol = d))
        }
      }
      # Coding vectors without assigned points have no refined position. Their
      # raw SONG coordinates belong to a different coordinate system, so they
      # are placed inside the refined layout instead of being kept.
      result$Y <- .song_place_unassigned(
        Y_refined, lengths(members) > 0L, result$E_s, result$C
      )
    }
  }

  # Store parameters
  parameters <- list(
    d = d, k = k, epsilon = epsilon, epochs = epochs,
    alpha = alpha, a = a, b = b, spread_factor = spread_factor,
    neg_sample_rate = neg_sample_rate, e_min = e_min,
    max_age = max_age, max_prototypes = max_prototypes,
    lr_sigma = lr_sigma, dispersion = dispersion, seed = seed
  )

  model <- new_song_model(result, parameters, n, D, feature_contract)
  model$lineage <- .song_model_lineage(model)
  model
}
