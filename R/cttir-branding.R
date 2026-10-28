# Named application artwork and compact browser icon from the CTTIR v5 library.
# Assets are local package files, independent of application data.
.cttir_brand_text <- function(file) {
  path <- system.file("branding", file, package = "songR")
  if (!nzchar(path)) stop("The packaged branding asset is missing: ", file)
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

.cttir_brand_uri <- function(file) {
  paste0("data:image/svg+xml,",
         utils::URLencode(.cttir_brand_text(file), reserved = TRUE))
}

.cttir_brand_head <- function() {
  shiny::singleton(shiny::tags$head(
    shiny::tags$link(rel = "icon", type = "image/svg+xml",
                     href = .cttir_brand_uri("favicon.svg")),
    shiny::tags$style(shiny::HTML(.cttir_brand_text("branding.css")))
  ))
}

.cttir_brand_logo <- function(height = 64, mode = c("auto", "light", "dark")) {
  mode <- match.arg(mode)
  shiny::tagList(
    .cttir_brand_head(),
    shiny::tags$span(
      class = "cttir-app-brand", `data-cttir-mode` = mode,
      style = sprintf("--cttir-brand-height:%spx;--cttir-brand-width:%spx;",
                      height, round(height * 432 / 498, 2)),
      shiny::tags$img(
        src = .cttir_brand_uri("logo.svg"),
        class = "cttir-app-brand-light", alt = "songR logo"
      ),
      shiny::tags$img(
        src = .cttir_brand_uri("logo-dark.svg"),
        class = "cttir-app-brand-dark", alt = "songR logo"
      )
    )
  )
}
