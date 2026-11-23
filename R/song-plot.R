#' Plot a SONG Model
#'
#' Visualize a \code{"song_model"} as a scatter plot of the embedding,
#' the codebook, or the codebook graph with edges.
#'
#' @param x A \code{"song_model"} object.
#' @param type Character. One of \code{"embedding"} (current-batch input points in
#'   embedding space), \code{"codebook"} (coding vectors only), or
#'   \code{"graph"} (coding vectors with edges drawn). Default: \code{"embedding"}.
#' @param color_by Optional vector of length equal to
#'   the number of input points (for \code{"embedding"}) or coding vectors
#'   (for \code{"codebook"} and \code{"graph"}) used to color the points.
#'   Factor, character and logical vectors are treated as categories and drawn
#'   with a qualitative palette. Numeric vectors are treated as continuous and
#'   mapped linearly onto the sequential viridis palette (low values dark
#'   purple, high values yellow). Missing or nonfinite values are drawn in grey.
#'   After an update, observation labels must follow the update batch, not all
#'   historical inputs. Codebook and graph plots also accept current-batch
#'   labels and map their modal value to each prototype; missing-only or empty
#'   assignments yield a missing label.
#' @param ... Additional arguments passed to \code{\link[graphics]{plot}}, for
#'   example \code{main}, \code{xlab}, \code{pch} or \code{cex}. They override
#'   the defaults of this method. Point colors are set through \code{color_by};
#'   \code{col} cannot be forwarded because it partially matches that argument.
#' @param legend Logical. If \code{TRUE} (default), a legend is drawn for a
#'   categorical \code{color_by} with at most 12 levels, in the plot corner
#'   that covers the fewest points.
#' @return Invisible \code{NULL}.
#' @details
#' Models with more than two output dimensions are drawn in their first two
#' embedding dimensions.
#' @export
#' @examples
#' model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42)
#' plot(model, color_by = iris$Species)
#'
#' # Continuous coloring and the codebook graph
#' plot(model, color_by = iris$Sepal.Length, main = "Sepal length")
#' plot(model, type = "graph", color_by = iris$Species)
#'
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
#'
#' @seealso \code{\link{song}}, \code{\link{autoplot.song_model}}
plot.song_model <- function(x, type = c("embedding", "codebook", "graph"),
                            color_by = NULL, ..., legend = TRUE) {
  type <- match.arg(type)
  .song_check_flag(legend, "legend")

  if (type == "embedding") {
    coords <- x$embedding
    main <- "SONG Embedding"
  } else {
    coords <- x$Y
    main <- if (type == "codebook") "SONG Codebook" else "SONG Codebook Graph"
  }
  color_by <- resolve_color_by(x, type, nrow(coords), color_by)

  d <- ncol(coords)
  if (d < 2) {
    cli::cli_abort("Cannot plot with output dimensionality < 2.")
  }

  colors <- .song_point_colors(color_by)

  # Arguments supplied through `...` take precedence over the method defaults.
  dots <- list(...)
  defaults <- list(
    pch = 16, cex = 0.6, xlab = "SONG 1", ylab = "SONG 2", main = main
  )
  args <- c(dots, defaults[setdiff(names(defaults), names(dots))])
  # Symbols keep the call small: plot.default() deparses its x and y arguments.
  px <- coords[, 1]
  py <- coords[, 2]
  do.call(
    graphics::plot,
    c(list(x = quote(px), y = quote(py), col = colors$col), args)
  )

  # Draw edges for graph type

  if (type == "graph") {
    E_s <- x$E_s
    edges <- which(upper.tri(E_s) & E_s > 0, arr.ind = TRUE)
    if (nrow(edges) > 0L) {
      w <- E_s[edges]
      edge_col <- vapply(
        pmin(w, 1),
        function(a) grDevices::adjustcolor("gray40", alpha.f = a),
        character(1)
      )
      graphics::segments(
        coords[edges[, 1], 1], coords[edges[, 1], 2],
        coords[edges[, 2], 1], coords[edges[, 2], 2],
        col = edge_col,
        lwd = w * 2
      )
    }
    # Redraw points on top
    graphics::points(
      coords[, 1], coords[, 2], col = colors$col, pch = args$pch,
      cex = if ("cex" %in% names(dots)) dots$cex else 0.8
    )
  }

  if (legend) {
    .song_plot_legend(coords, colors)
  }

  invisible(NULL)
}

# Translate a `color_by` vector into point colors for base graphics.
# Categories use a qualitative palette; numeric values use a sequential one.
.song_point_colors <- function(color_by, missing = "grey70") {
  if (is.null(color_by)) {
    return(list(col = "steelblue", levels = NULL, palette = NULL, missing = NULL))
  }
  if (is.numeric(color_by) && !is.factor(color_by)) {
    ramp <- grDevices::hcl.colors(100L, palette = "viridis")
    col <- rep(missing, length(color_by))
    finite <- is.finite(color_by)
    if (any(finite)) {
      value <- as.double(color_by[finite])
      span <- range(value)
      col[finite] <- if (span[2L] > span[1L]) {
        ramp[1L + floor((value - span[1L]) / (span[2L] - span[1L]) * 99)]
      } else {
        ramp[50L]
      }
    }
    return(list(col = col, levels = NULL, palette = NULL, missing = NULL))
  }
  color_by <- as.factor(color_by)
  palette <- grDevices::hcl.colors(max(nlevels(color_by), 1L), palette = "Set 2")
  palette <- palette[seq_len(nlevels(color_by))]
  col <- palette[as.integer(color_by)]
  has_missing <- anyNA(col)
  col[is.na(col)] <- missing
  list(col = col, levels = levels(color_by), palette = palette,
       missing = if (has_missing) missing else NULL)
}

