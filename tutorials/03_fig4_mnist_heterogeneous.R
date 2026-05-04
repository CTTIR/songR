# ============================================================
# Tutorial 03: Figure 4 — MNIST Heterogeneous Increments
# ============================================================
# Reproduces Figure 4 from Senanayake et al. (2021) IEEE TNNLS.
# MNIST digits with 2 classes added per step (heterogeneous).
# 5 panels at 2/4/6/8/10 classes for each method.
#
# Additional analysis: pairwise centroid distances showing
# digit "1" is closer to "7" than to "3" in embedding space.
#
# Methods: SONG (incremental), SONG+Reinit, t-SNE, UMAP
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

mnist_path <- file.path(DATA_DIR, "mnist_pca20.rds")
require_data(mnist_path)
mnist <- readRDS(mnist_path)

cat("=== Figure 4: MNIST Heterogeneous Increments ===\n")
cat("FAST_MODE:", FAST_MODE, "\n")

# ── Parameters ──────────────────────────────────────────────
pts_per_class <- if (FAST_MODE) 1000L else 6000L
SEED <- 42L
EPOCHS_INIT <- if (FAST_MODE) 30L else 50L
EPOCHS_UPD  <- if (FAST_MODE) 20L else 50L

# ── Class ordering (random but reproducible) ────────────────
set.seed(SEED)
all_classes <- sort(unique(mnist$labels))  # 0..9
class_order <- sample(all_classes)
cat("Class addition order:", paste(class_order, collapse = " -> "), "\n")

steps <- list(
  class_order[1:2],
  class_order[3:4],
  class_order[5:6],
  class_order[7:8],
  class_order[9:10]
)
step_labels <- c("2 classes", "4 classes", "6 classes", "8 classes", "10 classes")

# ── Build data list for each step ───────────────────────────
set.seed(SEED)
X_list <- list()
lab_list <- list()

for (s in seq_along(steps)) {
  new_classes <- steps[[s]]
  idx_new <- which(mnist$labels %in% new_classes)
  if (length(idx_new) > pts_per_class * length(new_classes)) {
    idx_new <- sample(idx_new, pts_per_class * length(new_classes))
  }
  X_list[[s]] <- mnist$data[idx_new, , drop = FALSE]
  lab_list[[s]] <- mnist$labels[idx_new]
}

cum_labels <- list()
for (s in seq_along(steps)) {
  cum_labels[[s]] <- unlist(lab_list[1:s])
}

cat("Points per step:", sapply(X_list, nrow), "\n")
cat("Cumulative points:", sapply(cum_labels, length), "\n\n")

# ── Method: SONG (incremental) ──────────────────────────────
cat("--- SONG (incremental) ---\n")
song_embs <- tryCatch({
  model <- NULL
  embs <- vector("list", length(X_list))
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
  embs <- vector("list", length(X_list))
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
  embs <- vector("list", length(X_list))
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
  embs <- vector("list", length(X_list))
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

# ── Centroid distance analysis ──────────────────────────────
cat("\n--- Centroid Distance Analysis ---\n")
cat("Checking: is digit '1' closer to '7' than to '3' in embedding space?\n\n")

compute_centroids <- function(emb, labels) {
  ul <- sort(unique(labels))
  centroids <- t(sapply(ul, function(l) colMeans(emb[labels == l, , drop = FALSE])))
  rownames(centroids) <- ul
  centroids
}

# Use final step (all 10 classes) for each method
final_methods <- list(
  SONG = song_embs, `SONG+Reinit` = reinit_embs,
  `t-SNE` = tsne_embs, UMAP = umap_embs
)

for (mname in names(final_methods)) {
  embs <- final_methods[[mname]]
  if (is.null(embs)) { cat(mname, ": skipped (failed)\n"); next }

  final_emb <- embs[[5]]
  final_lab <- cum_labels[[5]]

  if (!all(c(1, 3, 7) %in% final_lab)) {
    cat(mname, ": digits 1, 3, 7 not all present in final step\n")
    next
  }

  centroids <- compute_centroids(final_emb, final_lab)

  if (all(c("1", "3", "7") %in% rownames(centroids))) {
    d_1_7 <- sqrt(sum((centroids["1", ] - centroids["7", ])^2))
    d_1_3 <- sqrt(sum((centroids["1", ] - centroids["3", ])^2))
    cat(sprintf("  %s: d(1,7) = %.2f, d(1,3) = %.2f => '1' closer to '%s'\n",
                mname, d_1_7, d_1_3, if (d_1_7 < d_1_3) "7" else "3"))
  }
}

# ── Build 4x5 grid ─────────────────────────────────────────
cat("\n--- Building figure ---\n")
methods <- list(
  list(name = "SONG", embs = song_embs),
  list(name = "SONG+Reinit", embs = reinit_embs),
  list(name = "t-SNE", embs = tsne_embs),
  list(name = "UMAP", embs = umap_embs)
)

plots <- list()
for (m in seq_along(methods)) {
  for (s in seq_along(steps)) {
    title <- if (m == 1) step_labels[s] else ""
    ylabel <- if (s == 1) methods[[m]]$name else ""

    if (!is.null(methods[[m]]$embs)) {
      p <- plot_embedding(methods[[m]]$embs[[s]],
                          labels = factor(cum_labels[[s]]),
                          title = title,
                          point_size = 0.2)
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

combined <- wrap_plots(plots, ncol = 5, nrow = 4) +
  plot_annotation(
    title = "Figure 4: MNIST Heterogeneous Increments",
    subtitle = paste0("2 classes added per step | ",
                      if (FAST_MODE) paste0(pts_per_class, " pts/class (FAST_MODE)") else "Full data"),
    theme = theme(plot.title = element_text(size = 14, face = "bold"),
                  plot.subtitle = element_text(size = 10))
  )

# ── Save ────────────────────────────────────────────────────
out_file <- file.path(OUT_DIR, "fig4_mnist_heterogeneous.pdf")
ggsave(out_file, combined, width = 16, height = 12)
cat("Saved:", out_file, "\n")

cat("\n=== Summary ===\n")
cat("Dataset: MNIST (PCA-20)\n")
cat("Class order:", paste(class_order, collapse = " -> "), "\n")
cat("Steps: 2 -> 4 -> 6 -> 8 -> 10 classes\n")
cat("Points per class:", pts_per_class, "\n")
cat("Output:", normalizePath(out_file, mustWork = FALSE), "\n")
cat("Done.\n")
