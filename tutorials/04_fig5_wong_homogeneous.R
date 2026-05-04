# ============================================================
# Tutorial 04: Figure 5 — Wong CyTOF Homogeneous Increments
# ============================================================
# Reproduces Figure 5 from Senanayake et al. (2021) IEEE TNNLS.
# Wong CyTOF data with random nested subsamples (homogeneous):
# all cell types present at every step, growing sample size.
#
# Color by CCR7 expression (continuous viridis scale).
#
# Methods: SONG (incremental), SONG+Reinit, t-SNE, UMAP
# ============================================================

FAST_MODE <- TRUE

source("tutorials/utils_benchmarks.R")

library(songR)
library(ggplot2)
library(patchwork)
library(viridis)

# ── Data ────────────────────────────────────────────────────
DATA_DIR  <- ".housekeeping/data/songR_ready"
OUT_DIR   <- "tutorials/output"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

wong_path <- file.path(DATA_DIR, "wong_logicle.rds")
require_data(wong_path)
wong <- readRDS(wong_path)

cat("=== Figure 5: Wong CyTOF Homogeneous Increments ===\n")
cat("FAST_MODE:", FAST_MODE, "\n")
cat("Data dimensions:", nrow(wong$data), "x", ncol(wong$data), "\n")
if (isTRUE(wong$simulated)) cat("NOTE: Using simulated Wong-like data.\n")

# ── Parameters ──────────────────────────────────────────────
SEED <- 42L
EPOCHS_INIT <- if (FAST_MODE) 30L else 50L
EPOCHS_UPD  <- if (FAST_MODE) 20L else 50L

if (FAST_MODE) {
  step_sizes <- c(5000L, 10000L, 25000L, 50000L)
} else {
  step_sizes <- c(10000L, 20000L, 50000L, nrow(wong$data))
}
# Clamp to available data
step_sizes <- pmin(step_sizes, nrow(wong$data))
step_labels <- paste0("n=", format(step_sizes, big.mark = ","))
n_steps <- length(step_sizes)

cat("Step sizes:", paste(step_sizes, collapse = " -> "), "\n\n")

# ── Build nested subsamples ─────────────────────────────────
set.seed(SEED)
# Take the largest sample, then nest subsets
max_n <- max(step_sizes)
idx_all <- sample(nrow(wong$data), min(max_n, nrow(wong$data)))

X_list <- list()
ccr7_list <- list()
prev_n <- 0L

for (s in seq_along(step_sizes)) {
  n_s <- step_sizes[s]
  idx_s <- idx_all[1:n_s]

  if (prev_n == 0) {
    X_list[[s]] <- wong$data[idx_s, , drop = FALSE]
  } else {
    new_idx <- idx_s[(prev_n + 1):n_s]
    X_list[[s]] <- wong$data[new_idx, , drop = FALSE]
  }
  ccr7_list[[s]] <- wong$ccr7[idx_s[1:n_s]]
  prev_n <- n_s
}

# Cumulative CCR7 for coloring
cum_ccr7 <- list()
for (s in seq_along(step_sizes)) {
  cum_ccr7[[s]] <- wong$ccr7[idx_all[1:step_sizes[s]]]
}

cat("Points per increment:", sapply(X_list, nrow), "\n")
cat("Cumulative points:", sapply(cum_ccr7, length), "\n\n")

# ── Method: SONG (incremental) ──────────────────────────────
cat("--- SONG (incremental) ---\n")
song_embs <- tryCatch({
  model <- NULL
  embs <- vector("list", n_steps)
  X_seen <- NULL
  for (s in seq_along(X_list)) {
    X_seen <- rbind(X_seen, X_list[[s]])
    cat("  Step", s, ": n =", nrow(X_seen), "...")
    t0 <- proc.time()
    if (is.null(model)) {
      model <- songR::song(X_seen, epochs = EPOCHS_INIT, seed = SEED, verbose = FALSE)
    } else {
      model <- update(model, X_list[[s]], epochs = EPOCHS_UPD, verbose = FALSE)
    }
    embs[[s]] <- predict(model, newdata = X_seen)
    cat(" done (", round((proc.time() - t0)["elapsed"], 1), "s)\n")
  }
  embs
}, error = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL })

