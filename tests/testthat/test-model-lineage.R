lineage_fixture <- function() {
  x <- matrix(sin(seq_len(240)), ncol = 4)
  colnames(x) <- paste0("feature", 1:4)
  list(x = x, model = song(x, epochs = 3L, seed = 17L,
                           dispersion = FALSE, verbose = FALSE))
}

test_that("training and updates declare distinct projection versions", {
  f <- lineage_fixture()
  before <- serialize(f$model, NULL)
  updated <- update(f$model, f$x + 0.2, epochs = 2L, verbose = FALSE)
  expect_identical(serialize(f$model, NULL), before)
  expect_identical(f$model$lineage$revision, 1L)
  expect_null(f$model$lineage$parent_model_id)
  expect_identical(updated$lineage$revision, 2L)
  expect_identical(updated$lineage$parent_model_id, f$model$lineage$model_id)
  expect_false(identical(updated$lineage$model_id, f$model$lineage$model_id))
  expect_identical(updated$lineage$projection_policy, "reproject_all_with_updated_model")
  expect_identical(updated$lineage$embedding_scope, "update_batch_only")
  expect_equal(nrow(updated$embedding), nrow(f$x))
  expect_equal(updated$n_input, 2 * nrow(f$x))
  again <- update(updated, f$x, epochs = 1L, verbose = FALSE)
  expect_identical(again$lineage$revision, 3L)
  expect_identical(again$lineage$parent_model_id, updated$lineage$model_id)
})

test_that("frozen projection survives persistence and matches nearest-prototype oracle", {
  f <- lineage_fixture()
  before <- serialize(f$model, NULL)
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(f$model, path)
  loaded <- readRDS(path)
  expected_indices <- apply(f$x, 1L, function(row) {
    which.min(rowSums(sweep(f$model$C, 2L, row)^2))
  })
  expected <- f$model$Y[expected_indices, , drop = FALSE]
  expect_identical(predict(f$model, f$x), expected)
  expect_identical(predict(loaded, f$x), expected)
  expect_identical(serialize(f$model, NULL), before)
  expect_identical(loaded$lineage, f$model$lineage)
})

test_that("legacy updates explicitly identify unknown earlier history", {
  f <- lineage_fixture()
  f$model$lineage <- NULL
  updated <- update(f$model, f$x, epochs = 1L, verbose = FALSE)
  expect_identical(updated$lineage$revision, 1L)
  expect_identical(updated$lineage$parent_history, "legacy_unversioned")
  expect_match(updated$lineage$parent_model_id, "^[a-f0-9]{64}$")
  expect_null(f$model$lineage)
})

test_that("malformed lineage is refused before retraining", {
  f <- lineage_fixture()
  for (bad in list(list(), "bad", list(schema_version = "99"))) {
    f$model$lineage <- bad
    expect_error(update(f$model, f$x, epochs = 1L, verbose = FALSE),
                 class = "song_error_lineage")
  }
})

test_that("updated model and frozen projections survive serialization deterministically", {
  f <- lineage_fixture()
  a <- update(f$model, f$x + 0.2, epochs = 2L, verbose = FALSE, seed = 19L)
  b <- update(f$model, f$x + 0.2, epochs = 2L, verbose = FALSE, seed = 19L)
  expect_identical(a$lineage, b$lineage)
  expect_identical(a$C, b$C)
  expect_identical(a$Y, b$Y)
  loaded <- unserialize(serialize(a, NULL, version = 2L))
  expect_identical(predict(loaded, f$x), predict(a, f$x))
  expect_identical(loaded$lineage, a$lineage)
})

test_that("lineage refuses invalid scalar fields and contradictory policies", {
  f <- lineage_fixture()
  invalid <- list(
    revision = list(NA_integer_, 0L, 1.5, c(1L, 2L), .Machine$integer.max),
    model_id = list(NA_character_, "short", c(rep("a", 64), "b")),
    parent_model_id = list("invalid", paste(rep("a", 64), collapse = "")),
    parent_history = list(NA_character_, "versioned", "legacy_unversioned", "unknown"),
    projection_policy = list(NA_character_, "reproject_all_with_updated_model"),
    embedding_scope = list("update_batch_only", NA_character_)
  )
  for (field in names(invalid)) {
    for (value in invalid[[field]]) {
      changed <- f$model
      changed$lineage[[field]] <- value
      expect_error(update(changed, f$x, epochs = 1L, verbose = FALSE),
                   class = "song_error_lineage")
    }
  }
})

test_that("projection identity binds codebook coordinates and feature semantics", {
  f <- lineage_fixture()
  make_lineage <- songR:::.song_model_lineage
  expect_identical(make_lineage(f$model), f$model$lineage)
  for (field in c("C", "Y", "feature_contract")) {
    changed <- f$model
    if (field == "feature_contract") {
      changed$feature_contract$features[1] <- "changed_feature"
    } else {
      changed[[field]][1, 1] <- changed[[field]][1, 1] + 1
    }
    expect_false(identical(make_lineage(changed)$model_id, f$model$lineage$model_id))
  }
})

test_that("fully legacy positional models acquire a new revision history", {
  f <- lineage_fixture()
  f$model$lineage <- NULL
  f$model$feature_contract <- NULL
  x <- unname(f$x)
  expect_identical(predict(f$model, x), predict(f$model, f$x))
  first <- update(f$model, x, epochs = 1L, verbose = FALSE)
  second <- update(first, x, epochs = 1L, verbose = FALSE)
  expect_identical(first$lineage$parent_history, "legacy_unversioned")
  expect_identical(second$lineage$revision, 2L)
  expect_identical(second$lineage$parent_model_id, first$lineage$model_id)
  second$lineage$revision <- 1L
  expect_error(update(second, x, epochs = 1L, verbose = FALSE), class = "song_error_lineage")
})

test_that("update seeds are explicit and reject malformed values", {
  f <- lineage_fixture()
  for (seed in list(NA_integer_, Inf, 1.5, c(1L, 2L), "1")) {
    expect_error(update(f$model, f$x, epochs = 1L, verbose = FALSE, seed = seed),
                 "seed")
  }
  set.seed(22)
  a <- update(f$model, f$x, epochs = 1L, verbose = FALSE)
  set.seed(22)
  b <- update(f$model, f$x, epochs = 1L, verbose = FALSE, seed = NULL)
  expect_identical(a, b)
  seeded <- update(f$model, f$x, epochs = 1L, verbose = FALSE, seed = 22L)
  expect_identical(seeded$parameters$update_seed, 22L)
  expect_identical(a$C, seeded$C)
})
