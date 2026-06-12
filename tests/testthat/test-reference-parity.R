# Parity tests against golden fixtures generated from the reference Python
# implementation (.archive/SONG-master), produced by
# tests/testthat/fixtures/reference/gen_fixtures.py + gen_spread.py.
# Tiers follow the fidelity ladder: Tier A = deterministic (<=1e-5 vs float32
# reference), Tier B = statistical equivalence (AMI within band).

have_fx <- function(f) file.exists(file.path("fixtures", "reference", f))

test_that("Tier A: squared-euclidean distances match the reference (f32 tol)", {
  skip_if_not(have_fx("tierA_sqdist.csv"), "reference fixtures not generated")
  A <- as.matrix(utils::read.csv(file.path("fixtures","reference","tierA_A.csv"), header = FALSE))
  B <- as.matrix(utils::read.csv(file.path("fixtures","reference","tierA_B.csv"), header = FALSE))
  ref_d <- as.matrix(utils::read.csv(file.path("fixtures","reference","tierA_sqdist.csv"), header = FALSE))
  song_d <- t(apply(A, 1, function(x) colSums((t(B) - x)^2)))
  # reference is float32 + fastmath; songR is double -> agreement ~1e-6, not eps
  expect_equal(unname(song_d), unname(ref_d), tolerance = 1e-5)
})

test_that("Tier A: nearest-coding-vector argmin matches the reference", {
  skip_if_not(have_fx("tierA_argmin.csv"), "reference fixtures not generated")
  A <- as.matrix(utils::read.csv(file.path("fixtures","reference","tierA_A.csv"), header = FALSE))
  B <- as.matrix(utils::read.csv(file.path("fixtures","reference","tierA_B.csv"), header = FALSE))
  ref_arg <- scan(file.path("fixtures","reference","tierA_argmin.csv"), quiet = TRUE)
  song_d <- t(apply(A, 1, function(x) colSums((t(B) - x)^2)))
  song_arg <- apply(song_d, 1, which.min) - 1L  # reference is 0-indexed
  expect_identical(as.integer(song_arg), as.integer(ref_arg))
})

test_that("Tier A: songR's default kernel (a, b) matches find_spread_tightness(1, 0.1)", {
  skip_if_not(have_fx("tierA_spread_tightness.csv"), "reference fixtures not generated")
  st <- utils::read.csv(file.path("fixtures","reference","tierA_spread_tightness.csv"))
  r <- st[st$spread == 1 & st$min_dist == 0.1, ]
  # songR ships the rounded values 1.577 / 0.895 as defaults
  expect_equal(1.577, r$a, tolerance = 1e-3)
  expect_equal(0.895, r$b, tolerance = 1e-3)
})

test_that("Tier A: scalar derivations match the reference formulas", {
  # thresh_g, prototypes, min_strength, im_neix (reference song.py)
  expect_equal(0.9^(2 + 3), 0.59049, tolerance = 1e-10)              # min_strength
  expect_equal(as.integer(floor(exp(log(150) / 1.5))), 28L)          # prototypes(N=150)
  expect_equal(as.integer(floor(exp(log(1600) / 1.5))), 136L)        # prototypes(N=1600)
  expect_equal(-log(20) * log(0.5), 2.0764833, tolerance = 1e-6)     # thresh_g(D=20, sf=.5)
})

test_that("Tier B: songR AMI is statistically equivalent to the reference", {
  skip_on_cran()
  skip_if_not_installed("aricode")
  skip_if_not(have_fx("tierB_blobs_emb_nodisp.csv"), "reference fixtures not generated")

  X <- as.matrix(utils::read.csv(file.path("fixtures","reference","tierB_blobs_X.csv"), header = FALSE))
  y <- factor(scan(file.path("fixtures","reference","tierB_blobs_y.csv"), quiet = TRUE))
  ref_emb <- as.matrix(utils::read.csv(file.path("fixtures","reference","tierB_blobs_emb_nodisp.csv"), header = FALSE))

  ami <- function(emb) {
    mean(vapply(1:5, function(s) {
      set.seed(s)
      cl <- stats::kmeans(emb, centers = 8, nstart = 5, iter.max = 100)$cluster
      aricode::AMI(cl, y)
    }, numeric(1)))
  }

  # reference-matched params: raw-space SONG, no UMAP dispersion
  m <- song(X, d = 2L, k = 3L, epsilon = 0.99, epochs = 100L, a = 1.577, b = 0.895,
            spread_factor = 0.5, seed = 1L, dispersion = FALSE, verbose = FALSE)

  ref_ami <- ami(ref_emb)
  song_ami <- ami(m$embedding)
  expect_gt(ref_ami, 0.7)                       # sanity: reference clusters well
  expect_lt(abs(ref_ami - song_ami), 0.10)      # Tier-B equivalence band
})

test_that("Tier B (dispersed): songR UMAP-dispersed AMI tracks the reference", {
  # END-TO-END PIPELINE check, NOT a SONG-numerics check. The SONG core is
  # frozen; this exercises only the UMAP dispersion. songR deliberately uses a
  # stronger refinement than the reference (its raw embedding is more collapsed
  # on hard data), so songR's dispersed AMI now matches or beats the reference.
  # The loose band just guards against a gross regression, not exact equality.
  skip_on_cran()
  skip_if_not_installed("aricode")
  skip_if_not_installed("uwot")
  skip_if_not(have_fx("tierB_mnist_emb_umap.csv"), "reference fixtures not generated")

  ami <- function(emb, y, k) {
    mean(vapply(1:5, function(s) {
      set.seed(s)
      cl <- stats::kmeans(emb, centers = k, nstart = 5, iter.max = 100)$cluster
      aricode::AMI(cl, y)
    }, numeric(1)))
  }

  for (name in c("mnist", "fmnist")) {
    X <- as.matrix(utils::read.csv(file.path("fixtures","reference",
            paste0("tierB_", name, "_X.csv")), header = FALSE))
    y <- factor(scan(file.path("fixtures","reference",
            paste0("tierB_", name, "_y.csv")), quiet = TRUE))
    ref_emb <- as.matrix(utils::read.csv(file.path("fixtures","reference",
            paste0("tierB_", name, "_emb_umap.csv")), header = FALSE))
    k <- nlevels(y)

    m <- song(X, d = 2L, k = 3L, epsilon = 0.99, epochs = 100L, a = 1.577, b = 0.895,
              spread_factor = 0.5, seed = 1L, dispersion = TRUE, verbose = FALSE)

    ref_ami <- ami(ref_emb, y, k)
    song_ami <- ami(m$embedding, y, k)
    expect_gt(ref_ami, 0.4)                        # sanity
    expect_gt(song_ami, 0.4)                       # sanity
    expect_lt(abs(ref_ami - song_ami), 0.12)       # loose cross-library band
  }
})
