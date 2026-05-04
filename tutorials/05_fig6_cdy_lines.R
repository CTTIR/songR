# ============================================================
# Tutorial 05: Figure 6 — CDY Line Plots
# ============================================================
# Reproduces Figure 6 from Senanayake et al. (2021) IEEE TNNLS.
# Quantitative companion to homogeneous increments: tracks
# displacement of existing points (CDY) as new data is added.
#
# Two panels: Fashion-MNIST and MNIST.
# Methods: SONG, SONG+Reinit, t-SNE, UMAP
# ============================================================

FAST_MODE <- TRUE

source("tutorials/utils_benchmarks.R")

library(songR)
library(ggplot2)
library(patchwork)

# ── Data ────────────────────────────────────────────────────
DATA_DIR  <- ".housekeeping/data/songR_ready"
OUT_DIR   <- "tutorials/output"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

fmnist_path <- file.path(DATA_DIR, "fashion_mnist_pca20.rds")
mnist_path  <- file.path(DATA_DIR, "mnist_pca20.rds")
require_data(fmnist_path)
require_data(mnist_path)

fmnist <- readRDS(fmnist_path)
mnist  <- readRDS(mnist_path)

cat("=== Figure 6: CDY Line Plots ===\n")
cat("FAST_MODE:", FAST_MODE, "\n\n")

# ── Parameters ──────────────────────────────────────────────
SEED <- 42L
EPOCHS_INIT <- if (FAST_MODE) 30L else 50L
EPOCHS_UPD  <- if (FAST_MODE) 20L else 50L

if (FAST_MODE) {
  start_n   <- 2000L
  step_n    <- 2000L
  n_increments <- 4L
} else {
  start_n   <- 6000L
  step_n    <- 6000L
  n_increments <- 8L
}

# ── CDY computation for one dataset ────────────────────────
compute_cdy_for_dataset <- function(dataset, dname) {
  cat("=== Processing:", dname, "===\n")

  set.seed(SEED)
  total_n <- start_n + n_increments * step_n
  idx <- sample(nrow(dataset$data), min(total_n, nrow(dataset$data)))
  X_full <- dataset$data[idx, , drop = FALSE]

  # Build step boundaries
  boundaries <- c(start_n, start_n + cumsum(rep(step_n, n_increments)))
  boundaries <- pmin(boundaries, length(idx))

  # Split into initial + increments
  X_init <- X_full[1:boundaries[1], , drop = FALSE]
  X_increments <- list()
  for (i in seq_len(n_increments)) {
    X_increments[[i]] <- X_full[(boundaries[i] + 1):boundaries[i + 1], , drop = FALSE]
  }

  cat("  Initial:", nrow(X_init), "pts, Increments:", n_increments,
      "x", step_n, "pts\n")

  results <- list()

  # ── SONG (incremental) ──
  cat("  SONG (incremental)...\n")
  song_cdy <- tryCatch({
    model <- songR::song(X_init, epochs = EPOCHS_INIT, seed = SEED, verbose = FALSE)
    prev_emb <- predict(model, newdata = X_full[1:boundaries[1], , drop = FALSE])
    cdys <- numeric(0)
    for (i in seq_len(n_increments)) {
      model <- update(model, X_increments[[i]], epochs = EPOCHS_UPD, verbose = FALSE)
      curr_emb <- predict(model, newdata = X_full[1:boundaries[i], , drop = FALSE])
      disp <- compute_cdy(prev_emb[1:boundaries[i], , drop = FALSE],
                          curr_emb[1:boundaries[i], , drop = FALSE])
      cdys <- c(cdys, mean(disp))
      prev_emb <- predict(model, newdata = X_full[1:boundaries[i + 1], , drop = FALSE])
    }
    cdys
  }, error = function(e) { cat("    ERROR:", conditionMessage(e), "\n"); rep(NA, n_increments) })

  # ── SONG+Reinit ──
  cat("  SONG+Reinit...\n")
  reinit_cdy <- tryCatch({
    model <- songR::song(X_init, epochs = EPOCHS_INIT, seed = SEED, verbose = FALSE)
    prev_emb <- model$embedding
    # For reinit, we need to re-embed all old points at each step
    cdys <- numeric(0)
    X_seen <- X_init
    for (i in seq_len(n_increments)) {
      X_seen <- rbind(X_seen, X_increments[[i]])
      model <- songR::song(X_seen, epochs = EPOCHS_INIT, seed = SEED, verbose = FALSE)
      curr_emb <- model$embedding
      n_old <- nrow(prev_emb)
      disp <- compute_cdy(prev_emb, curr_emb[1:n_old, , drop = FALSE])
      cdys <- c(cdys, mean(disp))
      prev_emb <- curr_emb
    }
    cdys
  }, error = function(e) { cat("    ERROR:", conditionMessage(e), "\n"); rep(NA, n_increments) })

  # ── t-SNE ──
  cat("  t-SNE...\n")
  tsne_cdy <- tryCatch({
    prev_emb <- run_tsne(X_init, seed = SEED)
    cdys <- numeric(0)
    X_seen <- X_init
    for (i in seq_len(n_increments)) {
      X_seen <- rbind(X_seen, X_increments[[i]])
      curr_emb <- run_tsne(X_seen, seed = SEED)
      n_old <- nrow(prev_emb)
      disp <- compute_cdy(prev_emb, curr_emb[1:n_old, , drop = FALSE])
      cdys <- c(cdys, mean(disp))
      prev_emb <- curr_emb
    }
    cdys
  }, error = function(e) { cat("    ERROR:", conditionMessage(e), "\n"); rep(NA, n_increments) })

  # ── UMAP ──
  cat("  UMAP...\n")
  umap_cdy <- tryCatch({
    prev_emb <- run_umap(X_init, seed = SEED)
    cdys <- numeric(0)
    X_seen <- X_init
    for (i in seq_len(n_increments)) {
      X_seen <- rbind(X_seen, X_increments[[i]])
      curr_emb <- run_umap(X_seen, seed = SEED)
      n_old <- nrow(prev_emb)
      disp <- compute_cdy(prev_emb, curr_emb[1:n_old, , drop = FALSE])
      cdys <- c(cdys, mean(disp))
      prev_emb <- curr_emb
    }
    cdys
  }, error = function(e) { cat("    ERROR:", conditionMessage(e), "\n"); rep(NA, n_increments) })

  # Combine into data frame
  step_ids <- seq_len(n_increments)
  data.frame(
    dataset = dname,
    step = rep(step_ids, 4),
    method = rep(c("SONG", "SONG+Reinit", "t-SNE", "UMAP"), each = n_increments),
    mean_cdy = c(song_cdy, reinit_cdy, tsne_cdy, umap_cdy),
    sd_cdy = 0  # single-run SD; expand with multiple seeds for error ribbons
  )
}

