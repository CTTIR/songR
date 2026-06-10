test_that("plot methods run for all types", {
  model <- song(as.matrix(iris[, 1:4]), epochs = 4L, seed = 42, verbose = FALSE)
  tmp <- tempfile(fileext = ".png")
  grDevices::png(tmp)
  on.exit({ grDevices::dev.off(); unlink(tmp) }, add = TRUE)

  expect_no_error(plot(model, color_by = iris$Species))
  expect_no_error(plot(model, type = "codebook", color_by = iris$Species))
  expect_no_error(plot(model, type = "graph", color_by = iris$Species))
  expect_no_error(plot(model))  # no color_by
})

test_that("plot errors on wrong-length color_by", {
  model <- song(as.matrix(iris[, 1:4]), epochs = 4L, seed = 42, verbose = FALSE)
  tmp <- tempfile(fileext = ".png")
  grDevices::png(tmp)
  on.exit({ grDevices::dev.off(); unlink(tmp) }, add = TRUE)

  expect_error(plot(model, color_by = 1:10), "input points")
  expect_error(plot(model, type = "codebook", color_by = 1:10),
               "coding vectors")
})

test_that("autoplot returns a ggplot for all types", {
  skip_if_not_installed("ggplot2")
  model <- song(as.matrix(iris[, 1:4]), epochs = 4L, seed = 42, verbose = FALSE)

  expect_s3_class(autoplot.song_model(model, color_by = iris$Species), "ggplot")
  # input-length color_by on graph/codebook is mapped to coding vectors
  expect_s3_class(
    autoplot.song_model(model, type = "graph", color_by = iris$Species),
    "ggplot"
  )
  expect_s3_class(autoplot.song_model(model, type = "codebook"), "ggplot")
})

test_that("autoplot errors on wrong-length color_by", {
  skip_if_not_installed("ggplot2")
  model <- song(as.matrix(iris[, 1:4]), epochs = 4L, seed = 42, verbose = FALSE)
  expect_error(
    autoplot.song_model(model, type = "graph", color_by = 1:7),
    "coding vectors"
  )
})

test_that("predict maps new points onto existing coding-vector coordinates", {
  m <- as.matrix(iris[, 1:4])
  model <- song(m[1:120, ], epochs = 5L, seed = 42, verbose = FALSE,
                dispersion = FALSE)
  pc <- predict(model, newdata = m[121:150, ])

  expect_equal(nrow(pc), 30L)
  expect_equal(ncol(pc), 2L)

  # Every predicted coordinate must be an exact row of the model's embedding Y
  in_Y <- apply(pc, 1L, function(r) {
    any(abs(model$Y[, 1] - r[1]) < 1e-9 & abs(model$Y[, 2] - r[2]) < 1e-9)
  })
  expect_true(all(in_Y))
})
