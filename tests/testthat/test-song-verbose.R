# Coverage for verbose / dispersion-message paths and print/summary detail.

test_that("song(verbose = TRUE) emits progress without error", {
  expect_no_error(
    suppressMessages(
      song(as.matrix(iris[1:40, 1:4]), epochs = 3L, seed = 1L,
           verbose = TRUE, dispersion = FALSE)
    )
  )
})

test_that("song dispersion step emits a message when uwot is available", {
  skip_if_not_installed("uwot")
  expect_message(
    song(as.matrix(iris[1:60, 1:4]), epochs = 3L, seed = 1L,
         verbose = TRUE, dispersion = TRUE),
    "dispersion"
  )
})

test_that("song with dispersion produces a 2-column embedding via uwot", {
  skip_if_not_installed("uwot")
  m <- song(as.matrix(iris[1:80, 1:4]), epochs = 4L, seed = 1L,
            verbose = FALSE, dispersion = TRUE)
  expect_equal(ncol(m$embedding), 2L)
  expect_equal(nrow(m$embedding), 80L)
})

test_that("print reports points, coding vectors, edges and epoch status", {
  m <- song(as.matrix(iris[1:60, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  out <- paste(capture.output(res <- print(m)), collapse = "\n")
  expect_match(out, "SONG model")
  expect_match(out, "Coding vectors:")
  expect_match(out, "Edges:")
  expect_match(out, "max epochs|converged")
  expect_identical(res, m)
})

test_that("summary reports compression ratio and parameters", {
  m <- song(as.matrix(iris[1:60, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  out <- paste(capture.output(res <- summary(m)), collapse = "\n")
  expect_match(out, "Compression ratio:")
  expect_match(out, "Parameters:")
  expect_match(out, "epsilon =")
  expect_identical(res, m)
})

test_that("print/summary handle a converged model and a no-edge model", {
  m <- song(as.matrix(iris[1:60, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)

  m_conv <- m
  m_conv$converged <- TRUE
  expect_match(paste(capture.output(print(m_conv)), collapse = "\n"), "converged")

  m_noedge <- m
  m_noedge$E_s <- matrix(0, nrow = nrow(m$C), ncol = nrow(m$C))
  out <- paste(capture.output(summary(m_noedge)), collapse = "\n")
  expect_match(out, "Edges: 0")
  expect_false(grepl("Mean edge strength", out))
})
