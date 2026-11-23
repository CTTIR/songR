#' Launch Interactive Comparison App
#'
#' Opens a Shiny application that compares SONG, t-SNE, and UMAP
#' visualisations side-by-side on the built-in example data (iris and
#' \code{\link{songR_blobs}}) or on an uploaded CSV file. The app lets you
#' choose the feature and label columns of an upload, tune the main SONG
#' hyperparameters (\code{k}, \code{spread_factor}, \code{epochs},
#' \code{epsilon} and the dispersion step) together with the t-SNE perplexity
#' and the UMAP neighbourhood size, and inspect the fitted SONG codebook graph
#' and model summary. It features a dark mode toggle (persisted via
#' localStorage) and uses the viridis plasma colour scale for the comparison
#' plots.
#'
#' The app is a viewer: incremental updates, projection of new points and
#' export of embeddings or models are done in code with
#' \code{\link{update.song_model}}, \code{\link{predict.song_model}} and
#' \code{\link{saveRDS}}.
#'
#' The app needs the suggested packages \pkg{shiny}, \pkg{Rtsne}, \pkg{uwot}
#' and \pkg{viridis}; a missing one is reported with an installation hint.
#'
#' @param launch.browser Logical. Whether to open the app in the browser
#'   (default: \code{TRUE}).
#' @return Invisible \code{NULL}. The function is called for its side effect
#'   of launching the Shiny app.
#' @export
#' @examples
#' if (interactive()) {
#'   run_songR_app()
#' }
#'
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
run_songR_app <- function(launch.browser = TRUE) {
  require_pkg <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cli::cli_abort(c(
        "Package {.pkg {pkg}} is required for the comparison app.",
        "i" = "Install it with {.code install.packages(\"{pkg}\")}."
      ))
    }
  }
  for (pkg in c("shiny", "Rtsne", "uwot", "viridis")) require_pkg(pkg)

  app_dir <- system.file("shiny", "comparison_app", package = "songR")
  if (app_dir == "") {
    cli::cli_abort("Could not find the Shiny app directory. Try re-installing {.pkg songR}.")
  }
  shiny::runApp(app_dir, launch.browser = launch.browser,
                display.mode = "normal")
  invisible(NULL)
}
