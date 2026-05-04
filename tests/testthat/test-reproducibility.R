test_that("same seed produces identical embeddings", {
  m <- as.matrix(iris[, 1:4])
  model1 <- song(m, epochs = 5L, seed = 123, verbose = FALSE)
  model2 <- song(m, epochs = 5L, seed = 123, verbose = FALSE)

  expect_equal(model1$embedding, model2$embedding)
  expect_equal(model1$C, model2$C)
  expect_equal(model1$Y, model2$Y)
})

test_that("different seeds produce different embeddings", {
  m <- as.matrix(iris[, 1:4])
  model1 <- song(m, epochs = 5L, seed = 1, verbose = FALSE)
  model2 <- song(m, epochs = 5L, seed = 2, verbose = FALSE)

  # Embeddings should differ (extremely unlikely to be identical)
  expect_false(identical(model1$embedding, model2$embedding))
})

test_that("predict returns correct dimensions", {
  m <- as.matrix(iris[1:120, 1:4])
  model <- song(m, epochs = 5L, seed = 42, verbose = FALSE)
  new_coords <- predict(model, newdata = as.matrix(iris[121:150, 1:4]))

  expect_equal(nrow(new_coords), 30)
  expect_equal(ncol(new_coords), 2)
})

test_that("predict rejects mismatched dimensions", {
  model <- song(as.matrix(iris[, 1:4]), epochs = 3L, seed = 42, verbose = FALSE)
  expect_error(predict(model, newdata = matrix(1:10, ncol = 2)),
               "must have 4 columns")
})
