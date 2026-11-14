test_that("fit rejects invalid controls before native training or RNG changes", {
  x <- as.matrix(iris[1:30, 1:4])
  invalid <- list(
    list(d = 2.5), list(k = 3.5), list(epochs = 1.9),
    list(neg_sample_rate = 1.5), list(max_age = 0.5),
    list(max_prototypes = 2.5), list(max_prototypes = .Machine$integer.max),
    list(alpha = Inf), list(a = NaN), list(b = c(1, 2)),
    list(lr_sigma = -1), list(lr_sigma = Inf), list(e_min = numeric()),
    list(seed = 1.5), list(seed = c(1, 2)), list(verbose = NA),
    list(dispersion = 1), list(epsilon = 0.9 + 1i)
  )
  set.seed(71)
  before <- .Random.seed
  defaults <- list(X = x, epochs = 1L, dispersion = FALSE, verbose = FALSE, seed = 4L)
  for (args in invalid) {
    expect_error(do.call(song, utils::modifyList(defaults, args)),
                 regexp = paste0("`", names(args), "`"))
    expect_identical(.Random.seed, before)
  }
  expect_error(song(matrix(numeric(), nrow = 3L, ncol = 0L)), "feature column")
  expect_error(song(matrix(1 + 1i, 3L, 2L)), "numeric matrix")
})

test_that("update rejects invalid training controls without changing the model", {
  x <- as.matrix(iris[1:30, 1:4])
  model <- song(x, epochs = 1L, dispersion = FALSE, seed = 4L, verbose = FALSE)
  original <- serialize(model, NULL)
  for (epochs in list(0, -1, 1.5, Inf, NA_real_, c(1, 2), numeric())) {
    expect_error(update(model, x, epochs = epochs, verbose = FALSE), "`epochs`")
  }
  for (alpha in list(0, -1, Inf, NA_real_, c(1, 2), numeric())) {
    expect_error(update(model, x, epochs = 1L, alpha = alpha, verbose = FALSE), "`alpha`")
  }
  expect_identical(serialize(model, NULL), original)
})

test_that("damaged saved models are rejected before projection or retraining", {
  x <- as.matrix(iris[1:30, 1:4])
  model <- song(x, epochs = 1L, dispersion = FALSE, seed = 4L, verbose = FALSE)
  bad <- model
  bad$C <- bad$C[FALSE, , drop = FALSE]
  expect_error(predict(bad, x), class = "song_error_model")
  bad <- model
  bad$Y[1L, 1L] <- Inf
  expect_error(predict(bad, x), class = "song_error_model")
  bad <- model
  bad$adj <- matrix(0, 1L, 1L)
  expect_error(update(bad, x, epochs = 1L), class = "song_error_model")
  bad <- model
  bad$E_q <- numeric()
  expect_error(update(bad, x, epochs = 1L), class = "song_error_model")
})

test_that("one-row prediction agrees with nearest-prototype projection", {
  x <- as.matrix(iris[1:30, 1:4])
  model <- song(x, epochs = 1L, dispersion = FALSE, seed = 4L, verbose = FALSE)
  new <- x[5L, , drop = FALSE]
  nearest <- which.min(rowSums(sweep(model$C, 2L, new[1L, ], "-")^2))
  expected <- model$Y[nearest, , drop = FALSE]
  expect_equal(predict(model, new), expected)
  expect_equal(predict(model, as.data.frame(new)), expected)
  expect_error(predict(model, x[FALSE, , drop = FALSE]), "at least 1 rows")
})

test_that("negative seeds reproduce fit and update through the R random stream", {
  x <- as.matrix(iris[1:30, 1:4])
  fit <- function() song(x, epochs = 2L, dispersion = FALSE, seed = -4L, verbose = FALSE)
  a <- fit()
  b <- fit()
  expect_identical(a, b)
  update_fit <- function() update(a, x, epochs = 2L, seed = -9L, verbose = FALSE)
  expect_identical(update_fit(), update_fit())
})

test_that("cumulative training counts do not overflow R integers", {
  x <- as.matrix(iris[1:30, 1:4])
  model <- song(x, epochs = 1L, dispersion = FALSE, seed = 4L, verbose = FALSE)
  updated <- update(model, x, epochs = 1L, seed = 4L, verbose = FALSE)
  expect_identical(updated$parameters$epochs, 2L)
  expect_identical(updated$n_input, 60L)
  model$parameters$epochs <- .Machine$integer.max
  model$n_input <- .Machine$integer.max
  updated <- update(model, x, epochs = 1L, seed = 4L, verbose = FALSE)
  expect_identical(updated$parameters$epochs, as.double(.Machine$integer.max) + 1)
  expect_identical(updated$n_input, as.double(.Machine$integer.max) + nrow(x))
})

test_that("updated codebook colours use only labels for the current batch", {
  x <- as.matrix(iris[1:30, 1:4])
  model <- song(x, epochs = 1L, dispersion = FALSE, seed = 4L, verbose = FALSE)
  updated <- update(model, x[1:10, ], epochs = 1L, seed = 4L, verbose = FALSE)
  old_and_new <- c(rep("old", 30L), rep("new", 10L))
  expect_error(resolve_color_by(updated, "codebook", nrow(updated$C), old_and_new),
               "current batch")
  colours <- resolve_color_by(updated, "codebook", nrow(updated$C), rep("new", 10L))
  expect_true(all(as.character(colours[!is.na(colours)]) == "new"))
  missing <- resolve_color_by(updated, "graph", nrow(updated$C), rep(NA_character_, 10L))
  expect_true(all(is.na(missing)))
  missing_factor <- factor(rep(NA_character_, 10L), levels = c("old", "new"))
  mapped <- resolve_color_by(updated, "graph", nrow(updated$C), missing_factor)
  expect_true(all(is.na(mapped)))
})
