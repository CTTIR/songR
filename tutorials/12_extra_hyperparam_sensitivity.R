# ============================================================
# Tutorial 12: Extra — Hyperparameter Sensitivity Analysis
# ============================================================
# Sweeps key SONG hyperparameters on a fixed dataset:
#   - epsilon (edge decay): 0.5, 0.7, 0.9, 0.95
#   - spread_factor (growth threshold): 0.1, 0.3, 0.5, 0.8
#   - k (neighborhood size): 2, 3, 5, 8
#   - epochs: 10, 25, 50, 100
#
# Measures AMI, number of coding vectors, and runtime.
# Dataset: Fashion-MNIST (PCA-20) subsample.
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

fmnist_path <- file.path(DATA_DIR, "fashion_mnist_pca20.rds")
require_data(fmnist_path)
fmnist <- readRDS(fmnist_path)

cat("=== Extra: Hyperparameter Sensitivity ===\n")
cat("FAST_MODE:", FAST_MODE, "\n\n")

# ── Parameters ──────────────────────────────────────────────
SEED <- 42L
N_SAMPLE <- if (FAST_MODE) 3000L else 10000L

set.seed(SEED)
idx <- sample(nrow(fmnist$data), min(N_SAMPLE, nrow(fmnist$data)))
X <- fmnist$data[idx, ]
labels <- fmnist$labels[idx]
K_TRUE <- length(unique(labels))

cat("Dataset: Fashion-MNIST, n =", nrow(X), ", d =", ncol(X), "\n\n")

# ── Sweep function ─────────────────────────────────────────
run_sweep <- function(param_name, param_values, base_args) {
  cat("--- Sweeping:", param_name, "---\n")
  sweep_results <- list()

  for (val in param_values) {
    args <- base_args
    args[[param_name]] <- val
    args$X <- X
    args$seed <- SEED
    args$verbose <- FALSE

    cat(sprintf("  %s = %s ...", param_name, val))
    t0 <- proc.time()
    model <- tryCatch(do.call(songR::song, args),
                      error = function(e) NULL)
    elapsed <- round((proc.time() - t0)["elapsed"], 2)

    if (!is.null(model)) {
      ami <- compute_ami(model$embedding, labels, k = K_TRUE)
      n_cv <- nrow(model$C)
      cat(sprintf(" AMI=%.1f, CVs=%d, %.1fs\n", ami, n_cv, elapsed))
      sweep_results[[length(sweep_results) + 1]] <- data.frame(
        param = param_name, value = as.character(val),
        AMI = round(ami, 1), n_CVs = n_cv, time_s = elapsed
      )
    } else {
      cat(" FAILED\n")
      sweep_results[[length(sweep_results) + 1]] <- data.frame(
        param = param_name, value = as.character(val),
        AMI = NA, n_CVs = NA, time_s = elapsed
      )
    }
  }
  do.call(rbind, sweep_results)
}

# ── Default values ─────────────────────────────────────────
base_epochs <- if (FAST_MODE) 30L else 50L
base_args <- list(epochs = base_epochs, epsilon = 0.9,
                  spread_factor = 0.5, k = 3L)

# ── Run sweeps ─────────────────────────────────────────────
results <- list()

# 1. Epsilon sweep
eps_values <- c(0.5, 0.7, 0.9, 0.95)
results[[1]] <- run_sweep("epsilon", eps_values, base_args)

# 2. Spread factor sweep
sf_values <- c(0.1, 0.3, 0.5, 0.8)
results[[2]] <- run_sweep("spread_factor", sf_values, base_args)

# 3. k sweep
k_values <- c(2L, 3L, 5L, 8L)
results[[3]] <- run_sweep("k", k_values, base_args)

# 4. Epochs sweep
epoch_values <- if (FAST_MODE) c(10L, 25L, 50L) else c(10L, 25L, 50L, 100L)
base_noepoch <- base_args
base_noepoch$epochs <- NULL
results[[4]] <- run_sweep("epochs", epoch_values, base_noepoch)

all_results <- do.call(rbind, results)
rownames(all_results) <- NULL

# ── Print results ──────────────────────────────────────────
cat("\n=== Hyperparameter Sensitivity Results ===\n")
print(all_results, row.names = FALSE)

# ── Save CSV ───────────────────────────────────────────────
csv_file <- file.path(OUT_DIR, "hyperparam_sensitivity.csv")
write.csv(all_results, csv_file, row.names = FALSE)
cat("Saved CSV:", csv_file, "\n")

# ── Build line plots ───────────────────────────────────────
cat("\n--- Building sensitivity plots ---\n")

make_sweep_plot <- function(df, param_name) {
  df$value_num <- as.numeric(df$value)
  ggplot(df, aes(x = value_num, y = AMI)) +
    geom_line(linewidth = 0.8, color = "#2166AC") +
    geom_point(size = 3, color = "#2166AC") +
    labs(x = param_name, y = "AMI", title = param_name) +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(size = 11, face = "bold", hjust = 0.5))
}

plots <- lapply(split(all_results, all_results$param), function(df) {
  make_sweep_plot(df, unique(df$param))
})

combined <- wrap_plots(plots, ncol = 2) +
  plot_annotation(
    title = "SONG Hyperparameter Sensitivity",
    subtitle = paste0("Fashion-MNIST (n=", nrow(X), ") | ",
                      if (FAST_MODE) "FAST_MODE" else "Full epochs"),
    theme = theme(plot.title = element_text(size = 14, face = "bold"),
                  plot.subtitle = element_text(size = 10))
  )

out_file <- file.path(OUT_DIR, "hyperparam_sensitivity.pdf")
ggsave(out_file, combined, width = 10, height = 8)
cat("Saved:", out_file, "\n")

cat("\n=== Key Findings ===\n")
cat("Inspect the plots to identify:\n")
cat("  1. Optimal epsilon range (typically 0.8-0.95)\n")
cat("  2. Effect of spread_factor on CV count and quality\n")
cat("  3. Diminishing returns from higher k\n")
cat("  4. Convergence rate across epochs\n")
cat("Done.\n")
