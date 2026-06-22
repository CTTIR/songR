# Direct unit tests for the internal validation / resolution helpers.

test_that("validate_input coerces a numeric data.frame to a matrix", {
  df <- iris[1:5, 1:4]
  out <- songR:::validate_input(df)
  expect_true(is.matrix(out))
  expect_type(out, "double")
  expect_equal(dim(out), c(5L, 4L))
})

test_that("validate_input rejects a data.frame with a non-numeric column", {
  df <- data.frame(a = 1:5, b = letters[1:5])
  expect_error(songR:::validate_input(df), "columns in the data.frame must be numeric")
})

test_that("validate_input rejects a non-matrix, non-data.frame", {
  expect_error(songR:::validate_input(list(1, 2, 3)), "numeric matrix or data.frame")
})

test_that("validate_input rejects a character matrix", {
  expect_error(songR:::validate_input(matrix("x", 3, 2)), "numeric matrix")
})

test_that("validate_input rejects NA, Inf and < 2 rows", {
  m <- matrix(1:6, ncol = 2)
  m_na <- m; m_na[1, 1] <- NA
  expect_error(songR:::validate_input(m_na), "NA")
  m_inf <- m; m_inf[2, 2] <- Inf
  expect_error(songR:::validate_input(m_inf), "Inf")
  expect_error(songR:::validate_input(matrix(1:2, nrow = 1)), "at least 2 rows")
})

test_that("validate_input returns a clean matrix unchanged", {
  m <- matrix(as.numeric(1:6), ncol = 2)
  expect_identical(songR:::validate_input(m), m)
})

test_that("validate_params accepts a valid parameter set", {
  expect_invisible(
    songR:::validate_params(d = 2, k = 3, epsilon = 0.9, alpha = 1, a = 1.5,
                            b = 0.9, spread_factor = 0.5, neg_sample_rate = 5,
                            e_min = 0.1, epochs = 10)
  )
  expect_null(
    songR:::validate_params(2, 3, 0.9, 1, 1.5, 0.9, 0.5, 5, 0.1, 10)
  )
})

test_that("validate_params flags each invalid parameter individually", {
  ok <- list(d = 2, k = 3, epsilon = 0.9, alpha = 1, a = 1.5, b = 0.9,
             spread_factor = 0.5, neg_sample_rate = 5, e_min = 0.1, epochs = 10)
  call_vp <- function(mods) do.call(songR:::validate_params, modifyList(ok, mods))

  expect_error(call_vp(list(d = 0.5)),            "`d` must be a positive integer")
  expect_error(call_vp(list(k = 2)),              "`k` must be >= d \\+ 1")
  expect_error(call_vp(list(epsilon = 1.5)),      "`epsilon` must be in")
  expect_error(call_vp(list(epsilon = 0)),        "`epsilon` must be in")
  expect_error(call_vp(list(alpha = 0)),          "`alpha` must be positive")
  expect_error(call_vp(list(a = -1)),             "`a` must be positive")
  expect_error(call_vp(list(b = 0)),              "`b` must be positive")
  expect_error(call_vp(list(spread_factor = 1)),  "`spread_factor` must be in")
  expect_error(call_vp(list(neg_sample_rate = 0)),"`neg_sample_rate`")
  expect_error(call_vp(list(e_min = 0)),          "`e_min` must be positive")
  expect_error(call_vp(list(epochs = 0)),         "`epochs`")
})

test_that("resolve_color_by returns NULL for NULL input", {
  m <- song(as.matrix(iris[1:40, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  expect_null(songR:::resolve_color_by(m, "embedding", nrow(m$embedding), NULL))
})

test_that("resolve_color_by passes through matching-length embedding vector", {
  m <- song(as.matrix(iris[1:40, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  cb <- iris[1:40, 5]
  expect_identical(
    songR:::resolve_color_by(m, "embedding", nrow(m$embedding), cb),
    cb
  )
})

test_that("resolve_color_by errors on wrong-length embedding vector", {
  m <- song(as.matrix(iris[1:40, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  expect_error(
    songR:::resolve_color_by(m, "embedding", nrow(m$embedding), 1:3),
    "input points"
  )
})

test_that("resolve_color_by uses coding-vector-length vector directly", {
  m <- song(as.matrix(iris[1:40, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  ncv <- nrow(m$C)
  cb <- factor(rep("x", ncv))
  expect_identical(
    songR:::resolve_color_by(m, "codebook", ncv, cb),
    cb
  )
})

test_that("resolve_color_by maps input-length labels to coding vectors via modal label", {
  m <- song(as.matrix(iris[1:60, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  ncv <- nrow(m$C)
  mapped <- songR:::resolve_color_by(m, "graph", ncv, iris[1:60, 5])
  expect_s3_class(mapped, "factor")
  expect_length(mapped, ncv)
})

test_that("resolve_color_by yields NA for coding vectors with no assigned points", {
  # Synthetic model whose assignments never reference coding vector 2 -> NA.
  fake <- structure(
    list(assignments = rep(1L, 4L), n_input = 4L),
    class = "song_model"
  )
  mapped <- songR:::resolve_color_by(fake, "codebook", 2L,
                                     color_by = factor(c("a", "a", "b", "b")))
  expect_length(mapped, 2L)
  expect_true(is.na(mapped[2]))
})

test_that("resolve_color_by errors when length matches neither coding vectors nor input", {
  m <- song(as.matrix(iris[1:40, 1:4]), epochs = 3L, seed = 1L,
            verbose = FALSE, dispersion = FALSE)
  expect_error(
    songR:::resolve_color_by(m, "graph", nrow(m$C), rep(1, m$n_input + 999L)),
    "coding vectors"
  )
})
