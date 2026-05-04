#' Fit a SONG Model for Dimensionality Reduction
#'
#' Performs nonlinear dimensionality reduction using the Self-Organizing
#' Nebulous Growths (SONG) algorithm. SONG builds a codebook of coding
#' vectors connected by a topology-preserving graph, then maps the graph
#' into a low-dimensional embedding space. Unlike t-SNE and UMAP, the
#' resulting model supports incremental updates with new data via
#' \code{\link{update.song_model}}.
#'
#' @param X Numeric matrix of input data (\code{n x D}), or a data.frame
#'   with all numeric columns (will be coerced to matrix).
#' @param d Integer. Output dimensionality (default: 2).
#' @param k Integer. Neighborhood size for the coding-vector graph.
#'   Corresponds to \code{dim + n_neighbors} in the Python reference.
#'   Must be \code{>= d + 1} (default: 3, which matches Python's
#'   \code{n_neighbors = 1} with \code{dim = 2}).
#' @param epsilon Numeric. Edge decay rate, in \code{(0, 1)} (default: 0.9).
#'   Lower values produce sparser, faster-pruning graphs.
#' @param epochs Integer. Number of self-organisation iterations
#'   (default: 50, matching Python's \code{so_steps}).
#' @param alpha Numeric. Initial SO learning rate (default: 1.0).
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
#'   \code{floor(exp(log(n) / 1.5))}, matching the Python reference.
#' @param lr_sigma Numeric. Decay constant for the SO learning-rate
#'   schedule: \code{so_lr = alpha * exp(-lr_sigma * (epoch/epochs)^2)}.
#'   Default: 5.0 (matches Python).
#' @param dispersion Logical. If \code{TRUE} (default) and \pkg{uwot} is
#'   available, runs a short UMAP refinement step initialised from the SONG
#'   embedding. This matches the Python reference implementation's
#'   \code{transform()} method and dramatically improves visual cluster
#'   separation.
#' @param seed Integer or \code{NULL}. Random seed for reproducibility.
#' @param verbose Logical. Whether to print progress per epoch (default: TRUE).
#'
#' @return An S3 object of class \code{"song_model"} containing:
#' \describe{
#'   \item{Y}{Embedding coordinates of coding vectors (\code{n_coding x d}).}
#'   \item{C}{Coding vectors (\code{n_coding x D}).}
#'   \item{E}{Directed adjacency matrix (\code{n_coding x n_coding}).}
#'   \item{E_s}{Symmetric adjacency matrix.}
#'   \item{assignments}{Integer vector of length \code{n}: nearest CV index.}
#'   \item{embedding}{Embedding coordinates for all input points (\code{n x d}).}
#'   \item{parameters}{List of all hyperparameters used.}
#'   \item{n_epochs}{Number of epochs actually run.}
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
    verbose = TRUE
) {
  # Input validation
  X <- validate_input(X)
  d  <- as.integer(d)
  k  <- as.integer(k)
  epochs <- as.integer(epochs)
  neg_sample_rate <- as.integer(neg_sample_rate)
  max_age <- as.integer(max_age)

  n <- nrow(X)
  D <- ncol(X)

  # Adaptive e_min:  Python min_strength = epsilon^(dim + max_age)
  if (is.null(e_min)) {
    e_min <- epsilon^(d + max_age)
  }

  # Max prototypes:  Python int(exp(log(n) / 1.5))
  if (is.null(max_prototypes)) {
    max_prototypes <- as.integer(floor(exp(log(n) / 1.5)))
  }
  max_prototypes <- as.integer(max_prototypes)

  validate_params(d, k, epsilon, alpha, a, b, spread_factor,
                  neg_sample_rate, e_min, epochs)

  if (n < d + 1L) {
    stop("Need at least d + 1 = ", d + 1L, " data points, got ", n, ".",
         call. = FALSE)
  }

  if (!is.null(seed)) {
    set.seed(seed)
    cpp_seed <- as.integer(seed)
  } else {
    cpp_seed <- -1L
  }

  # ── Core SONG training (C++) ────────────────────────────────────────────
  result <- song_fit_cpp(
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
  )

  # ── UMAP dispersion step (matches Python transform()) ───────────────────
  if (isTRUE(dispersion) && requireNamespace("uwot", quietly = TRUE)) {
    if (verbose) message("Running UMAP dispersion step...")

    y_raw   <- result$embedding
    y_min   <- apply(y_raw, 2L, min)
    y_max   <- apply(y_raw, 2L, max)
    y_range <- pmax(y_max - y_min, 1e-10)
    # Python: Y_init = 10 * (Y - Y.min(0)) / (Y.max(0) - Y.min(0))
    y_init  <- 10.0 * sweep(sweep(y_raw, 2L, y_min, "-"), 2L, y_range, "/")

    umap_result <- tryCatch(
      uwot::umap(
        X,
        n_components  = d,
        n_epochs      = 11L,     # Python default um_epochs
        init          = y_init,
        min_dist      = 0.001,   # Python default um_min_dist
        learning_rate = 0.01,    # Python default um_lr
        verbose       = FALSE,
        n_threads     = 1L
      ),
      error = function(e) {
        warning("UMAP dispersion failed (", conditionMessage(e),
                "); returning raw SONG embedding.", call. = FALSE)
        NULL
      }
    )

    if (!is.null(umap_result)) {
      # Python rescales back:  output = (umap_out * Y_scale / 10) + Y_loc
      # We skip rescaling since the absolute scale doesn't matter for plots.
      result$embedding <- umap_result

      # Update CV positions to centroid of their assigned points
      Y_refined <- matrix(0.0, nrow = result$n_coding, ncol = d)
      for (cv in seq_len(result$n_coding)) {
        mask <- which(result$assignments == cv)
        if (length(mask) > 0L) {
          Y_refined[cv, ] <- colMeans(matrix(umap_result[mask, ], ncol = d))
        } else {
          Y_refined[cv, ] <- result$Y[cv, ]
        }
      }
      result$Y <- Y_refined
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

  new_song_model(result, parameters, n, D)
}
