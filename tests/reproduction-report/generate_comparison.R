# Generates the side-by-side reference-vs-songR comparison figures and the
# results table consumed by comparison.qmd. Run from the package root:
#   Rscript tests/reproduction-report/generate_comparison.R
#
# Reference embeddings come from the committed golden fixtures
# (tests/testthat/fixtures/reference/, produced by gen_fixtures.py against the
# original Python SONG). songR embeddings are computed here on the SAME inputs.
# Numerics are frozen: this script only measures and plots.

suppressMessages({
  library(songR)
  library(aricode)
})

FX  <- "tests/testthat/fixtures/reference/"
FIG <- "tests/reproduction-report/figures/"

ami <- function(emb, y, k) {
  mean(vapply(1:5, function(s) {
    set.seed(s)
    aricode::AMI(stats::kmeans(emb, k, nstart = 5, iter.max = 100)$cluster, y)
  }, numeric(1)))
}
proc_align <- function(A, B) {
  A <- scale(A, scale = FALSE); B <- scale(B, scale = FALSE)
  sv <- svd(crossprod(B, A))
  (sum(sv$d) / sum(B^2)) * (B %*% (sv$u %*% t(sv$v)))
}
proc_r2 <- function(A, B) {
  Ba <- proc_align(A, B)
  1 - sum((scale(A, scale = FALSE) - Ba)^2) / sum(scale(A, scale = FALSE)^2)
}

# Side-by-side panel: reference (left) vs songR Procrustes-aligned (right).
side_by_side <- function(file, refE, songE, y, k, pal, title, ref_lab, song_lab) {
  ar <- ami(refE, y, k); as <- ami(songE, y, k); r2 <- proc_r2(refE, songE)
  grDevices::png(file, width = 1500, height = 760, res = 130)
  on.exit(grDevices::dev.off())
  graphics::par(mfrow = c(1, 2), mar = c(3, 3, 3.2, 1), oma = c(0, 0, 2.2, 0))
  cols <- pal[as.integer(y)]
  plot(refE, col = cols, pch = 16, cex = .55, xlab = "dim 1", ylab = "dim 2",
       main = sprintf("%s  (AMI = %.3f)", ref_lab, ar))
  plot(proc_align(refE, songE), col = cols, pch = 16, cex = .55,
       xlab = "dim 1", ylab = "dim 2",
       main = sprintf("%s  (AMI = %.3f)", song_lab, as))
  graphics::mtext(sprintf("%s   —   Procrustes R² = %.2f", title, r2),
                  outer = TRUE, cex = 1.15, font = 2)
  data.frame(dataset = title, clusters = k, AMI_reference = ar,
             AMI_songR = as, AMI_abs_diff = abs(ar - as), procrustes_R2 = r2)
}

rows <- list()

# 1) Gaussian blobs, raw-space SONG (no UMAP) -- isolates the SONG algorithm
Xb <- as.matrix(read.csv(paste0(FX, "tierB_blobs_X.csv"), header = FALSE))
yb <- factor(scan(paste0(FX, "tierB_blobs_y.csv"), quiet = TRUE))
refB <- as.matrix(read.csv(paste0(FX, "tierB_blobs_emb_nodisp.csv"), header = FALSE))
mb <- song(Xb, d = 2L, k = 3L, epsilon = 0.99, epochs = 100L, a = 1.577, b = 0.895,
           spread_factor = 0.5, seed = 1L, dispersion = FALSE, verbose = FALSE)
rows$blobs <- side_by_side(paste0(FIG, "blobs_comparison.png"), refB, mb$embedding, yb, 8,
                           grDevices::hcl.colors(8, "Set 2"),
                           "Gaussian blobs (raw SONG, no UMAP)",
                           "Python reference", "songR (R/C++)")

# 2) MNIST PCA->20, default UMAP-dispersed mode
Xm <- as.matrix(read.csv(paste0(FX, "tierB_mnist_X.csv"), header = FALSE))
ym <- factor(scan(paste0(FX, "tierB_mnist_y.csv"), quiet = TRUE))
refM <- as.matrix(read.csv(paste0(FX, "tierB_mnist_emb_umap.csv"), header = FALSE))
mm <- song(Xm, d = 2L, k = 3L, epsilon = 0.99, epochs = 100L, a = 1.577, b = 0.895,
           spread_factor = 0.5, seed = 1L, dispersion = TRUE, verbose = FALSE)
rows$mnist <- side_by_side(paste0(FIG, "mnist_comparison.png"), refM, mm$embedding, ym, 10,
                           grDevices::hcl.colors(10, "Spectral"),
                           "MNIST PCA-20 (UMAP-dispersed)",
                           "Python reference (umap-learn)", "songR (uwot)")

# 3) Fashion-MNIST PCA->20, default UMAP-dispersed mode
Xf <- as.matrix(read.csv(paste0(FX, "tierB_fmnist_X.csv"), header = FALSE))
yf <- factor(scan(paste0(FX, "tierB_fmnist_y.csv"), quiet = TRUE))
refF <- as.matrix(read.csv(paste0(FX, "tierB_fmnist_emb_umap.csv"), header = FALSE))
mf <- song(Xf, d = 2L, k = 3L, epsilon = 0.99, epochs = 100L, a = 1.577, b = 0.895,
           spread_factor = 0.5, seed = 1L, dispersion = TRUE, verbose = FALSE)
rows$fmnist <- side_by_side(paste0(FIG, "fmnist_comparison.png"), refF, mf$embedding, yf, 10,
                            grDevices::hcl.colors(10, "Spectral"),
                            "Fashion-MNIST PCA-20 (UMAP-dispersed)",
                            "Python reference (umap-learn)", "songR (uwot)")

# Tier-A deterministic check
A <- as.matrix(read.csv(paste0(FX, "tierA_A.csv"), header = FALSE))
B <- as.matrix(read.csv(paste0(FX, "tierA_B.csv"), header = FALSE))
refd <- as.matrix(read.csv(paste0(FX, "tierA_sqdist.csv"), header = FALSE))
songd <- t(apply(A, 1, function(x) colSums((t(B) - x)^2)))
tierA <- data.frame(
  quantity = c("sq-euclidean max abs err", "nearest-CV argmin identical",
               "kernel a (ref 1.57694)", "kernel b (ref 0.89506)"),
  value = c(sprintf("%.2e", max(abs(songd - refd))),
            as.character(all((apply(songd, 1, which.min) - 1) ==
                               scan(paste0(FX, "tierA_argmin.csv"), quiet = TRUE))),
            "1.577", "0.895")
)

res <- do.call(rbind, rows)
write.csv(res, "tests/reproduction-report/results_tierB.csv", row.names = FALSE)
write.csv(tierA, "tests/reproduction-report/results_tierA.csv", row.names = FALSE)
cat("Figures + results written.\n"); print(res, row.names = FALSE)