# ── Run for both datasets ──────────────────────────────────
cdy_fmnist <- compute_cdy_for_dataset(fmnist, "Fashion-MNIST")
cdy_mnist  <- compute_cdy_for_dataset(mnist, "MNIST")

cdy_all <- rbind(cdy_fmnist, cdy_mnist)

# ── Print results ──────────────────────────────────────────
cat("\n=== CDY Results ===\n")
for (ds in c("Fashion-MNIST", "MNIST")) {
  cat("\n", ds, ":\n")
  sub <- cdy_all[cdy_all$dataset == ds, ]
  for (meth in unique(sub$method)) {
    vals <- sub$mean_cdy[sub$method == meth]
    cat(sprintf("  %s: %s\n", meth,
                paste(round(vals, 2), collapse = " -> ")))
  }
}

# ── Build two-panel line plot ──────────────────────────────
cat("\n--- Building figure ---\n")

p_fmnist <- plot_cdy_lines(cdy_fmnist) +
  ggtitle("Fashion-MNIST") +
  theme(legend.position = "none")

p_mnist <- plot_cdy_lines(cdy_mnist) +
  ggtitle("MNIST")

combined <- p_fmnist + p_mnist +
  plot_annotation(
    title = "Figure 6: CDY (Consecutive Displacement of Y)",
    subtitle = paste0("Start: ", start_n, " pts, add ", step_n,
                      " per step | ",
                      if (FAST_MODE) "FAST_MODE" else "Full data"),
    theme = theme(plot.title = element_text(size = 14, face = "bold"),
                  plot.subtitle = element_text(size = 10))
  ) +
  plot_layout(guides = "collect")

# ── Save ────────────────────────────────────────────────────
out_file <- file.path(OUT_DIR, "fig6_cdy_lines.pdf")
ggsave(out_file, combined, width = 12, height = 5)
cat("Saved:", out_file, "\n")

cat("\n=== Summary ===\n")
cat("Datasets: Fashion-MNIST, MNIST (PCA-20)\n")
cat("Start:", start_n, "pts, increment:", step_n, "pts x", n_increments, "steps\n")
cat("Output:", normalizePath(out_file, mustWork = FALSE), "\n")
cat("Done.\n")
