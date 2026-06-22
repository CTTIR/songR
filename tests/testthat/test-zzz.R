# Tests for the S3-method registration machinery in zzz.R.

test_that("register_s3_method registers autoplot for ggplot2 when loaded", {
  skip_if_not_installed("ggplot2")
  # ggplot2 is loaded by the time this runs in most setups; force it.
  loadNamespace("ggplot2")
  expect_no_error(
    songR:::register_s3_method("ggplot2", "autoplot", "song_model")
  )
  # The autoplot.song_model method itself must be a function in songR.
  expect_true(is.function(getNamespace("songR")$autoplot.song_model))
  # And it must dispatch from ggplot2::autoplot on a song_model object.
  m <- song(as.matrix(iris[1:30, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  p <- ggplot2::autoplot(m)
  expect_s3_class(p, "ggplot")
})

test_that(".onLoad runs without error and registers the autoplot method", {
  # Calling .onLoad again is idempotent; it must not error.
  expect_no_error(songR:::.onLoad("songR", "songR"))
})

test_that("register_s3_method sets a package onLoad hook", {
  skip_if_not_installed("ggplot2")
  songR:::register_s3_method("ggplot2", "autoplot", "song_model")
  hooks <- getHook(packageEvent("ggplot2", "onLoad"))
  expect_true(length(hooks) >= 1L)
  expect_true(all(vapply(hooks, is.function, logical(1))))
})
