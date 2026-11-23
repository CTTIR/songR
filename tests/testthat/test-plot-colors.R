# Regression tests for colour mapping, legends and argument forwarding in
# plot.song_model() and autoplot.song_model().

local_null_device <- function(env = parent.frame()) {
  grDevices::pdf(NULL)
  withr::defer(grDevices::dev.off(), envir = env)
}

fit_small <- function(n = 60L, ...) {
  song(as.matrix(iris[seq_len(n), 1:4]), epochs = 4L, seed = 1L,
       verbose = FALSE, dispersion = FALSE, ...)
}

is_color <- function(x) {
  !inherits(try(grDevices::col2rgb(x), silent = TRUE), "try-error")
}

test_that("numeric color_by is mapped onto a sequential palette", {
  value <- c(-2.5, 0, 0.37, 4, NA, Inf)
  colors <- .song_point_colors(value)
  ramp <- grDevices::hcl.colors(100L, palette = "viridis")
  expect_true(is_color(colors$col))
  expect_identical(colors$col[1L], ramp[1L])
  expect_identical(colors$col[4L], ramp[100L])
  expect_identical(colors$col[5:6], rep("grey70", 2L))
  # The key lists five evenly spaced values from the maximum to the minimum.
  expect_identical(colors$levels, c("4", "2.38", "0.75", "-0.875", "-2.5"))
  expect_identical(colors$palette[c(1L, 5L)], ramp[c(100L, 1L)])
  expect_identical(colors$missing, "grey70")
  # Monotone: larger values never map to an earlier palette entry.
  finite <- sort(stats::rnorm(50))
  expect_false(is.unsorted(match(.song_point_colors(finite)$col, ramp)))
  # Constant and all-missing vectors still give one valid colour per point.
  constant <- .song_point_colors(rep(3, 4L))
  expect_identical(constant$col, rep(ramp[50L], 4L))
  expect_identical(constant$levels, "3")
  expect_null(constant$missing)
  all_missing <- .song_point_colors(rep(NA_real_, 3L))
  expect_identical(all_missing$col, rep("grey70", 3L))
  expect_null(all_missing$levels)
  expect_true(is_color(.song_point_colors(1:5)$col))
})

test_that("categorical color_by keeps levels and marks missing labels", {
  colors <- .song_point_colors(c("a", "b", NA, "a"))
  expect_identical(colors$levels, c("a", "b"))
  expect_length(colors$palette, 2L)
  expect_identical(colors$col[c(1L, 4L)], rep(colors$palette[1L], 2L))
  expect_identical(colors$col[3L], "grey70")
  expect_identical(colors$missing, "grey70")
  expect_null(.song_point_colors(factor(c("a", "b")))$missing)
  # Logical vectors are categories, not colour numbers (FALSE was invisible).
  logical_colors <- .song_point_colors(c(TRUE, FALSE, TRUE))
  expect_identical(logical_colors$levels, c("FALSE", "TRUE"))
  expect_true(is_color(logical_colors$col))
  expect_identical(.song_point_colors(NULL)$col, "steelblue")
})

test_that("plot draws continuous, negative and logical color_by values", {
  local_null_device()
  m <- fit_small()
  set.seed(3)
  expect_no_error(plot(m, color_by = stats::rnorm(60)))
  expect_no_error(plot(m, color_by = stats::runif(60)))
  expect_no_error(plot(m, color_by = c(NA, stats::rnorm(59))))
  expect_no_error(plot(m, color_by = rep(c(TRUE, FALSE), 30L)))
  expect_no_error(plot(m, type = "codebook", color_by = seq_len(nrow(m$C)) - 3))
  expect_no_error(plot(m, type = "graph", color_by = iris$Sepal.Length[1:60]))
})

test_that("plot forwards graphical arguments that override its defaults", {
  local_null_device()
  m <- fit_small()
  expect_no_error(
    plot(m, color_by = iris$Species[1:60], main = "Custom", xlab = "x",
         ylab = "y", pch = 17, cex = 1.2, xlim = c(-5, 5))
  )
  expect_no_error(plot(m, type = "graph", pch = 1, cex = 1, legend = FALSE))
  # `col` partially matches `color_by`, so it is validated as point labels.
  expect_error(plot(m, col = "black"), "color_by must have length")
  expect_error(plot(m, legend = NA), "`legend`")
  expect_error(plot(m, type = "nonsense"))
})

test_that("the legend is drawn for few categories in the emptiest corner", {
  local_null_device()
  graphics::plot(c(0, 10), c(0, 10), type = "n")
  # All points sit in the top-right quarter, so that corner must be avoided.
  coords <- cbind(stats::runif(200, 7, 10), stats::runif(200, 7, 10))
  colors <- .song_point_colors(rep(c("a", "b"), 100L))
  corner <- .song_plot_legend(coords, colors)
  expect_true(corner %in% c("topleft", "bottomright", "bottomleft"))
  with_missing <- .song_point_colors(c("a", NA))
  expect_type(.song_plot_legend(coords, with_missing), "character")
  # A numeric color_by gets a five-value key.
  expect_type(.song_plot_legend(coords, .song_point_colors(1:200)), "character")
  # No legend without color_by, without finite values or above twelve levels.
  expect_null(.song_plot_legend(coords, .song_point_colors(NULL)))
  expect_null(.song_plot_legend(coords, .song_point_colors(rep(NA_real_, 200L))))
  many <- .song_point_colors(as.character(seq_len(13L)))
  expect_null(.song_plot_legend(coords, many))
})

test_that("autoplot reports one-dimensional embeddings clearly", {
  skip_if_not_installed("ggplot2")
  set.seed(5)
  m <- song(matrix(stats::rnorm(80), ncol = 1), d = 1L, k = 2L, epochs = 3L,
            seed = 1L, verbose = FALSE, dispersion = FALSE)
  expect_error(autoplot.song_model(m), "output dimensionality < 2")
})
