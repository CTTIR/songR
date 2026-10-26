# Refresh site branding and browser icons without rebuilding examples.
sync_site_branding <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  script <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(script) != 1L) stop("Run this file with Rscript.")
  branding <- dirname(normalizePath(script, winslash = "/", mustWork = TRUE))
  repository <- normalizePath(file.path(branding, "..", ".."),
                              winslash = "/", mustWork = TRUE)
  params <- commandArgs(trailingOnly = TRUE)
  if (length(params) != 1L || is.na(params) || !nzchar(params) ||
      !dir.exists(params)) {
    stop("Supply an existing site output directory.")
  }
  output <- normalizePath(params, winslash = "/", mustWork = TRUE)
  figures <- file.path(repository, "man", "figures")
  favicons <- file.path(repository, "pkgdown", "favicon")
  logos <- list.files(figures, "^logo.*[.](svg|png|pdf)$", full.names = TRUE)
  icons <- list.files(favicons, "[.](svg|png|ico|webmanifest)$", full.names = TRUE)
  if (!file.exists(file.path(figures, "logo.svg")) || !length(icons)) {
    stop("The source logo or favicon bundle is missing.")
  }
  roots <- c(output, if (dir.exists(file.path(output, "dev"))) file.path(output, "dev"))
  required <- c("favicon.svg", "favicon-96x96.png", "favicon.ico",
                "apple-touch-icon.png", "site.webmanifest")
  if (!all(file.exists(file.path(favicons, required)))) {
    stop("The source favicon bundle is incomplete.")
  }

  # Inspect directories before descending so a link cannot escape this tree.
  pending <- output
  html <- character()
  while (length(pending)) {
    current <- pending[[1L]]
    pending <- pending[-1L]
    entries <- list.files(current, all.files = TRUE, no.. = TRUE,
                          full.names = TRUE)
    entries <- entries[basename(entries) != ".git"]
    links <- Sys.readlink(entries)
    if (any(!is.na(links) & nzchar(links))) {
      stop("A site entry must not be a symbolic link.")
    }
    directories <- file.info(entries)$isdir
    if (anyNA(directories)) stop("A site entry could not be inspected.")
    pending <- c(pending, entries[directories])
    html <- c(html, entries[!directories & grepl("[.]html?$", entries,
                                               ignore.case = TRUE)])
  }

  revision <- substr(unname(tools::md5sum(file.path(favicons, "favicon.svg"))),
                     1L, 12L)
  # Treat comments and raw-text elements as indivisible tokens. Apparent tags
  # inside scripts, styles or quoted attributes must never become edit targets.
  html_tokens <- function(text) {
    attributes <- "(?:[^>\"']|\"[^\"]*\"|'[^']*')*"
    pattern <- paste0("(?is)<!--.*?(?:-->|\\z)|",
      "<!\\[CDATA\\[.*?(?:\\]\\]>|\\z)|",
      "<(script|style|title|textarea|xmp|iframe|noembed|noframes)\\b",
      attributes, ">.*?(?:</\\1\\s*>|\\z)|",
      "<[/!?]?[[:alpha:]]", attributes, ">")
    matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
    if (matches[[1L]] < 0L) {
      return(list(start = integer(), end = integer(), text = character()))
    }
    ends <- matches + attr(matches, "match.length") - 1L
    list(start = as.integer(matches), end = as.integer(ends),
         text = substring(text, matches, ends))
  }
  icon_link <- function(tag) {
    name <- regexpr("(?i)^<link\\b", tag, perl = TRUE)
    if (name[[1L]] < 0L) return(FALSE)
    rest <- substring(tag, attr(name, "match.length") + 1L)
    attribute <- paste0("^[[:space:]]*([^[:space:]=\"'<>/]+)",
      "(?:[[:space:]]*=[[:space:]]*(\"[^\"]*\"|'[^']*'|[^[:space:]>]+))?")
    while (nzchar(rest)) {
      match <- regexec(attribute, rest, perl = TRUE)
      parts <- regmatches(rest, match)[[1L]]
      if (!length(parts)) break
      if (identical(tolower(parts[[2L]]), "rel")) {
        value <- parts[[3L]]
        if (substr(value, 1L, 1L) %in% c("\"", "'")) {
          value <- substr(value, 2L, nchar(value) - 1L)
        }
        values <- strsplit(tolower(value), "[[:space:]]+")[[1L]]
        return(any(values %in% c("icon", "apple-touch-icon", "manifest")))
      }
      rest <- substring(rest, nchar(parts[[1L]]) + 1L)
    }
    FALSE
  }
  remove_ranges <- function(text, starts, ends) {
    if (!length(starts)) return(text)
    order <- order(starts, -ends)
    pieces <- character()
    cursor <- 1L
    for (i in order) {
      if (starts[[i]] > cursor) {
        pieces <- c(pieces, substr(text, cursor, starts[[i]] - 1L))
      }
      cursor <- max(cursor, ends[[i]] + 1L)
    }
    paste0(c(pieces, substring(text, cursor)), collapse = "")
  }
  updates <- list()
  for (page in html) {
    bytes <- readBin(page, "raw", n = file.info(page)$size)
    text <- rawToChar(bytes)
    document <- html_tokens(text)
    opening <- which(grepl("(?i)^<head(?:[[:space:]]|>)", document$text,
                            perl = TRUE))[1L]
    if (is.na(opening)) next
    closing <- which(seq_along(document$text) > opening &
      grepl("(?i)^</head[[:space:]]*>$", document$text, perl = TRUE))[1L]
    if (is.na(closing)) stop("An HTML page has an unclosed head: ", page)
    start <- document$end[[opening]] + 1L
    finish <- document$start[[closing]]
    head <- substr(text, start, finish - 1L)
    tags <- html_tokens(head)
    is_icon <- vapply(tags$text, icon_link, logical(1))
    starts <- tags$start[is_icon]
    ends <- tags$end[is_icon]
    # Remove a previous generated block only when its real comment markers
    # enclose icon links and whitespace, never script strings or other content.
    for (i in which(tags$text == "<!-- Package browser icons -->")) {
      j <- which(seq_along(tags$text) > i &
        tags$text == "<!-- /Package browser icons -->")[1L]
      if (is.na(j)) next
      inside <- if (j > i + 1L) seq.int(i + 1L, j - 1L) else integer()
      if (!all(is_icon[inside])) next
      middle <- substr(head, tags$end[[i]] + 1L, tags$start[[j]] - 1L)
      middle <- remove_ranges(middle, tags$start[inside] - tags$end[[i]],
                              tags$end[inside] - tags$end[[i]])
      if (grepl("[^[:space:]]", middle)) next
      end <- tags$end[[j]]
      following <- substr(head, end + 1L, end + 2L)
      end <- end + if (startsWith(following, "\r\n")) 2L else if (startsWith(following, "\n")) 1L else 0L
      starts <- c(starts, tags$start[[i]])
      ends <- c(ends, end)
    }
    head <- remove_ranges(head, starts, ends)
    root <- if (startsWith(page, paste0(output, "/dev/"))) {
      file.path(output, "dev")
    } else output
    parent <- dirname(page)
    relative <- if (identical(parent, root)) "" else substring(parent, nchar(root) + 2L)
    depth <- if (nzchar(relative)) length(strsplit(relative, "/", fixed = TRUE)[[1L]]) else 0L
    prefix <- paste(rep("../", depth), collapse = "")
    href <- function(name) paste0(prefix, name, "?v=", revision)
    newline <- if (grepl("\r\n", text, fixed = TRUE)) "\r\n" else "\n"
    block <- c("<!-- Package browser icons -->",
      sprintf('<link rel="icon" type="image/x-icon" href="%s">', href("favicon.ico")),
      sprintf('<link rel="icon" type="image/png" sizes="96x96" href="%s">', href("favicon-96x96.png")),
      sprintf('<link rel="icon" type="image/svg+xml" sizes="any" href="%s">', href("favicon.svg")),
      sprintf('<link rel="apple-touch-icon" sizes="180x180" href="%s">', href("apple-touch-icon.png")),
      sprintf('<link rel="manifest" href="%s">', href("site.webmanifest")),
      "<!-- /Package browser icons -->")
    updated <- paste0(substr(text, 1L, start - 1L), head,
                      paste(block, collapse = newline), newline,
                      substring(text, finish))
    if (!identical(text, updated)) updates[[page]] <- charToRaw(updated)
  }
  sources <- destinations <- character()
  for (root in roots) {
    sources <- c(sources, logos, file.path(figures, "logo.svg"), icons)
    destinations <- c(destinations,
      file.path(root, "reference", "figures", basename(logos)),
      file.path(root, "logo.svg"), file.path(root, basename(icons)))
    # Retain and refresh the older raster alias only where it is already used.
    if (file.exists(file.path(root, "logo.png"))) {
      sources <- c(sources, file.path(figures, "logo.png"))
      destinations <- c(destinations, file.path(root, "logo.png"))
    }
  }
  if (!all(file.exists(sources)) || any(file.info(sources)$isdir)) {
    stop("A branding source file is missing or is a directory.")
  }
  for (target in destinations) {
    link <- Sys.readlink(target)
    if (dir.exists(target) || (!is.na(link) && nzchar(link))) {
      stop("A branding destination must be a regular file: ", target)
    }
    ancestor <- dirname(target)
    while (!dir.exists(ancestor)) ancestor <- dirname(ancestor)
    resolved <- normalizePath(ancestor, winslash = "/", mustWork = TRUE)
    if (!identical(resolved, output) && !startsWith(resolved, paste0(output, "/"))) {
      stop("A branding destination escapes the site directory: ", target)
    }
  }
  for (i in seq_along(sources)) {
    dir.create(dirname(destinations[i]), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(sources[i], destinations[i], overwrite = TRUE)) {
      stop("Could not copy branding asset: ", destinations[i])
    }
  }
  for (page in names(updates)) writeBin(updates[[page]], page)
  message("Synchronized ", length(destinations), " branding assets across ",
          length(roots), " site root(s); refreshed browser icons in ",
          length(updates), " HTML page(s).")
}

sync_site_branding()