# ── Method: SONG+Reinit ────────────────────────────────────
cat("--- SONG+Reinit ---\n")
reinit_embs <- tryCatch({
  embs <- vector("list", n_steps)
  X_seen <- NULL
  for (s in seq_along(X_list)) {
    X_seen <- rbind(X_seen, X_list[[s]])
    cat("  Step", s, ": n =", nrow(X_seen), "...")
    t0 <- proc.time()
    model <- songR::song(X_seen, epochs = EPOCHS_INIT, seed = SEED, verbose = FALSE)
    embs[[s]] <- model$embedding
    cat(" done (", round((proc.time() - t0)["elapsed"], 1), "s)\n")
  }
  embs
}, error = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL })

# ── Method: t-SNE ──────────────────────────────────────────
cat("--- t-SNE ---\n")
tsne_embs <- tryCatch({
  embs <- vector("list", n_steps)
  X_seen <- NULL
  for (s in seq_along(X_list)) {
    X_seen <- rbind(X_seen, X_list[[s]])
    cat("  Step", s, ": n =", nrow(X_seen), "...")
    t0 <- proc.time()
    embs[[s]] <- run_tsne(X_seen, seed = SEED)
    cat(" done (", round((proc.time() - t0)["elapsed"], 1), "s)\n")
  }
  embs
}, error = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL })

# ── Method: UMAP ──────────────────────────────────────────
cat("--- UMAP ---\n")
umap_embs <- tryCatch({
  embs <- vector("list", n_steps)
  X_seen <- NULL
  for (s in seq_along(X_list)) {
    X_seen <- rbind(X_seen, X_list[[s]])
    cat("  Step", s, ": n =", nrow(X_seen), "...")
    t0 <- proc.time()
    embs[[s]] <- run_umap(X_seen, seed = SEED)
    cat(" done (", round((proc.time() - t0)["elapsed"], 1), "s)\n")
  }
  embs
}, error = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL })

# ── Build 4x4 grid ─────────────────────────────────────────
cat("\n--- Building figure ---\n")
methods <- list(
  list(name = "SONG", embs = song_embs),
  list(name = "SONG+Reinit", embs = reinit_embs),
  list(name = "t-SNE", embs = tsne_embs),
  list(name = "UMAP", embs = umap_embs)
)

plots <- list()
for (m in seq_along(methods)) {
  for (s in seq_along(step_sizes)) {
    title <- if (m == 1) step_labels[s] else ""
    ylabel <- if (s == 1) methods[[m]]$name else ""

    if (!is.null(methods[[m]]$embs)) {
      # Color by CCR7 (continuous)
      p <- plot_embedding(methods[[m]]$embs[[s]],
                          labels = cum_ccr7[[s]],
                          title = title,
                          point_size = 0.15)
    } else {
      p <- ggplot() +
        annotate("text", x = 0.5, y = 0.5, label = "Failed") +
        theme_void() + ggtitle(title)
    }

    if (s == 1) {
      p <- p + labs(y = ylabel) +
        theme(axis.title.y = element_text(size = 9, angle = 90))
    }

    plots <- c(plots, list(p))
  }
}

combined <- wrap_plots(plots, ncol = n_steps, nrow = 4) +
  plot_annotation(
    title = "Figure 5: Wong CyTOF Homogeneous Increments",
    subtitle = paste0("Nested random subsamples, colored by CCR7 expression | ",
                      if (FAST_MODE) "FAST_MODE" else "Full data",
                      if (isTRUE(wong$simulated)) " (simulated)" else ""),
    theme = theme(plot.title = element_text(size = 14, face = "bold"),
                  plot.subtitle = element_text(size = 10))
  )

# ── Save ────────────────────────────────────────────────────
out_file <- file.path(OUT_DIR, "fig5_wong_homogeneous.pdf")
ggsave(out_file, combined, width = 14, height = 12)
cat("Saved:", out_file, "\n")

cat("\n=== Summary ===\n")
cat("Dataset: Wong CyTOF", if (isTRUE(wong$simulated)) "(simulated)" else "", "\n")
cat("Steps:", paste(step_sizes, collapse = " -> "), "\n")
cat("Color: CCR7 expression (continuous viridis)\n")
cat("Output:", normalizePath(out_file, mustWork = FALSE), "\n")
cat("Done.\n")
