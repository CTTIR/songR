# Additional coverage for plot.song_model branches not hit elsewhere.

# A null graphics device that captures plotting without writing files.
local_null_device <- function(env = parent.frame()) {
  grDevices::pdf(NULL)
  withr::defer(grDevices::dev.off(), envir = env)
}

test_that("plot uses a numeric color_by directly (continuous path)", {
  local_null_device()
  m <- song(as.matrix(iris[1:60, 1:4]), epochs = 4L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  expect_no_error(plot(m, color_by = as.numeric(1:60)))
})

test_that("plot uses a character color_by (factor path)", {
  local_null_device()
  m <- song(as.matrix(iris[1:60, 1:4]), epochs = 4L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  expect_no_error(plot(m, color_by = as.character(iris[1:60, 5])))
})

test_that("plot aborts when output dimensionality is < 2", {
  local_null_device()
  m <- song(matrix(rnorm(80), ncol = 1), d = 1L, k = 2L, epochs = 3L,
            seed = 1L, verbose = FALSE, dispersion = FALSE)
  expect_error(plot(m), "output dimensionality < 2")
})

test_that("plot graph type draws edges and redraws points", {
  local_null_device()
  m <- song(as.matrix(iris[1:80, 1:4]), epochs = 6L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  expect_no_error(plot(m, type = "graph"))
  expect_no_error(plot(m, type = "graph", color_by = iris[1:80, 5]))
})

test_that("autoplot graph type with edges returns a ggplot", {
  skip_if_not_installed("ggplot2")
  m <- song(as.matrix(iris[1:80, 1:4]), epochs = 6L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  p <- autoplot.song_model(m, type = "graph")
  expect_s3_class(p, "ggplot")
})

test_that("autoplot aborts when ggplot2 is unavailable", {
  testthat::local_mocked_bindings(
    requireNamespace = function(pkg, ...) if (identical(pkg, "ggplot2")) FALSE else TRUE,
    .package = "base"
  )
  m <- song(as.matrix(iris[1:40, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  expect_error(autoplot.song_model(m), "ggplot2.*is required")
})
