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
#'   Factor, character and logical vectors are treated as categories. Up to
#'   eight categories are drawn in the Okabe-Ito palette, which stays
#'   distinguishable under the common forms of color vision deficiency; more
#'   categories use evenly spaced hues. Numeric vectors are treated as
#'   continuous and mapped linearly onto the sequential viridis palette (low
#'   values dark purple, high values yellow). Missing or nonfinite values are
#'   drawn in gray.
#'   After an update, observation labels must follow the update batch, not all
#'   historical inputs. Codebook and graph plots also accept current-batch
#'   labels and map them to each prototype: the modal value of categories and
#'   the mean of numeric values. Missing-only or empty assignments yield a
#'   missing label.
#' @param ... Additional arguments passed to \code{\link[graphics]{plot}}, for
#'   example \code{main}, \code{xlab}, \code{pch} or \code{cex}. They override
#'   the defaults of this method. Point colors are set through \code{color_by};
#'   \code{col} cannot be forwarded because it partially matches that argument.
#' @param legend Logical. If \code{TRUE} (default), a legend is drawn at the
#'   plot corner or edge where it covers the fewest points, in one or two
#'   columns: the levels of a categorical \code{color_by} with at most 12
#'   levels, or a key of five evenly spaced values for a numeric
#'   \code{color_by}.
#' @return Invisible \code{NULL}.
#' @details
#' Models with more than two output dimensions are drawn in their first two
#' embedding dimensions.
#'
#' The graph edges and the eighth category color take the foreground color of
#' the graphics device (\code{par("fg")}), so that they remain visible when the
#' plot is drawn on a dark background.
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

  # The foreground color of the device: the graph edges and the eighth category
  # color follow it, so that both stay visible on a dark background.
  ink <- graphics::par("fg")
  colors <- .song_point_colors(color_by, ink = ink)

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
      # Edge opacity follows the edge weight. At full weight an edge is 60 %
      # foreground color, which is "gray40" on a white background.
      ink_rgb <- grDevices::col2rgb(ink)[, 1L] / 255
      edge_col <- grDevices::rgb(
        ink_rgb[1L], ink_rgb[2L], ink_rgb[3L], alpha = 0.6 * pmin(w, 1)
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

# Qualitative colors for `n` categories. Up to eight categories use the
# Okabe-Ito palette that ships with R (grDevices::palette.colors()), which stays
# distinguishable under the common forms of color vision deficiency. Its yellow
# and black come last: yellow is faint on a white background, and black is
# replaced by `ink`, the foreground color of the plot, so that the eighth
# category stays visible on a dark background. More than eight categories fall
# back to evenly spaced hues.
.song_qualitative_palette <- function(n, ink = "black") {
  if (n < 1L) {
    return(character(0))
  }
  if (n > 8L) {
    return(grDevices::hcl.colors(n, palette = "Set 2"))
  }
  # Positions in the palette: 1 black, 2 orange, 3 sky blue, 4 bluish green,
  # 5 yellow, 6 blue, 7 vermillion, 8 reddish purple.
  okabe_ito <- unname(grDevices::palette.colors(8L, palette = "Okabe-Ito"))
  palette <- okabe_ito[c(2L, 3L, 4L, 6L, 7L, 8L, 5L, 1L)]
  palette[8L] <- ink
  palette[seq_len(n)]
}

# Translate a `color_by` vector into point colors for base graphics.
# Categories use a qualitative palette; numeric values use a sequential one.
.song_point_colors <- function(color_by, missing = "grey70", ink = "black") {
  if (is.null(color_by)) {
    return(list(col = "steelblue", levels = NULL, palette = NULL, missing = NULL))
  }
  if (is.numeric(color_by) && !is.factor(color_by)) {
    ramp <- grDevices::hcl.colors(100L, palette = "viridis")
    col <- rep(missing, length(color_by))
    finite <- is.finite(color_by)
    key_value <- NULL
    key_col <- NULL
    if (any(finite)) {
      value <- as.double(color_by[finite])
      span <- range(value)
      if (span[2L] > span[1L]) {
        position <- function(v) 1L + floor((v - span[1L]) / (span[2L] - span[1L]) * 99)
        col[finite] <- ramp[position(value)]
        # Five evenly spaced values, largest first, form the color key.
        key_value <- seq(span[2L], span[1L], length.out = 5L)
        key_col <- ramp[position(key_value)]
      } else {
        col[finite] <- ramp[50L]
        key_value <- span[1L]
        key_col <- ramp[50L]
      }
    }
    return(list(
      col = col,
      levels = if (!is.null(key_value)) {
        format(signif(key_value, 3L), trim = TRUE, drop0trailing = TRUE)
      },
      palette = key_col,
      missing = if (!all(finite)) missing else NULL
    ))
  }
  color_by <- as.factor(color_by)
  palette <- .song_qualitative_palette(nlevels(color_by), ink = ink)
  col <- palette[as.integer(color_by)]
  has_missing <- anyNA(col)
  col[is.na(col)] <- missing
  list(col = col, levels = levels(color_by), palette = palette,
       missing = if (has_missing) missing else NULL)
}

# Draw the category legend or numeric key where it hides the fewest points.
# Returns the chosen position invisibly, or NULL when no legend is drawn.
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
  # Candidate placements: the corners first, then the middle of each edge, in
  # one column and, for longer legends, in two. A long legend does not fit into
  # a corner of a small plot without covering points.
  positions <- c("topright", "topleft", "bottomright", "bottomleft",
                 "right", "left", "bottom", "top")
  candidates <- expand.grid(
    position = positions, ncol = if (length(labels) > 3L) 1:2 else 1L,
    stringsAsFactors = FALSE
  )
  # Points inside the legend box, and inside the box plus a clearance of 15%
  # on each side.
  hidden <- vapply(seq_len(nrow(candidates)), function(i) {
    box <- graphics::legend(
      candidates$position[i], legend = labels, pch = 16, cex = 0.8,
      ncol = candidates$ncol[i], plot = FALSE
    )$rect
    inside <- function(pad) {
      pad_x <- pad * box$w
      pad_y <- pad * box$h
      sum(coords[, 1] >= box$left - pad_x & coords[, 1] <= box$left + box$w + pad_x &
            coords[, 2] <= box$top + pad_y & coords[, 2] >= box$top - box$h - pad_y,
          na.rm = TRUE)
    }
    c(inside(0), inside(0.15))
  }, numeric(2))
  # Fewest covered points first, then the widest clearance, then the order above.
  best <- order(hidden[1L, ], hidden[2L, ])[1L]
  graphics::legend(
    candidates$position[best], legend = labels, col = fills, pch = 16,
    cex = 0.8, bty = "n", ncol = candidates$ncol[best],
    text.col = graphics::par("fg")
  )
  invisible(candidates$position[best])
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
#'   \code{\link{plot.song_model}} for the accepted lengths. As in
#'   \code{plot()}, up to eight categories are drawn in the Okabe-Ito palette
#'   and numeric vectors on the viridis scale; more than eight categories use
#'   the default discrete \code{ggplot2} scale. Adding a color scale to the
#'   returned plot replaces the scale chosen here.
#' @param ... Ignored.
#' @return A \code{ggplot} object.
#' @details
#' The method is registered for \code{ggplot2::autoplot()} when \pkg{ggplot2}
#' is available, so \code{ggplot2::autoplot(model)} dispatches to it once
#' \pkg{songR} is loaded. Models with more than two output dimensions are drawn
#' in their first two embedding dimensions.
#' @export
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42,
#'               verbose = FALSE)
#' ggplot2::autoplot(model, color_by = iris$Species)
#' autoplot.song_model(model, type = "graph", color_by = iris$Species)
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
  numeric_color <- is.numeric(color_by) && !is.factor(color_by)
  if (!is.null(color_by)) {
    # Categories become a factor so that a level keeps its color when it has
    # no points, as in plot().
    df$color <- if (numeric_color) color_by else as.factor(color_by)
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
    # The same colors as plot(): viridis for numeric values, Okabe-Ito for up
    # to eight categories, gray for missing values.
    if (numeric_color) {
      p <- p + ggplot2::scale_color_viridis_c(na.value = "grey70")
    } else if (nlevels(df$color) <= 8L) {
      p <- p + ggplot2::scale_color_manual(
        values = .song_qualitative_palette(nlevels(df$color)),
        na.value = "grey70", drop = FALSE
      )
    }
  } else {
    p <- p + ggplot2::geom_point(color = "steelblue", size = 1)
  }

  p <- p +
    ggplot2::labs(x = "SONG 1", y = "SONG 2", title = title) +
    ggplot2::theme_minimal()

  p
}
