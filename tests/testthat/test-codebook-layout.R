# Regression tests for the coding-vector layout after the dispersion step and
# for mapping point labels to coding vectors.

fit_small <- function(n = 60L, ...) {
  song(as.matrix(iris[seq_len(n), 1:4]), epochs = 4L, seed = 1L,
       verbose = FALSE, dispersion = FALSE, ...)
}

test_that("input-length labels map to the modal label of each coding vector", {
  m <- fit_small(n = 150L)
  labels <- iris$Species
  labels[c(3L, 70L)] <- NA
  n_cv <- nrow(m$C)
  reference <- vapply(seq_len(n_cv), function(i) {
    tbl <- table(labels[m$assignments == i])
    if (sum(tbl) == 0) NA_character_ else names(tbl)[which.max(tbl)]
  }, character(1))
  expect_identical(resolve_color_by(m, "codebook", n_cv, labels),
                   as.factor(reference))
  expect_identical(resolve_color_by(m, "graph", n_cv, as.character(labels)),
                   as.factor(reference))
  # A coding vector without assigned points receives a missing label.
  m$assignments[m$assignments == 1L] <- 2L
  expect_true(is.na(resolve_color_by(m, "codebook", n_cv, labels)[1L]))
})

test_that("numeric input-length values map to the mean of each coding vector", {
  m <- fit_small(n = 150L)
  value <- iris$Sepal.Length
  value[c(5L, 90L)] <- NA
  n_cv <- nrow(m$C)
  reference <- vapply(seq_len(n_cv), function(i) {
    assigned <- value[m$assignments == i]
    assigned <- assigned[is.finite(assigned)]
    if (length(assigned) == 0L) NA_real_ else mean(assigned)
  }, numeric(1))
  mapped <- resolve_color_by(m, "graph", n_cv, value)
  expect_type(mapped, "double")
  expect_equal(mapped, reference)
  # Values that already have coding-vector length are used as supplied.
  expect_identical(resolve_color_by(m, "codebook", n_cv, reference), reference)
})

test_that("dispersion places coding vectors at the centroid of their points", {
  skip_if_not_installed("uwot")
  m <- song(as.matrix(iris[, 1:4]), epochs = 4L, seed = 1L, verbose = FALSE)
  used <- sort(unique(m$assignments))
  centroids <- t(vapply(used, function(cv) {
    colMeans(m$embedding[m$assignments == cv, , drop = FALSE])
  }, numeric(2)))
  expect_equal(m$Y[used, , drop = FALSE], centroids, ignore_attr = TRUE)
})

test_that("unassigned coding vectors are placed inside the dispersed layout", {
  Y <- rbind(c(0, 0), c(10, 0), c(0, 10), c(-900, 900), c(500, -500))
  occupied <- c(TRUE, TRUE, TRUE, FALSE, FALSE)
  E_s <- matrix(0, 5L, 5L)
  E_s[4L, c(1L, 2L)] <- E_s[c(1L, 2L), 4L] <- c(1, 3)
  C <- rbind(c(0, 0, 0), c(1, 0, 0), c(0, 1, 0), c(5, 5, 5), c(0, 0.9, 0))
  placed <- .song_place_unassigned(Y, occupied, E_s, C)
  expect_identical(placed[1:3, ], Y[1:3, ])
  # Edge-weighted mean of the occupied neighbours 1 and 2 (weights 1 and 3).
  expect_equal(placed[4L, ], c(7.5, 0))
  # No occupied neighbour: copy the occupied vector nearest in input space.
  expect_identical(placed[5L, ], Y[3L, ])
  expect_identical(.song_place_unassigned(Y, rep(TRUE, 5L), E_s, C), Y)

  skip_if_not_installed("uwot")
  m <- song(songR_blobs$data, epochs = 15L, seed = 42L, verbose = FALSE)
  unassigned <- setdiff(seq_len(nrow(m$C)), m$assignments)
  expect_gt(length(unassigned), 0L)
  limits <- apply(m$embedding, 2L, range)
  for (j in seq_len(ncol(m$Y))) {
    expect_true(all(m$Y[, j] >= limits[1L, j] & m$Y[, j] <= limits[2L, j]))
  }
  # Projection onto such a vector stays inside the layout as well.
  projected <- predict(m, m$C[unassigned, , drop = FALSE])
  expect_true(all(projected[, 1L] >= limits[1L, 1L] & projected[, 1L] <= limits[2L, 1L]))
})
