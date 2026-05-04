# ============================================================
# Tutorial 13: Extra — Runtime Scaling Benchmark
# ============================================================
# Measures wall-clock time for SONG, t-SNE, and UMAP as
# dataset size grows. Reports both absolute time and
# scaling behavior.
#
# Uses synthetic Gaussian blobs for controlled comparison.
# ============================================================

FAST_MODE <- TRUE

source("tutorials/utils_benchmarks.R")

library(songR)
library(ggplot2)

# ── Output ──────────────────────────────────────────────────
OUT_DIR <- "tutorials/output"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

cat("=== Extra: Runtime Scaling Benchmark ===\n")
cat("FAST_MODE:", FAST_MODE, "\n\n")

# ── Parameters ──────────────────────────────────────────────
SEED <- 42L
N_DIM <- 20L
N_CLUSTERS <- 10L

if (FAST_MODE) {
  sample_sizes <- c(500L, 1000L, 2000L, 5000L, 10000L)
  EPOCHS <- 30L
} else {
  sample_sizes <- c(1000L, 2000L, 5000L, 10000L, 20000L, 50000L)
  EPOCHS <- 50L
}

cat("Sample sizes:", paste(sample_sizes, collapse = ", "), "\n")
cat("Dimensions:", N_DIM, "\n\n")

# ── Run benchmarks ─────────────────────────────────────────
results <- list()

for (n in sample_sizes) {
  cat(sprintf("n = %d ...\n", n))

  # Generate data
  blobs <- simulate_gaussian_blobs(
    n_clusters = N_CLUSTERS, cluster_sd = 5, n_dim = N_DIM,
    n_per_cluster = ceiling(n / N_CLUSTERS), seed = SEED
  )
  X <- blobs$data[1:min(n, nrow(blobs$data)), , drop = FALSE]

  # SONG
  t_song <- tryCatch({
    tm <- time_method(songR::song(X, epochs = EPOCHS, seed = SEED, verbose = FALSE))
    cat(sprintf("  SONG:  %.2fs (CVs: %d)\n", tm$elapsed, nrow(tm$result$C)))
    tm$elapsed
  }, error = function(e) { cat("  SONG: FAILED\n"); NA })

  # t-SNE
  t_tsne <- tryCatch({
    tm <- time_method(run_tsne(X, seed = SEED))
    cat(sprintf("  t-SNE: %.2fs\n", tm$elapsed))
    tm$elapsed
  }, error = function(e) { cat("  t-SNE: FAILED\n"); NA })

  # UMAP
  t_umap <- tryCatch({
    tm <- time_method(run_umap(X, seed = SEED))
    cat(sprintf("  UMAP:  %.2fs\n", tm$elapsed))
    tm$elapsed
  }, error = function(e) { cat("  UMAP: FAILED\n"); NA })

  results[[length(results) + 1]] <- data.frame(
    n = nrow(X),
    SONG = round(t_song, 3),
    tSNE = round(t_tsne, 3),
    UMAP = round(t_umap, 3)
  )
}

results_df <- do.call(rbind, results)
rownames(results_df) <- NULL

# ── Print results ──────────────────────────────────────────
cat("\n=== Runtime Results (seconds) ===\n")
print(results_df, row.names = FALSE)

# ── Save CSV ───────────────────────────────────────────────
csv_file <- file.path(OUT_DIR, "runtime_benchmark.csv")
write.csv(results_df, csv_file, row.names = FALSE)
cat("Saved CSV:", csv_file, "\n")

# ── Build line plot ────────────────────────────────────────
cat("\n--- Building runtime scaling plot ---\n")

# Reshape to long format
long_df <- data.frame(
  n = rep(results_df$n, 3),
  time = c(results_df$SONG, results_df$tSNE, results_df$UMAP),
  method = rep(c("SONG", "t-SNE", "UMAP"), each = nrow(results_df))
)

p <- ggplot(long_df, aes(x = n, y = time, color = method)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3) +
  scale_x_log10(labels = scales::comma_format()) +
  scale_y_log10() +
  labs(
    title = "Runtime Scaling: SONG vs t-SNE vs UMAP",
    subtitle = paste0(N_DIM, "D Gaussian blobs, ", N_CLUSTERS, " clusters, ",
                      EPOCHS, " epochs | ",
                      if (FAST_MODE) "FAST_MODE" else "Full"),
    x = "Number of Points (log scale)",
    y = "Wall-clock Time in Seconds (log scale)",
    color = "Method"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10),
    legend.position = "bottom"
  )

out_file <- file.path(OUT_DIR, "runtime_benchmark.pdf")
ggsave(out_file, p, width = 8, height = 6)
cat("Saved:", out_file, "\n")

# ── Speed ratios ───────────────────────────────────────────
cat("\n=== Speed Ratios (SONG / other) ===\n")
for (i in seq_len(nrow(results_df))) {
  n <- results_df$n[i]
  r_tsne <- results_df$SONG[i] / results_df$tSNE[i]
  r_umap <- results_df$SONG[i] / results_df$UMAP[i]
  cat(sprintf("  n=%6d: SONG/t-SNE=%.2f, SONG/UMAP=%.2f\n", n, r_tsne, r_umap))
}

cat("\nDone.\n")
