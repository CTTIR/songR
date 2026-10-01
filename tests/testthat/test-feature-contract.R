feature_training <- function() {
  cbind(feature_a = seq_len(30), feature_b = sin(seq_len(30)))
}
feature_model <- function(...) {
  song(feature_training(),
    epochs = 2L, dispersion = FALSE, seed = 7L,
    verbose = FALSE, ...
  )
}
feature_metadata <- function() {
  data.frame(
    feature = c("feature_a", "feature_b"),
    compartment = c("whole", "nucleus"), statistic = c("mean", "mean"),
    unit = c("a.u.", "a.u."), transform = c("identity", "asinh(cofactor=5)"),
    normalization = c("none", "reference-v1"), stringsAsFactors = FALSE
  )
}

test_that("named models reject reordered and missing feature identities", {
  model <- feature_model()
  x <- feature_training()[1:4, ]
  expect_error(predict(model, x[, 2:1]), class = "song_error_features")
  expect_error(update(model, x[, 2:1], epochs = 1L, verbose = FALSE),
    class = "song_error_features"
  )
  expect_error(predict(model, unname(x)), class = "song_error_features")
  colnames(x)[2] <- "different_feature"
  expect_error(predict(model, x), class = "song_error_features")
})

test_that("declared metadata survives storage and rejects incompatible projection", {
  manifest <- feature_metadata()
  model <- feature_model(feature_manifest = manifest)
  path <- tempfile(fileext = ".rds")
  withr::defer(unlink(path))
  saveRDS(model, path, version = 3L)
  restored <- readRDS(path)
  expect_identical(restored$feature_contract$manifest, manifest)
  x <- feature_training()[1:4, ]
  expect_error(predict(restored, x), class = "song_error_features")
  for (field in c("compartment", "statistic", "unit", "transform", "normalization")) {
    changed <- manifest
    changed[[field]][1] <- "incompatible"
    expect_error(predict(restored, x, feature_manifest = changed),
      class = "song_error_features"
    )
  }
  expect_identical(
    predict(restored, x, feature_manifest = manifest),
    predict(model, x, feature_manifest = manifest)
  )
  expect_error(predict(model, x, feature_manifest = manifest[2:1, ]),
    class = "song_error_features"
  )
})

test_that("frozen prediction matches a hand-calculated nearest-prototype oracle", {
  model <- feature_model()
  model$C <- matrix(c(0, 100, 100, 0), nrow = 2, byrow = TRUE)
  model$Y <- matrix(c(1, 2, 7, 8), nrow = 2, byrow = TRUE)
  x <- matrix(c(1, 99, 99, 1),
    nrow = 2, byrow = TRUE,
    dimnames = list(NULL, c("feature_a", "feature_b"))
  )
  before <- serialize(model, NULL)
  expect_identical(unname(predict(model, x)), model$Y)
  expect_identical(unname(predict(model, x[2:1, ])), model$Y[2:1, ])
  expect_identical(serialize(model, NULL), before)
})


test_that("invalid feature declarations fail before fitting", {
  x <- feature_training()
  for (bad in list(c("a", "a"), c("", "b"), c(NA_character_, "b"))) {
    colnames(x) <- bad
    expect_error(song(x, epochs = 1L, verbose = FALSE), class = "song_error_features")
  }
  for (field in names(feature_metadata())) {
    manifest <- feature_metadata()
    manifest[[field]][1] <- NA_character_
    expect_error(feature_model(feature_manifest = manifest), class = "song_error_features")
  }
  manifest <- feature_metadata()
  manifest$unit <- factor(manifest$unit)
  expect_error(feature_model(feature_manifest = manifest), class = "song_error_features")
  expect_error(feature_model(feature_manifest = manifest[, -1]), class = "song_error_features")
  expect_error(feature_model(feature_manifest = feature_metadata()[1, ]),
    class = "song_error_features"
  )
})

test_that("updates preserve the declared contract and input model", {
  manifest <- feature_metadata()
  model <- feature_model(feature_manifest = manifest)
  before <- serialize(model, NULL)
  x <- feature_training()[1:4, ]
  expect_error(update(model, x, epochs = 1L, verbose = FALSE), class = "song_error_features")
  updated <- update(model, x, epochs = 1L, verbose = FALSE, feature_manifest = manifest)
  expect_identical(updated$feature_contract, model$feature_contract)
  expect_identical(serialize(model, NULL), before)
  expect_equal(updated$n_input, model$n_input + nrow(x))
  expect_equal(nrow(predict(updated, x, feature_manifest = manifest)), nrow(x))
})

test_that("unnamed and legacy models retain positional compatibility", {
  x <- feature_training()
  positional <- song(unname(x), epochs = 2L, dispersion = FALSE, seed = 7L, verbose = FALSE)
  named <- feature_model()
  expect_identical(positional$C, named$C)
  expect_identical(positional$Y, named$Y)
  expect_identical(predict(positional, x), predict(positional, unname(x)))
  expect_error(predict(positional, x, feature_manifest = feature_metadata()),
    class = "song_error_features"
  )
  legacy <- named
  legacy$feature_contract <- NULL
  expect_identical(predict(legacy, unname(x)), predict(named, x))
  expect_error(predict(legacy, x, feature_manifest = feature_metadata()),
    class = "song_error_features"
  )
})

test_that("unsupported stored schemas and nonfinite measurements fail closed", {
  model <- feature_model()
  model$feature_contract$schema_version <- "999.0"
  expect_error(predict(model, feature_training()), class = "song_error_features")
  model <- feature_model()
  for (bad in c(NA_real_, NaN, Inf, -Inf)) {
    x <- feature_training()
    x[1, 1] <- bad
    expect_error(predict(model, x))
    expect_error(update(model, x, epochs = 1L, verbose = FALSE))
  }
})


test_that("positional projection ignores semantically irrelevant query names", {
  x <- feature_training()
  model <- song(unname(x), epochs = 2L, dispersion = FALSE, seed = 7L, verbose = FALSE)
  reference <- predict(model, unname(x))
  for (labels in list(c("a", "a"), c("", "b"), c(NA_character_, "b"))) {
    colnames(x) <- labels
    expect_identical(predict(model, x), reference)
  }
})
