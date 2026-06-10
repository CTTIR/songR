# songR-side reproduction of paper AMI (Tables II-IV protocol):
# k-means(k = n_clusters) on the 2-D SONG embedding vs ground-truth labels,
# scored by Adjusted Mutual Information, averaged over seeds.
# Paper-leaning hyperparameters (Table I): epsilon=0.99, epochs=100, a=1.577, b=0.895.
# k = 3 (= dim + n_neighbors, the reference code default; paper "k" is ambiguous and
# k=2 is invalid for a 2-D embedding under songR's k >= d+1 rule).
suppressMessages({ library(songR); library(aricode) })

ami_for <- function(emb, labels, kk, seeds = 1:5) {
  vapply(seeds, function(s) {
    set.seed(s)
    cl <- stats::kmeans(emb, centers = kk, nstart = 5, iter.max = 100)$cluster
    aricode::AMI(cl, labels)
  }, numeric(1))
}

run_ds <- function(name, X, labels, song_seeds = 1:5,
                   epochs = 100L, epsilon = 0.99, k = 3L) {
  kk <- nlevels(as.factor(labels))
  cat(sprintf("\n[%s] n=%d D=%d clusters=%d\n", name, nrow(X), ncol(X), kk))
  amis <- numeric(0); t0 <- proc.time()
  for (s in song_seeds) {
    m <- song(X, k = k, epsilon = epsilon, epochs = epochs, a = 1.577, b = 0.895,
              seed = s, verbose = FALSE)
    amis <- c(amis, mean(ami_for(m$embedding, labels, kk)))
    cat(sprintf("  song seed %d: AMI=%.3f\n", s, tail(amis, 1)))
  }
  el <- (proc.time() - t0)["elapsed"]
  data.frame(dataset = name, n = nrow(X), D = ncol(X), clusters = kk,
             epochs = epochs, epsilon = epsilon, k = k,
             AMI_mean = mean(amis), AMI_sd = sd(amis), seconds = round(el, 1))
}

res <- list()
# 1) Gaussian blobs (shipped) — full
data(songR_blobs)
res$blobs <- run_ds("blobs", songR_blobs$data, songR_blobs$labels, epochs = 100L)
write.csv(do.call(rbind, res), "data-raw/reproduction/output/ami.csv", row.names = FALSE)

# 2) COIL-20 (PCA->300) — full; D=300 engages reference PCA front-end (songR omits)
c20 <- readRDS(".housekeeping/data/songR_ready/coil20_pca300.rds")
res$coil20 <- run_ds("coil20_pca300", c20$data, c20$labels, epochs = 100L)
write.csv(do.call(rbind, res), "data-raw/reproduction/output/ami.csv", row.names = FALSE)

# 3) MNIST (PCA->20) — subsample 5000 for tractability
mn <- readRDS(".housekeeping/data/songR_ready/mnist_pca20.rds")
set.seed(42); idx <- sample(nrow(mn$data), 5000)
res$mnist <- run_ds("mnist_pca20(n=5000)", mn$data[idx, ], mn$labels[idx], epochs = 100L)

out <- do.call(rbind, res)
write.csv(out, "data-raw/reproduction/output/ami.csv", row.names = FALSE)
cat("\n=== AMI SUMMARY ===\n"); print(out, row.names = FALSE)
cat("\nDONE\n")
