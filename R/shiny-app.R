#' Launch Interactive Comparison App
#'
#' Opens a Shiny application that compares SONG, t-SNE, and UMAP
#' visualizations side-by-side on user-supplied or example data.
#' The app features a dark mode toggle (persisted via localStorage),
#' uses the viridis plasma color scale for all plots, and supports
#' uploading custom CSV/RDS data, tuning SONG hyperparameters,
#' running incremental updates, and exporting embeddings.
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
