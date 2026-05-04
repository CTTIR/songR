setwd("C:/Users/raban/Documents/GitHub/songR")
set.seed(2021)
n_per_cluster <- 200
n_clusters <- 8
D <- 20
blobs_data <- do.call(rbind, lapply(seq_len(n_clusters), function(i) {
  center <- stats::rnorm(D, mean = 0, sd = 10)
  sweep(matrix(stats::rnorm(n_per_cluster * D, sd = 2), ncol = D), 2, center, "+")
}))
blobs_labels <- factor(rep(paste0("cluster_", seq_len(n_clusters)), each = n_per_cluster))
songR_blobs <- list(data = blobs_data, labels = blobs_labels, description = "Simulated Gaussian blobs dataset")
if (!dir.exists("data")) dir.create("data")
save(songR_blobs, file = "data/songR_blobs.rda", compress = "xz")
cat("Dataset created\n")
