# ============================================================
# songR Benchmark Utilities
# ============================================================
# Shared helper functions for all tutorial scripts.
# Source this file at the top of every tutorial:
#   source("tutorials/utils_benchmarks.R")
# ============================================================

# ── AMI computation ──────────────────────────────────────────
#' Run k-means on 2D embedding, compute AMI against true labels
#' @param embedding matrix (n x 2)
#' @param labels_true factor or integer vector of true labels
#' @param k number of k-means clusters (default: number of unique labels)
#' @param n_init number of random starts to average over (default: 5)
#' @return numeric, mean AMI across n_init runs (scaled 0-100 to match paper)
compute_ami <- function(embedding, labels_true, k = NULL, n_init = 5L) {
  if (!requireNamespace("aricode", quietly = TRUE)) {
    stop("Package 'aricode' required for AMI computation. ",
         "Install with: install.packages('aricode')")
  }
  if (is.null(k)) k <- length(unique(labels_true))
  amis <- vapply(seq_len(n_init), function(i) {
    km <- tryCatch(
      stats::kmeans(embedding, centers = k, nstart = 1, iter.max = 100,
                    algorithm = "Hartigan-Wong"),
      warning = function(w) {
        stats::kmeans(embedding, centers = k, nstart = 1, iter.max = 100,
                      algorithm = "Lloyd")
      }
    )
    aricode::AMI(as.integer(factor(labels_true)), km$cluster)
  }, numeric(1))
  mean(amis) * 100
}

# ── CDY computation ──────────────────────────────────────────
#' Consecutive Displacement of Y
#' @param emb_before matrix (n x d) embedding BEFORE new data added
#' @param emb_after matrix (n x d) embedding AFTER new data added (same n rows)
#' @return numeric vector of per-point displacements
compute_cdy <- function(emb_before, emb_after) {
  stopifnot(nrow(emb_before) == nrow(emb_after))
  sqrt(rowSums((emb_after - emb_before)^2))
}

# ── Gaussian blobs simulator ─────────────────────────────────
#' Simulate Gaussian blobs (matching paper Section IV-C)
#' @param n_clusters integer
#' @param cluster_sd numeric, standard deviation per cluster
#' @param n_dim integer, dimensionality
#' @param n_per_cluster integer, points per cluster (default: 500)
#' @param center_sd numeric, spread of cluster centers (default: 30)
#' @param seed integer
#' @return list(data = matrix, labels = factor)
simulate_gaussian_blobs <- function(n_clusters, cluster_sd, n_dim,
                                     n_per_cluster = 500L, center_sd = 30,
                                     seed = 42L) {
  set.seed(seed)
  data_list <- lapply(seq_len(n_clusters), function(i) {
    center <- stats::rnorm(n_dim, sd = center_sd)
    sweep(matrix(stats::rnorm(n_per_cluster * n_dim, sd = cluster_sd),
                 ncol = n_dim), 2, center, "+")
  })
  list(
    data = do.call(rbind, data_list),
    labels = factor(rep(seq_len(n_clusters), each = n_per_cluster))
  )
}

# ── Wong CyTOF simulator (fallback) ─────────────────────────
simulate_wong_data <- function(n = 327000, D = 39, n_clusters = 12, seed = 2016) {
  set.seed(seed)
  cluster_props <- c(0.15, 0.12, 0.11, 0.10, 0.09, 0.08, 0.07, 0.06,
                     0.06, 0.06, 0.05, 0.05)
  cluster_sizes <- round(n * cluster_props)
  cluster_sizes[1] <- n - sum(cluster_sizes[-1])

  data <- do.call(rbind, lapply(seq_len(n_clusters), function(i) {
    center <- rnorm(D, mean = rnorm(1, 0, 3), sd = 0.5)
    spread <- runif(1, 0.3, 1.8)
    sweep(matrix(rnorm(cluster_sizes[i] * D, sd = spread), ncol = D),
          2, center, "+")
  }))

  ccr7_base <- rep(c(3, 2.5, 2, 1.5, 1, 0.5, 0, -0.5, -1, -1.5, -2, -2.5),
                    cluster_sizes)
  ccr7 <- ccr7_base + rnorm(n, sd = 0.5)

  list(data = data, ccr7 = ccr7,
       cluster_id = factor(rep(seq_len(n_clusters), cluster_sizes)),
       labels = factor(rep(seq_len(n_clusters), cluster_sizes)),
       simulated = TRUE)
}

# ── COIL-20 simulator (fallback) ─────────────────────────────
simulate_coil20 <- function(n_objects = 20, n_poses = 72, D = 300, seed = 1996) {
  set.seed(seed)
  data_list <- lapply(seq_len(n_objects), function(obj) {
    angles <- seq(0, 2 * pi, length.out = n_poses + 1)[-(n_poses + 1)]
    basis1 <- rnorm(D); basis1 <- basis1 / sqrt(sum(basis1^2))
    basis2 <- rnorm(D); basis2 <- basis2 - sum(basis2 * basis1) * basis1
    basis2 <- basis2 / sqrt(sum(basis2^2))
    center <- rnorm(D, sd = 5)
    radius <- runif(1, 1, 3)
    sweep(radius * (outer(cos(angles), basis1) + outer(sin(angles), basis2)),
          2, center, "+") + matrix(rnorm(n_poses * D, sd = 0.1), ncol = D)
  })
  list(data = do.call(rbind, data_list),
       labels = factor(rep(seq_len(n_objects), each = n_poses)),
       simulated = TRUE)
}

