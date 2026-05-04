# ============================================================
# Tutorial 01: Prepare All Benchmark Datasets
# ============================================================
# Downloads/generates all datasets used in the tutorial suite.
# Run ONCE; subsequent tutorials load from songR_ready/.
#
# Datasets:
#   1. MNIST (PCA-20)
#   2. Fashion-MNIST (PCA-20)
#   3. Wong CyTOF (logicle-transformed, or simulated fallback)
#   4. COIL-20 (PCA-300, simulated fallback)
# ============================================================

source("tutorials/utils_benchmarks.R")

READY_DIR <- ".housekeeping/data/songR_ready"
if (!dir.exists(READY_DIR)) dir.create(READY_DIR, recursive = TRUE)

# ── 1. MNIST ─────────────────────────────────────────────────
cat("=== [1/4] MNIST ===\n")
mnist_path <- file.path(READY_DIR, "mnist_pca20.rds")
if (file.exists(mnist_path)) {
  cat("  [skip] already exists\n")
} else {
  # Try existing preprocessed file first
  existing <- file.path(READY_DIR, "mnist.rds")
  if (file.exists(existing)) {
    d <- readRDS(existing)
    saveRDS(d, mnist_path)
    cat("  Copied from existing mnist.rds\n")
  } else {
    # Try dslabs
    if (requireNamespace("dslabs", quietly = TRUE)) {
      cat("  Loading via dslabs...\n")
      mnist_raw <- dslabs::read_mnist()
      x <- mnist_raw$train$images / 255.0
    } else {
      # Try raw gz files
      gz_dir <- ".housekeeping/data/MNIST_FashionMNIST"
      rds_file <- file.path(gz_dir, "mnist.rds")
      if (file.exists(rds_file)) {
        cat("  Loading from existing RDS...\n")
        raw <- readRDS(rds_file)
        x <- rbind(raw$x_train, raw$x_test) / 255.0
        y <- c(raw$y_train, raw$y_test)
      } else {
        stop("MNIST data not found. Place mnist.rds in ", gz_dir)
      }
    }
    if (!exists("y")) y <- if (exists("mnist_raw")) mnist_raw$train$labels else NULL
    if (is.null(y)) stop("MNIST labels not available")

    cat("  Running PCA (n=20)...\n"); flush.console()
    pca <- irlba::prcomp_irlba(x, n = 20, center = TRUE, scale. = FALSE)
    result <- list(data = pca$x, labels = as.integer(y))
    saveRDS(result, mnist_path)
    cat("  Saved:", nrow(result$data), "x", ncol(result$data), "\n")
  }
}

# ── 2. Fashion-MNIST ─────────────────────────────────────────
cat("\n=== [2/4] Fashion-MNIST ===\n")
fmnist_path <- file.path(READY_DIR, "fashion_mnist_pca20.rds")
if (file.exists(fmnist_path)) {
  cat("  [skip] already exists\n")
} else {
  existing <- file.path(READY_DIR, "fashion_mnist.rds")
  if (file.exists(existing)) {
    d <- readRDS(existing)
    saveRDS(d, fmnist_path)
    cat("  Copied from existing fashion_mnist.rds\n")
  } else {
    gz_dir <- ".housekeeping/data/MNIST_FashionMNIST"
    rds_file <- file.path(gz_dir, "fashion_mnist.rds")
    if (file.exists(rds_file)) {
      cat("  Loading from existing RDS...\n")
      raw <- readRDS(rds_file)
      x <- rbind(raw$x_train, raw$x_test) / 255.0
      y <- c(raw$y_train, raw$y_test)
    } else {
      stop("Fashion-MNIST data not found. Place fashion_mnist.rds in ", gz_dir)
    }
    cat("  Running PCA (n=20)...\n"); flush.console()
    pca <- irlba::prcomp_irlba(x, n = 20, center = TRUE, scale. = FALSE)
    fmnist_labels <- c("T-shirt/top", "Trouser", "Pullover", "Dress", "Coat",
                       "Sandal", "Shirt", "Sneaker", "Bag", "Ankle boot")
    result <- list(data = pca$x, labels = as.integer(y),
                   label_names = fmnist_labels)
    saveRDS(result, fmnist_path)
    cat("  Saved:", nrow(result$data), "x", ncol(result$data), "\n")
  }
}

# ── 3. Wong CyTOF ───────────────────────────────────────────
cat("\n=== [3/4] Wong CyTOF ===\n")
wong_path <- file.path(READY_DIR, "wong_logicle.rds")
if (file.exists(wong_path)) {
  cat("  [skip] already exists\n")
} else {
  # Check for preprocessed file
  existing <- file.path(READY_DIR, "wong.rds")
  if (file.exists(existing)) {
    d <- readRDS(existing)
    # Add ccr7 if available
    if ("CCR7" %in% colnames(d$data)) {
      d$ccr7 <- d$data[, "CCR7"]
    } else {
      d$ccr7 <- d$data[, 1]  # fallback
    }
    d$simulated <- FALSE
    saveRDS(d, wong_path)
    cat("  Copied from existing wong.rds\n")
  } else {
    cat("  Real data not found. Generating simulated Wong-like data...\n")
    d <- simulate_wong_data(n = 100000, seed = 2016)
    saveRDS(d, wong_path)
    cat("  Saved simulated:", nrow(d$data), "x", ncol(d$data), "\n")
  }
}

# ── 4. COIL-20 ───────────────────────────────────────────────
cat("\n=== [4/4] COIL-20 ===\n")
coil_path <- file.path(READY_DIR, "coil20_pca300.rds")
if (file.exists(coil_path)) {
  cat("  [skip] already exists\n")
} else {
  cat("  Generating simulated COIL-20 data...\n")
  d <- simulate_coil20(seed = 1996)
  saveRDS(d, coil_path)
  cat("  Saved:", nrow(d$data), "x", ncol(d$data),
      "| Objects:", length(unique(d$labels)), "\n")
}

# ── Summary ──────────────────────────────────────────────────
cat("\n=== Summary ===\n")
cat("Output directory:", normalizePath(READY_DIR), "\n")
for (f in list.files(READY_DIR, pattern = "\\.rds$")) {
  sz <- round(file.size(file.path(READY_DIR, f)) / 1e6, 1)
  cat("  ", f, "-", sz, "MB\n")
}
