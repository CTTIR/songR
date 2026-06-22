# Tests for run_songR_app() guard branches.
# The actual Shiny launch is interactive and excluded from coverage; here we
# only exercise the dependency-check abort, which is pure and side-effect free.

test_that("run_songR_app aborts when a required package is missing", {
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )
  expect_error(run_songR_app(), "required for the comparison app")
})

test_that("run_songR_app abort message names the missing package and install hint", {
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )
  err <- tryCatch(run_songR_app(), error = function(e) e)
  expect_s3_class(err, "rlang_error")
  msg <- paste(conditionMessage(err), collapse = " ")
  expect_match(msg, "shiny")
})
