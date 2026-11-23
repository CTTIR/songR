# The comparison app is interactive; these tests cover its packaged branding
# helpers and drive its server logic without opening a browser.

test_that("branding helpers read the packaged artwork", {
  skip_if_not_installed("shiny")
  svg <- .cttir_brand_text("logo.svg")
  expect_match(svg, "<svg", fixed = TRUE)
  uri <- .cttir_brand_uri("favicon.svg")
  expect_match(uri, "^data:image/svg\\+xml,")
  expect_false(grepl("[<> \"]", uri))
  expect_error(.cttir_brand_text("no-such-asset.svg"), "branding asset is missing")

  logo <- .cttir_brand_logo(height = 50, mode = "dark")
  html <- as.character(logo)
  expect_match(html, "data-cttir-mode=\"dark\"", fixed = TRUE)
  expect_match(html, "--cttir-brand-height:50px", fixed = TRUE)
  expect_match(html, "alt=\"songR logo\"", fixed = TRUE)
  expect_error(.cttir_brand_logo(mode = "sepia"), "should be one of")
})

test_that("the comparison app server fits all three methods on iris", {
  skip_on_cran()
  for (pkg in c("shiny", "Rtsne", "uwot", "viridis")) skip_if_not_installed(pkg)
  app_dir <- system.file("shiny", "comparison_app", package = "songR")
  skip_if(!nzchar(app_dir), "app directory not installed")

  # Rendering must not warn: a reactive used to be passed as the device `bg`.
  warned <- character()
  withCallingHandlers(
    shiny::testServer(app_dir, {
      session$setInputs(
        dataset = "iris", song_k = 3, song_sf = 0.5, song_epochs = 5,
        song_epsilon = 0.9, song_dispersion = FALSE, tsne_perp = 30,
        umap_nn = 15, seed = 42, dark_mode = FALSE
      )
      expect_null(results$song_model)
      session$setInputs(run_btn = 1)

      expect_s3_class(results$song_model, "song_model")
      expect_identical(dim(results$song_model$embedding), c(150L, 2L))
      expect_identical(dim(results$tsne_result), c(150L, 2L))
      expect_identical(dim(results$umap_result), c(150L, 2L))
      expect_identical(results$labels, iris$Species)
      expect_true(is.finite(results$song_time))
      expect_match(paste(utils::capture.output(output$song_summary), collapse = " "),
                   "SONG model summary")
      # Dark mode re-renders every plot with the dark page background.
      session$setInputs(dark_mode = TRUE)
      expect_type(output$song_plot$src, "character")
      expect_type(output$song_graph_plot$src, "character")
    }),
    warning = function(w) {
      warned <<- c(warned, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(warned, character())
})

test_that("the comparison app reports invalid SONG settings without failing", {
  skip_on_cran()
  for (pkg in c("shiny", "Rtsne", "uwot", "viridis")) skip_if_not_installed(pkg)
  app_dir <- system.file("shiny", "comparison_app", package = "songR")
  skip_if(!nzchar(app_dir), "app directory not installed")

  shiny::testServer(app_dir, {
    # k must be at least d + 1 = 3; the app must survive the rejected fit.
    session$setInputs(
      dataset = "iris", song_k = 2, song_sf = 0.5, song_epochs = 5,
      song_epsilon = 0.9, song_dispersion = FALSE, tsne_perp = 30,
      umap_nn = 15, seed = 42, dark_mode = FALSE
    )
    session$setInputs(run_btn = 1)
    expect_null(results$song_model)
    expect_identical(dim(results$umap_result), c(150L, 2L))
  })
})
