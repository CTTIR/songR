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

test_that("up to eight categories use the Okabe-Ito palette", {
  okabe_ito <- unname(grDevices::palette.colors(8L, palette = "Okabe-Ito"))
  eight <- .song_qualitative_palette(8L)
  # Yellow and black come last; black follows the foreground color.
  expect_identical(eight, c(okabe_ito[c(2:4, 6:8, 5L)], "black"))
  expect_identical(eight[7L], "#F0E442")
  expect_identical(.song_qualitative_palette(8L, ink = "#EEEEEE")[8L], "#EEEEEE")
  expect_identical(.song_qualitative_palette(3L), eight[1:3])
  expect_identical(.song_qualitative_palette(0L), character(0))
  # More categories fall back to distinct, valid colors.
  many <- .song_qualitative_palette(11L)
  expect_length(unique(many), 11L)
  expect_true(is_color(many))
  # Point colors use the palette and pass the foreground color on.
  colors <- .song_point_colors(factor(letters[1:8]), ink = "white")
  expect_identical(colors$palette, c(eight[1:7], "white"))
})

test_that("graph edges follow the foreground color of the device", {
  skip_on_cran() # replaces a binding in the graphics namespace
  m <- fit_small()
  edge_colors <- function(fg) {
    local_null_device()
    graphics::par(fg = fg)
    seen <- NULL
    testthat::local_mocked_bindings(
      segments = function(..., col) seen <<- col,
      .package = "graphics"
    )
    plot(m, type = "graph")
    seen
  }
  on_light <- grDevices::col2rgb(edge_colors("black"), alpha = TRUE)
  on_dark <- grDevices::col2rgb(edge_colors("white"), alpha = TRUE)
  expect_true(all(on_light[1:3, ] == 0))
  expect_true(all(on_dark[1:3, ] == 255))
  # Opacity is 60 % of the edge weight in both cases.
  expect_identical(on_light[4L, ], on_dark[4L, ])
  expect_true(all(on_light[4L, ] > 0 & on_light[4L, ] <= 153))
})

test_that("autoplot uses the color scales of plot()", {
  skip_if_not_installed("ggplot2")
  m <- fit_small()
  point_colors <- function(p) {
    built <- ggplot2::ggplot_build(p)
    built$data[[length(built$data)]]$colour
  }
  species <- iris$Species[1:60]
  categorical <- point_colors(autoplot.song_model(m, color_by = species))
  expect_identical(
    categorical,
    .song_qualitative_palette(3L)[as.integer(species)]
  )
  with_missing <- c(NA, as.character(species[-1L]))
  expect_identical(
    point_colors(autoplot.song_model(m, color_by = with_missing))[1L], "grey70"
  )
  numeric <- autoplot.song_model(m, color_by = iris$Sepal.Length[1:60])
  shade <- point_colors(numeric)
  order_value <- order(iris$Sepal.Length[1:60])
  expect_identical(
    toupper(shade[order_value[c(1L, 60L)]]), c("#440154", "#FDE725")
  )
  # More than eight categories keep the default discrete scale.
  many <- autoplot.song_model(m, color_by = rep(letters[1:10], 6L))
  expect_length(unique(point_colors(many)), 10L)
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
  # A long legend leaves the corners when every corner holds points.
  graphics::plot(c(0, 10), c(0, 10), type = "n")
  at_corners <- cbind(rep(c(0, 10), each = 100L), rep(c(0, 10), 100L))
  eight <- .song_point_colors(rep(letters[1:8], 25L))
  expect_true(
    .song_plot_legend(at_corners, eight) %in% c("right", "left", "bottom", "top")
  )
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

test_that("a numeric range wider than the largest double still maps to colors", {
  wide <- .song_point_colors(c(-1e308, 1e308, 0))
  expect_false(anyNA(wide$col))
  expect_length(unique(wide$col), 3L)
  expect_false(anyNA(wide$palette))
  expect_length(wide$levels, 5L)
  expect_false(any(grepl("Inf|NaN|NA", wide$levels)))
})
