# Feature contracts describe input semantics; they never transform measurements.
.song_feature_error <- function(message) {
  cli::cli_abort(message, class = "song_error_features")
}

.song_feature_names <- function(X) {
  features <- colnames(X)
  if (!is.null(features) && (anyNA(features) || any(!nzchar(trimws(features))) ||
                               anyDuplicated(features))) {
    .song_feature_error("Feature names must be unique, nonempty and nonmissing.")
  }
  features
}

.song_manifest <- function(manifest, features) {
  fields <- c("feature", "compartment", "statistic", "unit", "transform", "normalization")
  if (!is.data.frame(manifest) || !identical(names(manifest), fields) ||
        is.null(features) || nrow(manifest) != length(features)) {
    .song_feature_error(paste(
      "Supply a manifest with the documented columns",
      "and one row per named feature."
    ))
  }
  valid <- vapply(manifest, function(x) {
    is.character(x) && !anyNA(x) && all(nzchar(trimws(x)))
  }, logical(1))
  if (!all(valid) || !identical(manifest$feature, features)) {
    .song_feature_error("Manifest values must be nonempty strings in exact feature order.")
  }
  out <- as.data.frame(manifest, stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

.song_feature_contract <- function(X, manifest = NULL) {
  features <- .song_feature_names(X)
  if (!is.null(manifest)) manifest <- .song_manifest(manifest, features)
  list(
    schema_version = "1.0.0", n_features = ncol(X),
    mode = if (!is.null(manifest)) "declared" else if (is.null(features)) "positional" else "named",
    features = features, manifest = manifest, missing_policy = "error"
  )
}

.song_check_features <- function(object, X, manifest = NULL) {
  contract <- object$feature_contract
  if (is.null(contract)) {
    if (!is.null(manifest)) {
      .song_feature_error("This legacy model has no declared feature metadata to verify.")
    }
    return(invisible(NULL))
  }
  fields <- c("schema_version", "n_features", "mode", "features", "manifest", "missing_policy")
  if (!is.list(contract) || !identical(names(contract), fields) ||
        !identical(contract$schema_version, "1.0.0") ||
        !identical(contract$missing_policy, "error") ||
        !identical(contract$n_features, object$D) ||
        !is.character(contract$mode) || length(contract$mode) != 1L ||
        !contract$mode %in% c("positional", "named", "declared")) {
    .song_feature_error("The stored feature contract is malformed or unsupported.")
  }
  if (contract$mode == "positional") {
    if (!is.null(contract$features) || !is.null(contract$manifest) || !is.null(manifest)) {
      .song_feature_error("A positional model cannot verify declared feature metadata.")
    }
    return(invisible(NULL))
  }
  observed <- .song_feature_contract(X, manifest)
  if (!identical(observed, contract)) {
    .song_feature_error("Input feature order or declared metadata differs from training.")
  }
  invisible(NULL)
}
