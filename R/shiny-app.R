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
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required. Install it with install.packages('shiny').",
         call. = FALSE)
  }
  if (!requireNamespace("Rtsne", quietly = TRUE)) {
    stop("Package 'Rtsne' is required for the comparison app. ",
         "Install it with install.packages('Rtsne').", call. = FALSE)
  }
  if (!requireNamespace("uwot", quietly = TRUE)) {
    stop("Package 'uwot' is required for the comparison app. ",
         "Install it with install.packages('uwot').", call. = FALSE)
  }
  if (!requireNamespace("viridis", quietly = TRUE)) {
    stop("Package 'viridis' is required for the comparison app. ",
         "Install it with install.packages('viridis').", call. = FALSE)
  }
  app_dir <- system.file("shiny", "comparison_app", package = "songR")
  if (app_dir == "") {
    stop("Could not find the Shiny app directory. Try re-installing 'songR'.",
         call. = FALSE)
  }
  shiny::runApp(app_dir, launch.browser = launch.browser,
                display.mode = "normal")
  invisible(NULL)
}
