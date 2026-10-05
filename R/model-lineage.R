# Version the frozen projection geometry, not biological or physical distances.
.song_projection_id <- function(object) {
  payload <- list(C = object$C, Y = object$Y, D = object$D,
                  feature_contract = object$feature_contract)
  digest::digest(serialize(payload, NULL, version = 2L),
                 algo = "sha256", serialize = FALSE)
}

.song_lineage_error <- function() {
  cli::cli_abort("The stored model lineage is malformed or unsupported.",
                 class = "song_error_lineage")
}

.song_check_lineage <- function(object) {
  x <- object$lineage
  if (is.null(x)) {
    return(invisible(NULL))
  }
  fields <- c("schema_version", "revision", "model_id", "parent_model_id",
              "parent_history", "projection_policy", "embedding_scope")
  hash <- function(value) {
    is.character(value) && length(value) == 1L && !is.na(value) &&
      grepl("^[a-f0-9]{64}$", value)
  }
  scalar_choice <- function(value, choices) {
    is.character(value) && length(value) == 1L && !is.na(value) && value %in% choices
  }
  if (!is.list(x) || !identical(names(x), fields) ||
        !identical(x$schema_version, "1.0.0") ||
        !is.integer(x$revision) || length(x$revision) != 1L ||
        is.na(x$revision) || x$revision < 1L || x$revision == .Machine$integer.max ||
        !hash(x$model_id) || !(is.null(x$parent_model_id) || hash(x$parent_model_id)) ||
        !scalar_choice(x$parent_history, c("none", "versioned", "legacy_unversioned")) ||
        !scalar_choice(x$projection_policy,
                       c("frozen_nearest_prototype", "reproject_all_with_updated_model")) ||
        !scalar_choice(x$embedding_scope, c("training_batch", "update_batch_only"))) {
    .song_lineage_error()
  }
  initial <- identical(x$parent_history, "none")
  if (initial != is.null(x$parent_model_id) ||
        initial != identical(x$projection_policy, "frozen_nearest_prototype") ||
        initial != identical(x$embedding_scope, "training_batch") ||
        ((initial || x$parent_history == "legacy_unversioned") && x$revision != 1L) ||
        (x$parent_history == "versioned" && x$revision < 2L)) {
    .song_lineage_error()
  }
  invisible(NULL)
}

.song_model_lineage <- function(object, parent = NULL) {
  if (is.null(parent)) {
    revision <- 1L
    parent_id <- NULL
    history <- "none"
  } else {
    .song_check_lineage(parent)
    revision <- if (is.null(parent$lineage)) 1L else parent$lineage$revision + 1L
    parent_id <- if (is.null(parent$lineage)) {
      .song_projection_id(parent)
    } else {
      parent$lineage$model_id
    }
    history <- if (is.null(parent$lineage)) "legacy_unversioned" else "versioned"
  }
  identity <- list(projection = .song_projection_id(object), revision = revision,
                   parent_model_id = parent_id)
  list(
    schema_version = "1.0.0", revision = revision,
    model_id = digest::digest(serialize(identity, NULL, version = 2L),
                              algo = "sha256", serialize = FALSE),
    parent_model_id = parent_id, parent_history = history,
    projection_policy = if (is.null(parent)) "frozen_nearest_prototype" else
      "reproject_all_with_updated_model",
    embedding_scope = if (is.null(parent)) "training_batch" else "update_batch_only"
  )
}
