# ============================================================
# Tutorial 08: Table II — AMI for Heterogeneous Increments
# ============================================================
# Reproduces Table II from Senanayake et al. (2021) IEEE TNNLS.
# AMI scores for heterogeneous increments on Fashion-MNIST and MNIST.
# Same scheme as Figs 3 & 4: add 2 classes per step.
# K-means on embedding, AMI vs true labels, averaged over seeds.
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

cat("=== Table II: AMI for Heterogeneous Increments ===\n")
cat("FAST_MODE:", FAST_MODE, "\n\n")

# ── Parameters ──────────────────────────────────────────────
if (FAST_MODE) {
  pts_per_class <- 500L
  n_seeds <- 3L
} else {
  pts_per_class <- 6000L
  n_seeds <- 5L
}

EPOCHS_INIT <- if (FAST_MODE) 30L else 50L
EPOCHS_UPD  <- if (FAST_MODE) 20L else 50L
BASE_SEED <- 42L

step_labels <- c("2 cls", "4 cls", "6 cls", "8 cls", "10 cls")

# ── Helper: compute AMI for one dataset/seed ────────────────
run_heterogeneous_ami <- function(dataset, dname, seed) {
  set.seed(seed)
  all_classes <- sort(unique(dataset$labels))
  class_order <- sample(all_classes)

  steps <- list(
    class_order[1:2], class_order[3:4], class_order[5:6],
    class_order[7:8], class_order[9:10]
  )

  # Build data
  X_list <- list()
  lab_list <- list()
  for (s in seq_along(steps)) {
    idx <- which(dataset$labels %in% steps[[s]])
    if (length(idx) > pts_per_class * length(steps[[s]])) {
      idx <- sample(idx, pts_per_class * length(steps[[s]]))
    }
    X_list[[s]] <- dataset$data[idx, , drop = FALSE]
    lab_list[[s]] <- dataset$labels[idx]
  }

  cum_labels <- list()
  for (s in seq_along(steps)) {
    cum_labels[[s]] <- unlist(lab_list[1:s])
  }

  n_steps <- length(steps)
  ami_mat <- matrix(NA_real_, nrow = 4, ncol = n_steps,
                    dimnames = list(c("SONG", "SONG+Reinit", "t-SNE", "UMAP"),
                                   step_labels))

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
      k <- length(unique(cum_labels[[s]]))
      ami_mat["SONG", s] <- compute_ami(emb, cum_labels[[s]], k = k)
    }
  }, error = function(e) cat("  SONG error:", conditionMessage(e), "\n"))

  # ── SONG+Reinit ──
  tryCatch({
    X_seen <- NULL
    for (s in seq_along(X_list)) {
      X_seen <- rbind(X_seen, X_list[[s]])
      model <- songR::song(X_seen, epochs = EPOCHS_INIT, seed = seed, verbose = FALSE)
      k <- length(unique(cum_labels[[s]]))
      ami_mat["SONG+Reinit", s] <- compute_ami(model$embedding, cum_labels[[s]], k = k)
    }
  }, error = function(e) cat("  SONG+Reinit error:", conditionMessage(e), "\n"))

  # ── t-SNE ──
  tryCatch({
    X_seen <- NULL
    for (s in seq_along(X_list)) {
      X_seen <- rbind(X_seen, X_list[[s]])
      emb <- run_tsne(X_seen, seed = seed)
      k <- length(unique(cum_labels[[s]]))
      ami_mat["t-SNE", s] <- compute_ami(emb, cum_labels[[s]], k = k)
    }
  }, error = function(e) cat("  t-SNE error:", conditionMessage(e), "\n"))

  # ── UMAP ──
  tryCatch({
    X_seen <- NULL
    for (s in seq_along(X_list)) {
      X_seen <- rbind(X_seen, X_list[[s]])
      emb <- run_umap(X_seen, seed = seed)
      k <- length(unique(cum_labels[[s]]))
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
    seed_results[[si]] <- run_heterogeneous_ami(dataset, dname, seed_val)
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
cat("\n=== Table II: AMI for Heterogeneous Increments (averaged over", n_seeds, "seeds) ===\n")
print(results_df, row.names = FALSE)

# ── Save CSV ────────────────────────────────────────────────
csv_file <- file.path(OUT_DIR, "table_II_heterogeneous_ami.csv")
write.csv(results_df, csv_file, row.names = FALSE)
cat("\nSaved:", csv_file, "\n")

cat("\n=== Summary ===\n")
cat("Datasets: Fashion-MNIST, MNIST (PCA-20)\n")
cat("Points/class:", pts_per_class, "\n")
cat("Seeds:", n_seeds, "\n")
cat("Output:", normalizePath(csv_file, mustWork = FALSE), "\n")
cat("Done.\n")