# Draw the category legend in the corner that hides the fewest points.
# Returns the chosen corner invisibly, or NULL when no legend is drawn.
.song_plot_legend <- function(coords, colors, max_levels = 12L) {
  n_levels <- length(colors$levels)
  if (n_levels < 1L || n_levels > max_levels) {
    return(invisible(NULL))
  }
  labels <- colors$levels
  fills <- colors$palette
  if (!is.null(colors$missing)) {
    labels <- c(labels, "NA")
    fills <- c(fills, colors$missing)
  }
  corners <- c("topright", "topleft", "bottomright", "bottomleft")
  hidden <- vapply(corners, function(corner) {
    box <- graphics::legend(corner, legend = labels, pch = 16, cex = 0.8,
                            plot = FALSE)$rect
    # Count points in the legend box plus a clearance of 15% on each side.
    pad_x <- 0.15 * box$w
    pad_y <- 0.15 * box$h
    sum(coords[, 1] >= box$left - pad_x & coords[, 1] <= box$left + box$w + pad_x &
          coords[, 2] <= box$top + pad_y & coords[, 2] >= box$top - box$h - pad_y,
        na.rm = TRUE)
  }, numeric(1))
  corner <- corners[which.min(hidden)]
  graphics::legend(
    corner, legend = labels, col = fills, pch = 16,
    cex = 0.8, bty = "n", text.col = graphics::par("fg")
  )
  invisible(corner)
}

#' Autoplot Method for SONG Models
#'
#' Creates a \code{ggplot2} plot of a \code{"song_model"} object. Requires
#' \code{ggplot2} to be installed.
#'
#' @param object A \code{"song_model"} object.
#' @param type Character. One of \code{"embedding"}, \code{"codebook"}, or
#'   \code{"graph"}.
#' @param color_by Optional vector for coloring points; see
#'   \code{\link{plot.song_model}} for the accepted lengths. Categorical and
#'   numeric vectors use the discrete and continuous \code{ggplot2} color
#'   scales, which can be replaced by adding a scale to the returned plot.
#' @param ... Ignored.
#' @return A \code{ggplot} object.
#' @details
#' The method is registered for \code{ggplot2::autoplot()} when \pkg{ggplot2}
#' is available, so \code{ggplot2::autoplot(model)} dispatches to it once
#' \pkg{songR} is loaded. Models with more than two output dimensions are drawn
#' in their first two embedding dimensions.
#' @export
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42,
#'                 verbose = FALSE)
#'   ggplot2::autoplot(model, color_by = iris$Species)
#'   autoplot.song_model(model, type = "graph", color_by = iris$Species)
#' }
#'
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
autoplot.song_model <- function(object,
                                type = c("embedding", "codebook", "graph"),
                                color_by = NULL, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package {.pkg ggplot2} is required for {.fn autoplot}.",
      "i" = 'Install it with {.run install.packages("ggplot2")}.'
    ))
  }

  type <- match.arg(type)

  if (type == "embedding") {
    coords <- object$embedding
    title <- "SONG Embedding"
  } else {
    coords <- object$Y
    title <- if (type == "codebook") "SONG Codebook" else "SONG Codebook Graph"
  }

  color_by <- resolve_color_by(object, type, nrow(coords), color_by)
  if (ncol(coords) < 2L) {
    cli::cli_abort("Cannot plot with output dimensionality < 2.")
  }
  df <- data.frame(x = coords[, 1], y = coords[, 2])
  if (!is.null(color_by)) {
    df$color <- color_by
  }

  # Suppress R CMD check notes for ggplot2 NSE
  x <- y <- xend <- yend <- weight <- color <- NULL

  p <- ggplot2::ggplot(df, ggplot2::aes(x = x, y = y))

  if (type == "graph") {
    # Add edges
    E_s <- object$E_s
    edges <- which(upper.tri(E_s) & E_s > 0, arr.ind = TRUE)
    if (nrow(edges) > 0L) {
      edge_df <- data.frame(
        x = coords[edges[, 1], 1], y = coords[edges[, 1], 2],
        xend = coords[edges[, 2], 1], yend = coords[edges[, 2], 2],
        weight = E_s[edges]
      )
      p <- p + ggplot2::geom_segment(
        data = edge_df,
        ggplot2::aes(x = x, y = y, xend = xend, yend = yend,
                     alpha = weight),
        color = "gray40", show.legend = FALSE
      )
    }
  }

  if (!is.null(color_by)) {
    p <- p + ggplot2::geom_point(ggplot2::aes(color = color), size = 1) +
      ggplot2::labs(color = "")
  } else {
    p <- p + ggplot2::geom_point(color = "steelblue", size = 1)
  }

  p <- p +
    ggplot2::labs(x = "SONG 1", y = "SONG 2", title = title) +
    ggplot2::theme_minimal()

  p
}
