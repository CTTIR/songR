test_that("update() adds coding vectors", {
  model1 <- song(as.matrix(iris[1:100, 1:4]), epochs = 5L, seed = 42,
                 verbose = FALSE)
  n_coding_before <- nrow(model1$C)

  model2 <- update(model1, as.matrix(iris[101:150, 1:4]), epochs = 5L,
                   verbose = FALSE)
  n_coding_after <- nrow(model2$C)

  # Updated model should have at least as many coding vectors
  expect_gte(n_coding_after, n_coding_before)
})

test_that("update() returns valid song_model", {
  model1 <- song(as.matrix(iris[1:100, 1:4]), epochs = 3L, seed = 42,
                 verbose = FALSE)
  model2 <- update(model1, as.matrix(iris[101:150, 1:4]), epochs = 3L,
                   verbose = FALSE)

  expect_s3_class(model2, "song_model")
  expect_equal(ncol(model2$C), 4)
  expect_equal(ncol(model2$Y), 2)
})

test_that("update() rejects mismatched dimensions", {
  model <- song(as.matrix(iris[1:100, 1:4]), epochs = 3L, seed = 42,
                verbose = FALSE)
  expect_error(update(model, matrix(1:10, ncol = 2)),
               "must have 4 columns")
})
