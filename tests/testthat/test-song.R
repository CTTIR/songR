test_that("song() runs on iris without error", {
  model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42, verbose = FALSE)
  expect_s3_class(model, "song_model")
})

test_that("song() output has correct structure", {
  model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42, verbose = FALSE)

  # Embedding has n rows and d columns

  expect_equal(nrow(model$embedding), 150)
  expect_equal(ncol(model$embedding), 2)

  # Coding vectors exist and have correct dimensions
  expect_gt(nrow(model$C), 0)
  expect_equal(ncol(model$C), 4)

  # All assignments are valid indices into C
  expect_true(all(model$assignments >= 1))
  expect_true(all(model$assignments <= nrow(model$C)))

  # Y has same number of rows as C

  expect_equal(nrow(model$Y), nrow(model$C))
  expect_equal(ncol(model$Y), 2)
})

test_that("song() accepts data.frame input", {
  model <- song(iris[, 1:4], epochs = 3L, seed = 42, verbose = FALSE)
  expect_s3_class(model, "song_model")
})

test_that("song() with d = 3 works", {
  model <- song(as.matrix(iris[, 1:4]), d = 3L, k = 4L, epochs = 3L,
                seed = 42, verbose = FALSE)
  expect_equal(ncol(model$embedding), 3)
  expect_equal(ncol(model$Y), 3)
})

test_that("print and summary methods work", {
  model <- song(as.matrix(iris[, 1:4]), epochs = 3L, seed = 42, verbose = FALSE)
  expect_output(print(model), "SONG model")
  expect_output(summary(model), "SONG model summary")
})
