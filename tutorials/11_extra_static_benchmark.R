# ============================================================
# Tutorial 11: Extra — Static Benchmark Comparison
# ============================================================
# Extended comparison: SONG vs t-SNE vs UMAP on multiple
# datasets WITHOUT incremental updates (single-shot embedding).
# Computes AMI, timing, and generates scatter panels.
#
# Datasets: MNIST, Fashion-MNIST, Wong CyTOF, COIL-20
# ============================================================

FAST_MODE <- TRUE

source("tutorials/utils_benchmarks.R")

library(songR)
library(ggplot2)
library(patchwork)

# ── Data ────────────────────────────────────────────────────
DATA_DIR <- ".housekeeping/data/songR_ready"
OUT_DIR  <- "tutorials/output"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

cat("=== Extra: Static Benchmark Comparison ===\n")
cat("FAST_MODE:", FAST_MODE, "\n\n")

# ── Parameters ──────────────────────────────────────────────
SEED <- 42L
EPOCHS <- if (FAST_MODE) 30L else 50L
N_SAMPLE <- if (FAST_MODE) 5000L else 20000L

# ── Load datasets ──────────────────────────────────────────
datasets <- list()

# MNIST
mnist_path <- file.path(DATA_DIR, "mnist_pca20.rds")
if (file.exists(mnist_path)) {
  d <- readRDS(mnist_path)
  set.seed(SEED)
  idx <- sample(nrow(d$data), min(N_SAMPLE, nrow(d$data)))
  datasets[["MNIST"]] <- list(X = d$data[idx, ], labels = d$labels[idx], k = 10)
  cat("Loaded MNIST:", nrow(datasets$MNIST$X), "pts\n")
}

# Fashion-MNIST
fmnist_path <- file.path(DATA_DIR, "fashion_mnist_pca20.rds")
if (file.exists(fmnist_path)) {
  d <- readRDS(fmnist_path)
  set.seed(SEED)
  idx <- sample(nrow(d$data), min(N_SAMPLE, nrow(d$data)))
  datasets[["Fashion-MNIST"]] <- list(X = d$data[idx, ], labels = d$labels[idx], k = 10)
  cat("Loaded Fashion-MNIST:", nrow(datasets[["Fashion-MNIST"]]$X), "pts\n")
}

# Wong CyTOF
wong_path <- file.path(DATA_DIR, "wong_logicle.rds")
if (file.exists(wong_path)) {
  d <- readRDS(wong_path)
  set.seed(SEED)
  idx <- sample(nrow(d$data), min(N_SAMPLE, nrow(d$data)))
  labs <- if (!is.null(d$labels)) d$labels[idx] else d$cluster_id[idx]
  datasets[["Wong CyTOF"]] <- list(X = d$data[idx, ], labels = labs,
                                     k = length(unique(labs)))
  cat("Loaded Wong CyTOF:", nrow(datasets[["Wong CyTOF"]]$X), "pts\n")
}

# COIL-20
coil_path <- file.path(DATA_DIR, "coil20_pca300.rds")
if (file.exists(coil_path)) {
  d <- readRDS(coil_path)
  datasets[["COIL-20"]] <- list(X = d$data, labels = d$labels, k = 20)
  cat("Loaded COIL-20:", nrow(datasets[["COIL-20"]]$X), "pts\n")
}

if (length(datasets) == 0) {
  stop("No datasets found. Run tutorials/01_prepare_data.R first.")
}
cat("\n")

# ── Run methods on each dataset ────────────────────────────
results <- list()
all_plots <- list()

for (dname in names(datasets)) {
  cat(sprintf("=== %s ===\n", dname))
  ds <- datasets[[dname]]

  # SONG
  cat("  SONG...")
  tm_song <- time_method(songR::song(ds$X, epochs = EPOCHS, seed = SEED, verbose = FALSE))
  ami_song <- compute_ami(tm_song$result$embedding, ds$labels, k = ds$k)
  cat(sprintf(" AMI=%.1f, %.1fs\n", ami_song, tm_song$elapsed))

  # t-SNE
  cat("  t-SNE...")
  tm_tsne <- time_method(run_tsne(ds$X, seed = SEED))
  ami_tsne <- compute_ami(tm_tsne$result, ds$labels, k = ds$k)
  cat(sprintf(" AMI=%.1f, %.1fs\n", ami_tsne, tm_tsne$elapsed))

  # UMAP
  cat("  UMAP...")
  tm_umap <- time_method(run_umap(ds$X, seed = SEED))
  ami_umap <- compute_ami(tm_umap$result, ds$labels, k = ds$k)
  cat(sprintf(" AMI=%.1f, %.1fs\n", ami_umap, tm_umap$elapsed))

  results[[length(results) + 1]] <- data.frame(
    Dataset = dname, n = nrow(ds$X), d = ncol(ds$X), k = ds$k,
    SONG_AMI = round(ami_song, 1), SONG_time = round(tm_song$elapsed, 1),
    tSNE_AMI = round(ami_tsne, 1), tSNE_time = round(tm_tsne$elapsed, 1),
    UMAP_AMI = round(ami_umap, 1), UMAP_time = round(tm_umap$elapsed, 1)
  )

  # Plots for this dataset
  p1 <- plot_embedding(tm_song$result$embedding, labels = factor(ds$labels),
                       title = sprintf("%s — SONG (%.1f)", dname, ami_song), point_size = 0.3)
  p2 <- plot_embedding(tm_tsne$result, labels = factor(ds$labels),
                       title = sprintf("t-SNE (%.1f)", ami_tsne), point_size = 0.3)
  p3 <- plot_embedding(tm_umap$result, labels = factor(ds$labels),
                       title = sprintf("UMAP (%.1f)", ami_umap), point_size = 0.3)
  all_plots <- c(all_plots, list(p1, p2, p3))

  cat("\n")
}

results_df <- do.call(rbind, results)
rownames(results_df) <- NULL

# ── Print results ──────────────────────────────────────────
cat("\n=== Static Benchmark Results ===\n")
print(results_df, row.names = FALSE)

# ── Save CSV ───────────────────────────────────────────────
csv_file <- file.path(OUT_DIR, "static_benchmark.csv")
write.csv(results_df, csv_file, row.names = FALSE)
cat("Saved CSV:", csv_file, "\n")

# ── Save scatter grid ──────────────────────────────────────
n_datasets <- length(datasets)
combined <- wrap_plots(all_plots, ncol = 3, nrow = n_datasets) +
  plot_annotation(
    title = "Static Benchmark: SONG vs t-SNE vs UMAP",
    subtitle = paste0("AMI in parentheses | ",
                      if (FAST_MODE) paste0("n=", N_SAMPLE, " (FAST_MODE)") else "Full data"),
    theme = theme(plot.title = element_text(size = 14, face = "bold"),
                  plot.subtitle = element_text(size = 10))
  )

out_file <- file.path(OUT_DIR, "static_benchmark.pdf")
ggsave(out_file, combined, width = 15, height = 4 * n_datasets)
cat("Saved:", out_file, "\n")

cat("Done.\n")
