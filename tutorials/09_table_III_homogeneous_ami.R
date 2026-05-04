# ============================================================
# Tutorial 09: Table III — AMI for Homogeneous Increments
# ============================================================
# Reproduces Table III from Senanayake et al. (2021) IEEE TNNLS.
# AMI scores for homogeneous increments on Fashion-MNIST and MNIST.
# All classes present at every step, growing sample size.
#
# Full mode:  12k -> 24k -> 48k -> 60k
# FAST_MODE:  3k  -> 6k  -> 12k -> 15k
#
# Methods: SONG (incremental), SONG+Reinit, t-SNE, UMAP
# ============================================================

FAST_MODE <- TRUE

source("tutorials/utils_benchmarks.R")

library(songR)

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

cat("=== Table III: AMI for Homogeneous Increments ===\n")
cat("FAST_MODE:", FAST_MODE, "\n\n")

# ── Parameters ──────────────────────────────────────────────
if (FAST_MODE) {
  step_sizes <- c(3000L, 6000L, 12000L, 15000L)
  n_seeds <- 3L
} else {
  step_sizes <- c(12000L, 24000L, 48000L, 60000L)
  n_seeds <- 5L
}

EPOCHS_INIT <- if (FAST_MODE) 30L else 50L
EPOCHS_UPD  <- if (FAST_MODE) 20L else 50L
BASE_SEED <- 42L

step_labels <- paste0("n=", format(step_sizes, big.mark = ","))

# ── Helper: compute AMI for one dataset/seed ────────────────
run_homogeneous_ami <- function(dataset, dname, seed) {
  set.seed(seed)

  max_n <- max(step_sizes)
  n_avail <- nrow(dataset$data)
  idx_all <- sample(n_avail, min(max_n, n_avail))

  n_steps <- length(step_sizes)
  ami_mat <- matrix(NA_real_, nrow = 4, ncol = n_steps,
                    dimnames = list(c("SONG", "SONG+Reinit", "t-SNE", "UMAP"),
                                   step_labels))

  # Build incremental data list
  X_list <- list()
  lab_list <- list()
  prev_n <- 0L
  for (s in seq_along(step_sizes)) {
    n_s <- min(step_sizes[s], length(idx_all))
    if (prev_n == 0) {
      new_idx <- idx_all[1:n_s]
    } else {
      new_idx <- idx_all[(prev_n + 1):n_s]
    }
    X_list[[s]] <- dataset$data[new_idx, , drop = FALSE]
    lab_list[[s]] <- dataset$labels[new_idx]
    prev_n <- n_s
  }

  # Cumulative labels
  cum_labels <- list()
  for (s in seq_along(step_sizes)) {
    n_s <- min(step_sizes[s], length(idx_all))
    cum_labels[[s]] <- dataset$labels[idx_all[1:n_s]]
  }

  k <- length(unique(dataset$labels))

  # ── SONG (incremental) ──
  tryCatch({
    model <- NULL; X_seen <- NULL
    for (s in seq_along(X_list)) {
      X_seen <- rbind(X_seen, X_list[[s]])
      if (is.null(model)) {
        model <- songR::song(X_seen, epochs = EPOCHS_INIT, seed = seed, verbose = FALSE)
      } else {
        model <- update(model, X_list[[s]], epochs = EPOCHS_UPD, verbose = FALSE)
      }
      emb <- predict(model, newdata = X_seen)
      ami_mat["SONG", s] <- compute_ami(emb, cum_labels[[s]], k = k)
    }
  }, error = function(e) cat("  SONG error:", conditionMessage(e), "\n"))

  # ── SONG+Reinit ──
  tryCatch({
    X_seen <- NULL
    for (s in seq_along(X_list)) {
      X_seen <- rbind(X_seen, X_list[[s]])
      model <- songR::song(X_seen, epochs = EPOCHS_INIT, seed = seed, verbose = FALSE)
      ami_mat["SONG+Reinit", s] <- compute_ami(model$embedding, cum_labels[[s]], k = k)
    }
  }, error = function(e) cat("  SONG+Reinit error:", conditionMessage(e), "\n"))

  # ── t-SNE ──
  tryCatch({
    X_seen <- NULL
    for (s in seq_along(X_list)) {
      X_seen <- rbind(X_seen, X_list[[s]])
      emb <- run_tsne(X_seen, seed = seed)
      ami_mat["t-SNE", s] <- compute_ami(emb, cum_labels[[s]], k = k)
    }
  }, error = function(e) cat("  t-SNE error:", conditionMessage(e), "\n"))

  # ── UMAP ──
  tryCatch({
    X_seen <- NULL
    for (s in seq_along(X_list)) {
      X_seen <- rbind(X_seen, X_list[[s]])
      emb <- run_umap(X_seen, seed = seed)
      ami_mat["UMAP", s] <- compute_ami(emb, cum_labels[[s]], k = k)
    }
  }, error = function(e) cat("  UMAP error:", conditionMessage(e), "\n"))

  ami_mat
}

# ── Run across seeds ────────────────────────────────────────
all_results <- list()

for (dname in c("Fashion-MNIST", "MNIST")) {
  dataset <- if (dname == "Fashion-MNIST") fmnist else mnist
  cat("=== Processing:", dname, "===\n")

  seed_results <- list()
  for (si in seq_len(n_seeds)) {
    seed_val <- BASE_SEED + si - 1
    cat(sprintf("  Seed %d/%d (seed=%d)...\n", si, n_seeds, seed_val))
    seed_results[[si]] <- run_homogeneous_ami(dataset, dname, seed_val)
  }

  # Average over seeds
  avg_ami <- Reduce("+", seed_results) / n_seeds

  # Format as data frame
  for (meth in rownames(avg_ami)) {
    all_results[[length(all_results) + 1]] <- data.frame(
      Dataset = dname,
      Method = meth,
      t(round(avg_ami[meth, ], 1)),
      stringsAsFactors = FALSE
    )
  }

  cat("  Done. Average AMI:\n")
  print(round(avg_ami, 1))
  cat("\n")
}

results_df <- do.call(rbind, all_results)
rownames(results_df) <- NULL

# ── Print Table ─────────────────────────────────────────────
cat("\n=== Table III: AMI for Homogeneous Increments (averaged over", n_seeds, "seeds) ===\n")
print(results_df, row.names = FALSE)

# ── Save CSV ────────────────────────────────────────────────
csv_file <- file.path(OUT_DIR, "table_III_homogeneous_ami.csv")
write.csv(results_df, csv_file, row.names = FALSE)
cat("\nSaved:", csv_file, "\n")

cat("\n=== Summary ===\n")
cat("Datasets: Fashion-MNIST, MNIST (PCA-20)\n")
cat("Step sizes:", paste(step_sizes, collapse = " -> "), "\n")
cat("Seeds:", n_seeds, "\n")
cat("Output:", normalizePath(csv_file, mustWork = FALSE), "\n")
cat("Done.\n")
