# ============================================================
# Tutorial 07: Figure 8 — COIL-20 Topology Preservation
# ============================================================
# Reproduces Figure 8 from Senanayake et al. (2021) IEEE TNNLS.
# COIL-20: 1440 images (20 objects x 72 poses) -> PCA to 300 -> embed.
#
# Expected: circular clusters for SONG/UMAP (rotation topology),
# arch shapes for t-SNE (known topology distortion).
#
# Output: 1x3 panel PDF colored by object ID.
# ============================================================

FAST_MODE <- TRUE

source("tutorials/utils_benchmarks.R")

library(songR)
library(ggplot2)
library(patchwork)
library(RColorBrewer)

# ── Data ────────────────────────────────────────────────────
DATA_DIR  <- ".housekeeping/data/songR_ready"
OUT_DIR   <- "tutorials/output"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

coil_path <- file.path(DATA_DIR, "coil20_pca300.rds")
require_data(coil_path)
coil <- readRDS(coil_path)

cat("=== Figure 8: COIL-20 Topology Preservation ===\n")
cat("FAST_MODE:", FAST_MODE, "\n")
cat("Data dimensions:", nrow(coil$data), "x", ncol(coil$data), "\n")
cat("Objects:", length(unique(coil$labels)), "\n")
if (isTRUE(coil$simulated)) cat("NOTE: Using simulated COIL-20-like data.\n")

# ── Parameters ──────────────────────────────────────────────
SEED <- 42L
EPOCHS <- if (FAST_MODE) 30L else 50L
X <- coil$data
labels <- coil$labels

# ── 20-color palette ───────────────────────────────────────
n_obj <- length(unique(labels))
if (n_obj <= 20) {
  # Combine two qualitative palettes for 20 distinct colors
  pal <- c(brewer.pal(8, "Set2"), brewer.pal(8, "Dark2"),
           brewer.pal(4, "Set3"))
  pal <- pal[1:n_obj]
} else {
  pal <- rainbow(n_obj)
}

# ── Method: SONG ───────────────────────────────────────────
cat("\n--- SONG ---\n")
p_song <- tryCatch({
  t0 <- proc.time()
  model <- songR::song(X, epochs = EPOCHS, seed = SEED, verbose = FALSE)
  elapsed <- round((proc.time() - t0)["elapsed"], 1)
  cat("  Done (", elapsed, "s), CVs:", nrow(model$C), "\n")

  plot_embedding(model$embedding, labels = factor(labels),
                 title = paste0("SONG (", elapsed, "s)"),
                 point_size = 1.0) +
    scale_color_manual(values = pal)
}, error = function(e) {
  cat("  ERROR:", conditionMessage(e), "\n")
  ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Failed") +
    theme_void() + ggtitle("SONG")
})

# ── Method: t-SNE ──────────────────────────────────────────
cat("--- t-SNE ---\n")
p_tsne <- tryCatch({
  t0 <- proc.time()
  emb <- run_tsne(X, perplexity = 30, seed = SEED)
  elapsed <- round((proc.time() - t0)["elapsed"], 1)
  cat("  Done (", elapsed, "s)\n")

  plot_embedding(emb, labels = factor(labels),
                 title = paste0("t-SNE (", elapsed, "s)"),
                 point_size = 1.0) +
    scale_color_manual(values = pal)
}, error = function(e) {
  cat("  ERROR:", conditionMessage(e), "\n")
  ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Failed") +
    theme_void() + ggtitle("t-SNE")
})

# ── Method: UMAP ──────────────────────────────────────────
cat("--- UMAP ---\n")
p_umap <- tryCatch({
  t0 <- proc.time()
  emb <- run_umap(X, seed = SEED)
  elapsed <- round((proc.time() - t0)["elapsed"], 1)
  cat("  Done (", elapsed, "s)\n")

  plot_embedding(emb, labels = factor(labels),
                 title = paste0("UMAP (", elapsed, "s)"),
                 point_size = 1.0) +
    scale_color_manual(values = pal)
}, error = function(e) {
  cat("  ERROR:", conditionMessage(e), "\n")
  ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Failed") +
    theme_void() + ggtitle("UMAP")
})

# ── Build 1x3 panel ───────────────────────────────────────
combined <- p_song + p_tsne + p_umap +
  plot_annotation(
    title = "Figure 8: COIL-20 Topology Preservation",
    subtitle = paste0("20 objects x 72 poses | PCA to 300D | ",
                      if (FAST_MODE) "FAST_MODE" else "Full epochs",
                      if (isTRUE(coil$simulated)) " (simulated)" else ""),
    theme = theme(plot.title = element_text(size = 14, face = "bold"),
                  plot.subtitle = element_text(size = 10))
  )

# ── Save ────────────────────────────────────────────────────
out_file <- file.path(OUT_DIR, "fig8_coil20_topology.pdf")
ggsave(out_file, combined, width = 15, height = 5)
cat("\nSaved:", out_file, "\n")

# ── Print topology observations ────────────────────────────
cat("\n=== Topology Observations ===\n")
cat("Expected behavior (per paper):\n")
cat("  SONG: Circular clusters (preserves rotational topology)\n")
cat("  UMAP: Circular clusters (similar topology preservation)\n")
cat("  t-SNE: Arch/horseshoe shapes (known topology distortion)\n")
cat("\nInspect the PDF to verify these patterns.\n")

cat("\n=== Summary ===\n")
cat("Dataset: COIL-20", if (isTRUE(coil$simulated)) "(simulated)" else "", "\n")
cat("Dimensions:", nrow(X), "x", ncol(X), "\n")
cat("Output:", normalizePath(out_file, mustWork = FALSE), "\n")
cat("Done.\n")
