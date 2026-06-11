# Reproduce key figures from the original SONG paper (Senanayake et al., 2021,
# IEEE TNNLS) with songR. Run from the package root:
#   Rscript tests/paper-figures/generate_paper_figures.R
#
# Uses the paper's Table I hyperparameters (epsilon = 0.99, epochs = 100,
# a = 1.577, b = 0.895) and the default UMAP dispersion. Real datasets live in
# the gitignored .housekeeping/ (PCA-reduced per the paper protocol); MNIST and
# Fashion-MNIST are subsampled for tractable runtime. AMI (k-means on the
# embedding vs. labels, mean over 5 seeds) is annotated on each figure.

suppressMessages({ library(songR); library(aricode); library(viridis) })

DATA <- ".housekeeping/data/songR_ready/"
FIG  <- "tests/paper-figures/figures/"
PARAMS <- list(k = 3L, epsilon = 0.99, epochs = 100L, a = 1.577, b = 0.895,
               spread_factor = 0.5, seed = 1L)
ami <- function(emb, y, k) mean(vapply(1:5, function(s) {
  set.seed(s); aricode::AMI(stats::kmeans(emb, k, nstart = 5, iter.max = 100)$cluster, y)
}, numeric(1)))

fit_song <- function(X) do.call(song, c(list(X = X, d = 2L, dispersion = TRUE,
                                             verbose = FALSE), PARAMS))

embed_plot <- function(file, emb, labels, title, sub = "", w = 1500, h = 1300) {
  lv <- levels(as.factor(labels)); pal <- viridis::viridis(length(lv), option = "plasma", end = .92)
  grDevices::png(file, width = w, height = h, res = 150)
  on.exit(grDevices::dev.off())
  graphics::par(mar = c(3, 3, 4, 1))
  plot(emb[, 1], emb[, 2], col = pal[as.integer(as.factor(labels))], pch = 16, cex = .45,
       xlab = "SONG 1", ylab = "SONG 2", main = title)
  if (nzchar(sub)) graphics::mtext(sub, line = 0.2, cex = 0.85)
  if (length(lv) <= 20)
    graphics::legend("topright", legend = lv, col = pal, pch = 16, cex = .6, bty = "n", ncol = 2)
}

rows <- list()
sub_idx <- function(n, m, seed = 42) { set.seed(seed); if (n <= m) seq_len(n) else sample(n, m) }

## Fig 4 — MNIST (PCA -> 20), digits 0-9
mn <- readRDS(paste0(DATA, "mnist_pca20.rds")); i <- sub_idx(nrow(mn$data), 15000)
m <- fit_song(mn$data[i, ]); a <- ami(m$embedding, mn$labels[i], 10)
embed_plot(paste0(FIG, "fig4_mnist.png"), m$embedding, mn$labels[i],
           "Paper Fig. 4 - MNIST (songR)", sprintf("PCA->20, n=%d, AMI=%.3f", length(i), a))
rows$mnist <- data.frame(figure = "Fig 4", dataset = "MNIST (PCA-20)", n = length(i), clusters = 10, AMI = a)

## Fig 3 — Fashion-MNIST (PCA -> 20)
fm <- readRDS(paste0(DATA, "fashion_mnist_pca20.rds")); i <- sub_idx(nrow(fm$data), 15000)
m <- fit_song(fm$data[i, ]); a <- ami(m$embedding, fm$labels[i], 10)
embed_plot(paste0(FIG, "fig3_fashion_mnist.png"), m$embedding, fm$labels[i],
           "Paper Fig. 3 - Fashion-MNIST (songR)", sprintf("PCA->20, n=%d, AMI=%.3f", length(i), a))
rows$fmnist <- data.frame(figure = "Fig 3", dataset = "Fashion-MNIST (PCA-20)", n = length(i), clusters = 10, AMI = a)

## Fig 8 — COIL-20 (PCA -> 300): rotation topology -> circular clusters
c20 <- readRDS(paste0(DATA, "coil20_pca300.rds"))
m <- fit_song(c20$data); a <- ami(m$embedding, c20$labels, 20)
embed_plot(paste0(FIG, "fig8_coil20.png"), m$embedding, c20$labels,
           "Paper Fig. 8 - COIL-20 topology (songR)",
           sprintf("PCA->300, n=%d, 20 objects, AMI=%.3f", nrow(c20$data), a))
rows$coil20 <- data.frame(figure = "Fig 8", dataset = "COIL-20 (PCA-300)", n = nrow(c20$data), clusters = 20, AMI = a)

## Fig 7 — Gaussian blobs, many clusters / high dimension (noise-tolerance stress)
set.seed(7); K <- 30L; D <- 60L; per <- 200L
centers <- matrix(stats::rnorm(K * D, sd = 10), K, D)
Xb <- do.call(rbind, lapply(seq_len(K), function(k) matrix(stats::rnorm(per * D, sd = 1), per, D) +
                              matrix(centers[k, ], per, D, byrow = TRUE)))
yb <- factor(rep(seq_len(K), each = per))
m <- fit_song(Xb); a <- ami(m$embedding, yb, K)
embed_plot(paste0(FIG, "fig7_blobs.png"), m$embedding, yb,
           "Paper Fig. 7 - Gaussian blobs (songR)", sprintf("%d clusters, %dD, AMI=%.3f", K, D, a))
rows$blobs <- data.frame(figure = "Fig 7", dataset = sprintf("Blobs (%dc/%dD)", K, D), n = nrow(Xb), clusters = K, AMI = a)

## Fig 3/4 (heterogeneous incremental) — MNIST: train on 0-4, add 5-9
i <- sub_idx(nrow(mn$data), 10000, seed = 11)
Xall <- mn$data[i, ]; yall <- mn$labels[i]; lab <- as.integer(as.character(yall))
g1 <- lab %in% 0:4; g2 <- !g1
mv1 <- fit_song(Xall[g1, ])
mv2 <- update(mv1, Xall[g2, ], epochs = 50L, verbose = FALSE)
emb_all <- predict(mv2, Xall)
grDevices::png(paste0(FIG, "fig3_4_incremental.png"), width = 2400, height = 1150, res = 150)
graphics::par(mfrow = c(1, 2), mar = c(3, 3, 4, 1))
pal <- viridis::viridis(10, option = "plasma", end = .92)
plot(mv1$embedding, col = pal[lab[g1] + 1], pch = 16, cex = .45, xlab = "SONG 1", ylab = "SONG 2",
     main = "Step 1: digits 0-4")
plot(emb_all, col = pal[lab + 1], pch = 16, cex = .45, xlab = "SONG 1", ylab = "SONG 2",
     main = "Step 2: + digits 5-9 (incremental)")
graphics::legend("topright", legend = 0:9, col = pal, pch = 16, cex = .6, bty = "n", ncol = 2)
grDevices::dev.off()
rows$incremental <- data.frame(figure = "Fig 3/4", dataset = "MNIST heterogeneous incremental",
                               n = length(i), clusters = 10, AMI = ami(emb_all, yall, 10))

res <- do.call(rbind, rows)
write.csv(res, "tests/paper-figures/results.csv", row.names = FALSE)
cat("\n=== PAPER-FIGURE REPRODUCTION (songR) ===\n"); print(res, row.names = FALSE)
