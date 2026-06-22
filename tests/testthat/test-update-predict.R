# Extra coverage for update.song_model / predict.song_model branches.

test_that("update reconstructs adj for a legacy model lacking $adj", {
  m <- song(as.matrix(iris[1:80, 1:4]), epochs = 4L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  # Simulate an old model object saved before $adj existed.
  m$adj <- NULL
  m2 <- update(m, as.matrix(iris[81:120, 1:4]), epochs = 3L, verbose = FALSE)
  expect_s3_class(m2, "song_model")
  expect_equal(ncol(m2$C), 4L)
})

test_that("update falls back to original alpha when alpha = NULL", {
  m <- song(as.matrix(iris[1:80, 1:4]), epochs = 4L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  m2 <- update(m, as.matrix(iris[81:120, 1:4]), epochs = 3L,
               alpha = NULL, verbose = FALSE)
  expect_s3_class(m2, "song_model")
  expect_equal(m2$parameters$epochs, m$parameters$epochs + 3L)
})

test_that("update accepts an explicit alpha", {
  m <- song(as.matrix(iris[1:80, 1:4]), epochs = 4L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  m2 <- update(m, as.matrix(iris[81:120, 1:4]), epochs = 3L,
               alpha = 0.5, verbose = FALSE)
  expect_s3_class(m2, "song_model")
  expect_equal(m2$n_input, 120L)
})

test_that("update tolerates models with NULL lr_sigma and NULL seed in params", {
  m <- song(as.matrix(iris[1:80, 1:4]), epochs = 4L, seed = NULL,
            verbose = FALSE, dispersion = FALSE)
  m$parameters$lr_sigma <- NULL
  m2 <- update(m, as.matrix(iris[81:120, 1:4]), epochs = 2L, verbose = FALSE)
  expect_s3_class(m2, "song_model")
})

test_that("predict returns one embedding row per new point", {
  m <- song(as.matrix(iris[1:120, 1:4]), epochs = 4L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  pc <- predict(m, newdata = as.matrix(iris[121:150, 1:4]))
  expect_equal(dim(pc), c(30L, 2L))
})
