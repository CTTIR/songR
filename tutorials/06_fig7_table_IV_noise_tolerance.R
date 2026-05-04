# ============================================================
# Tutorial 06: Figure 7 + Table IV — Gaussian Blobs Noise Tolerance
# ============================================================
# Reproduces Figure 7 and Table IV from Senanayake et al. (2021).
# 32 datasets: 8 stds x 4 cluster counts, all 60D.
# Compute AMI for each configuration x method.
#
# Output:
#   - CSV table of AMI scores
#   - Scatter plot PDF for (100 clusters, std=10, 60D)
# ============================================================

FAST_MODE <- TRUE

source("tutorials/utils_benchmarks.R")

library(songR)
library(ggplot2)
library(patchwork)

# ── Output ──────────────────────────────────────────────────
OUT_DIR <- "tutorials/output"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

cat("=== Figure 7 + Table IV: Gaussian Blobs Noise Tolerance ===\n")
cat("FAST_MODE:", FAST_MODE, "\n\n")

# ── Parameters ──────────────────────────────────────────────
SEED <- 42L
N_DIM <- 60L
EPOCHS <- if (FAST_MODE) 30L else 50L

if (FAST_MODE) {
  stds <- c(4, 10, 16, 20)
  n_clusters_vec <- c(10, 50, 100)
  pts_per_cluster <- 50L
} else {
  stds <- c(4, 8, 10, 12, 14, 16, 18, 20)
  n_clusters_vec <- c(10, 20, 50, 100)
  pts_per_cluster <- 500L
}

cat("Stds:", paste(stds, collapse = ", "), "\n")
cat("Cluster counts:", paste(n_clusters_vec, collapse = ", "), "\n")
cat("Points/cluster:", pts_per_cluster, "\n")
cat("Dimensions:", N_DIM, "\n\n")

# ── Run all configurations ──────────────────────────────────
results <- list()
config_idx <- 0

total_configs <- length(stds) * length(n_clusters_vec)
cat("Total configurations:", total_configs, "\n\n")

for (nc in n_clusters_vec) {
  for (sd_val in stds) {
    config_idx <- config_idx + 1
    cat(sprintf("[%d/%d] k=%d, std=%d ...\n", config_idx, total_configs, nc, sd_val))

    # Generate blobs
    blobs <- simulate_gaussian_blobs(
      n_clusters = nc, cluster_sd = sd_val, n_dim = N_DIM,
      n_per_cluster = pts_per_cluster, seed = SEED
    )
    X <- blobs$data
    true_labels <- blobs$labels

    # SONG
    ami_song <- tryCatch({
      model <- songR::song(X, epochs = EPOCHS, seed = SEED, verbose = FALSE)
      compute_ami(model$embedding, true_labels, k = nc)
    }, error = function(e) { cat("  SONG error:", conditionMessage(e), "\n"); NA })

    # t-SNE
    ami_tsne <- tryCatch({
      emb <- run_tsne(X, seed = SEED)
      compute_ami(emb, true_labels, k = nc)
    }, error = function(e) { cat("  t-SNE error:", conditionMessage(e), "\n"); NA })

    # UMAP
    ami_umap <- tryCatch({
      emb <- run_umap(X, seed = SEED)
      compute_ami(emb, true_labels, k = nc)
    }, error = function(e) { cat("  UMAP error:", conditionMessage(e), "\n"); NA })

    results[[config_idx]] <- data.frame(
      n_clusters = nc, std = sd_val,
      SONG = round(ami_song, 1),
      tSNE = round(ami_tsne, 1),
      UMAP = round(ami_umap, 1)
    )

    cat(sprintf("  AMI: SONG=%.1f, t-SNE=%.1f, UMAP=%.1f\n",
                ami_song, ami_tsne, ami_umap))
  }
}

results_df <- do.call(rbind, results)

# ── Print Table IV ──────────────────────────────────────────
cat("\n=== Table IV: AMI Scores (0-100) ===\n")
print(results_df, row.names = FALSE)

# ── Save CSV ────────────────────────────────────────────────
csv_file <- file.path(OUT_DIR, "table_IV_noise_tolerance.csv")
write.csv(results_df, csv_file, row.names = FALSE)
cat("\nSaved CSV:", csv_file, "\n")

# ── Scatter plot for (100 clusters, std=10, 60D) ───────────
cat("\n--- Building scatter plot (k=100, std=10) ---\n")

blobs_plot <- simulate_gaussian_blobs(
  n_clusters = 100, cluster_sd = 10, n_dim = N_DIM,
  n_per_cluster = pts_per_cluster, seed = SEED
)
X_plot <- blobs_plot$data
labels_plot <- blobs_plot$labels

# SONG
p_song <- tryCatch({
  model <- songR::song(X_plot, epochs = EPOCHS, seed = SEED, verbose = FALSE)
  ami <- compute_ami(model$embedding, labels_plot, k = 100)
  plot_embedding(model$embedding, labels = labels_plot,
                 title = sprintf("SONG (AMI=%.1f)", ami), point_size = 0.3)
}, error = function(e) {
  ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Failed") +
    theme_void() + ggtitle("SONG")
})

# t-SNE
p_tsne <- tryCatch({
  emb <- run_tsne(X_plot, seed = SEED)
  ami <- compute_ami(emb, labels_plot, k = 100)
  plot_embedding(emb, labels = labels_plot,
                 title = sprintf("t-SNE (AMI=%.1f)", ami), point_size = 0.3)
}, error = function(e) {
  ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Failed") +
    theme_void() + ggtitle("t-SNE")
})

# UMAP
p_umap <- tryCatch({
  emb <- run_umap(X_plot, seed = SEED)
  ami <- compute_ami(emb, labels_plot, k = 100)
  plot_embedding(emb, labels = labels_plot,
                 title = sprintf("UMAP (AMI=%.1f)", ami), point_size = 0.3)
}, error = function(e) {
  ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Failed") +
    theme_void() + ggtitle("UMAP")
})

combined <- p_song + p_tsne + p_umap +
  plot_annotation(
    title = "Figure 7: Gaussian Blobs (k=100, std=10, 60D)",
    subtitle = paste0(pts_per_cluster, " pts/cluster | ",
                      if (FAST_MODE) "FAST_MODE" else "Full data"),
    theme = theme(plot.title = element_text(size = 14, face = "bold"),
                  plot.subtitle = element_text(size = 10))
  )

out_file <- file.path(OUT_DIR, "fig7_noise_tolerance.pdf")
ggsave(out_file, combined, width = 14, height = 5)
cat("Saved:", out_file, "\n")

# ── Summary ─────────────────────────────────────────────────
cat("\n=== Summary ===\n")
cat("Configs tested:", nrow(results_df), "\n")

# Mean AMI by method
cat("Mean AMI across all configs:\n")
cat(sprintf("  SONG:  %.1f\n", mean(results_df$SONG, na.rm = TRUE)))
cat(sprintf("  t-SNE: %.1f\n", mean(results_df$tSNE, na.rm = TRUE)))
cat(sprintf("  UMAP:  %.1f\n", mean(results_df$UMAP, na.rm = TRUE)))

cat("CSV output:", normalizePath(csv_file, mustWork = FALSE), "\n")
cat("PDF output:", normalizePath(out_file, mustWork = FALSE), "\n")
cat("Done.\n")