# ── Method wrappers ──────────────────────────────────────────
#' Run SONG incrementally on a list of data matrices
#' @param X_list list of matrices, presented sequentially
#' @param reinit if TRUE, reinitialize model at each step (SONG+Reinit)
#' @param ... passed to songR::song()
#' @return list of embeddings (one per step, covering ALL data seen so far)
run_song_incremental <- function(X_list, reinit = FALSE, ...) {
  embeddings <- vector("list", length(X_list))
  model <- NULL
  X_seen <- NULL

  for (i in seq_along(X_list)) {
    X_seen <- rbind(X_seen, X_list[[i]])

    if (reinit || is.null(model)) {
      model <- songR::song(X_seen, verbose = FALSE, ...)
    } else {
      model <- update(model, X_list[[i]], verbose = FALSE)
    }

    embeddings[[i]] <- predict(model, newdata = X_seen)
  }
  embeddings
}

#' UMAP wrapper
run_umap <- function(X, seed = 42L, ...) {
  set.seed(seed)
  uwot::umap(X, n_neighbors = 15L, min_dist = 0.1,
             n_epochs = 200, verbose = FALSE, ...)
}

#' t-SNE wrapper
run_tsne <- function(X, perplexity = 30, seed = 42L, ...) {
  set.seed(seed)
  perp <- min(perplexity, floor((nrow(X) - 1) / 3))
  Rtsne::Rtsne(X, dims = 2, perplexity = perp,
               verbose = FALSE, max_iter = 1000,
               check_duplicates = FALSE, ...)$Y
}

# ── Plotting ─────────────────────────────────────────────────
#' Standard embedding scatter plot using ggplot2
#' @param emb matrix (n x 2)
#' @param labels factor/character for discrete coloring, or numeric for continuous
#' @param title plot title
#' @param point_size cex equivalent (default: 0.3)
#' @return ggplot object
plot_embedding <- function(emb, labels = NULL, title = "", point_size = 0.3) {
  df <- data.frame(x = emb[, 1], y = emb[, 2])

  if (!is.null(labels)) {
    df$label <- labels
    if (is.numeric(labels) && !is.factor(labels)) {
      p <- ggplot2::ggplot(df, ggplot2::aes(x, y, color = label)) +
        ggplot2::geom_point(size = point_size, alpha = 0.6) +
        viridis::scale_color_viridis(option = "C")
    } else {
      n_levels <- length(unique(labels))
      p <- ggplot2::ggplot(df, ggplot2::aes(x, y, color = factor(label))) +
        ggplot2::geom_point(size = point_size, alpha = 0.6) +
        viridis::scale_color_viridis(discrete = TRUE, option = "C",
                                      end = 0.92)
    }
  } else {
    p <- ggplot2::ggplot(df, ggplot2::aes(x, y)) +
      ggplot2::geom_point(size = point_size, alpha = 0.6, color = "#B12A90")
  }

  p + ggplot2::labs(title = title, x = "", y = "") +
    ggplot2::theme_minimal(base_size = 8) +
    ggplot2::theme(
      legend.position = "none",
      plot.title = ggplot2::element_text(size = 9, hjust = 0.5),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank()
    )
}

#' CDY line plot with error bands
plot_cdy_lines <- function(cdy_df) {
  method_colors <- c("SONG" = "#0D0887", "SONG+Reinit" = "#7E03A8",
                     "t-SNE" = "#CC4678", "UMAP" = "#F89441")
  ggplot2::ggplot(cdy_df, ggplot2::aes(x = step, y = mean_cdy,
                                         color = method, fill = method)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = pmax(mean_cdy - sd_cdy, 0),
                                       ymax = mean_cdy + sd_cdy),
                          alpha = 0.2, color = NA) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_color_manual(values = method_colors) +
    ggplot2::scale_fill_manual(values = method_colors) +
    ggplot2::labs(x = "Increment", y = "Mean CDY +/- SD", color = "Method",
                  fill = "Method") +
    ggplot2::theme_minimal()
}

# ── Timing wrapper ───────────────────────────────────────────
#' Time a method call, return list(result, elapsed_sec)
time_method <- function(expr) {
  timing <- system.time(result <- expr)
  list(result = result, elapsed = as.numeric(timing["elapsed"]))
}

# ── Data loading helpers ─────────────────────────────────────
#' Check for required data file, stop with message if missing
require_data <- function(path, script_name = "01_prepare_data.R") {
  if (!file.exists(path)) {
    stop("Data file not found: ", path, "\n",
         "Run tutorials/", script_name, " first.",
         call. = FALSE)
  }
}

cat("utils_benchmarks.R loaded.\n")
