#' Plot a SONG Model
#'
#' Visualize a \code{"song_model"} as a scatter plot of the embedding,
#' the codebook, or the codebook graph with edges.
#'
#' @param x A \code{"song_model"} object.
#' @param type Character. One of \code{"embedding"} (all input points in
#'   embedding space), \code{"codebook"} (coding vectors only), or
#'   \code{"graph"} (coding vectors with edges drawn). Default: \code{"embedding"}.
#' @param color_by Optional vector (factor or numeric) of length equal to
#'   the number of input points (for \code{"embedding"}) or coding vectors
#'   (for \code{"codebook"} and \code{"graph"}) used to color the points.
#' @param ... Additional arguments passed to \code{\link[graphics]{plot}}.
#' @return Invisible \code{NULL}.
#' @export
#' @examples
#' model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42)
#' plot(model, color_by = iris$Species)
#'
#' @references
#' Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#' Self-Organizing Nebulous Growths for Robust and Incremental Data
#' Visualization. \emph{IEEE Transactions on Neural Networks and Learning
#' Systems}, 32(10), 4588--4602. \doi{10.1109/TNNLS.2020.3023941}
#'
#' @seealso \code{\link{song}}, \code{\link{autoplot.song_model}}
plot.song_model <- function(x, type = c("embedding", "codebook", "graph"),
                            color_by = NULL, ...) {
  type <- match.arg(type)

  if (type == "embedding") {
    coords <- x$embedding
    main <- "SONG Embedding"
    if (!is.null(color_by) && length(color_by) != nrow(coords)) {
      stop("color_by must have length equal to number of input points (",
           nrow(coords), ").", call. = FALSE)
    }
  } else {
    coords <- x$Y
    main <- if (type == "codebook") "SONG Codebook" else "SONG Codebook Graph"
    if (!is.null(color_by) && length(color_by) != nrow(coords)) {
      # For codebook/graph, also accept input-length color_by and map via assignments
      if (length(color_by) == x$n_input) {
        # Map to coding vectors: use the mode of assignments
        uq <- sort(unique(x$assignments))
        mapped <- vapply(seq_len(nrow(coords)), function(i) {
          pts <- which(x$assignments == i)
          if (length(pts) == 0) return(NA)
          tbl <- table(color_by[pts])
          names(tbl)[which.max(tbl)]
        }, character(1))
        color_by <- as.factor(mapped)
      } else {
        stop("color_by must have length equal to number of ",
             if (type == "codebook") "coding vectors" else "coding vectors",
             " (", nrow(coords), ") or input points (", x$n_input, ").",
             call. = FALSE)
      }
    }
  }

  # Determine colors
  if (is.null(color_by)) {
    col <- "steelblue"
  } else if (is.factor(color_by) || is.character(color_by)) {
    color_by <- as.factor(color_by)
    palette <- grDevices::hcl.colors(nlevels(color_by), palette = "Set 2")
    col <- palette[as.integer(color_by)]
  } else {
    col <- color_by
  }

  d <- ncol(coords)
  if (d < 2) {
    stop("Cannot plot with output dimensionality < 2.", call. = FALSE)
  }

  # 2D plot
  graphics::plot(
    coords[, 1], coords[, 2],
    col = col, pch = 16, cex = 0.6,
    xlab = "SONG 1", ylab = "SONG 2",
    main = main,
    ...
  )

  # Draw edges for graph type

  if (type == "graph") {
    E_s <- x$E_s
    for (i in seq_len(nrow(E_s) - 1)) {
      for (j in (i + 1):ncol(E_s)) {
        if (E_s[i, j] > 0) {
          graphics::segments(
            coords[i, 1], coords[i, 2],
            coords[j, 1], coords[j, 2],
            col = grDevices::adjustcolor("gray40", alpha.f = E_s[i, j]),
            lwd = E_s[i, j] * 2
          )
        }
      }
    }
    # Redraw points on top
    graphics::points(coords[, 1], coords[, 2], col = col, pch = 16, cex = 0.8)
  }

  invisible(NULL)
}

#' Autoplot Method for SONG Models
#'
#' Creates a \code{ggplot2} plot of a \code{"song_model"} object. Requires
#' \code{ggplot2} to be installed.
#'
#' @param object A \code{"song_model"} object.
#' @param type Character. One of \code{"embedding"}, \code{"codebook"}, or
#'   \code{"graph"}.
#' @param color_by Optional vector for coloring points.
#' @param ... Ignored.
#' @return A \code{ggplot} object.
#' @export
#' @examples
#' \donttest{
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42)
#'   # Use songR::autoplot.song_model(model, color_by = iris$Species)
#'   # or ensure songR is loaded with library(songR) for dispatch
#' }
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
    stop("Package 'ggplot2' is required for autoplot. ",
         "Install it with install.packages('ggplot2').", call. = FALSE)
  }

  type <- match.arg(type)

  if (type == "embedding") {
    coords <- object$embedding
    title <- "SONG Embedding"
  } else {
    coords <- object$Y
    title <- if (type == "codebook") "SONG Codebook" else "SONG Codebook Graph"
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
    edges <- list()
    idx <- 1
    for (i in seq_len(nrow(E_s) - 1)) {
      for (j in (i + 1):ncol(E_s)) {
        if (E_s[i, j] > 0) {
          edges[[idx]] <- data.frame(
            x = coords[i, 1], y = coords[i, 2],
            xend = coords[j, 1], yend = coords[j, 2],
            weight = E_s[i, j]
          )
          idx <- idx + 1
        }
      }
    }
    if (length(edges) > 0) {
      edge_df <- do.call(rbind, edges)
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
