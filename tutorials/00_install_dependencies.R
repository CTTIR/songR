# ============================================================
# songR Tutorial Dependencies
# ============================================================
# Run this script once to install all packages needed for the
# tutorial suite.
# ============================================================

pkgs <- c(
  "Rtsne",           # t-SNE baseline

"uwot",            # UMAP baseline
  "aricode",         # AMI computation
  "ggplot2",         # plotting
  "patchwork",       # multi-panel ggplot layouts
  "viridis",         # continuous color scales
  "RColorBrewer",    # discrete palettes
  "irlba"            # fast PCA
)

for (pkg in pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installing: ", pkg)
    install.packages(pkg)
  } else {
    message("OK: ", pkg, " (", packageVersion(pkg), ")")
  }
}

# Verify songR is available
if (!requireNamespace("songR", quietly = TRUE)) {
  message("\nsongR not found. Install from local source:")
  message('  devtools::install(".")')
} else {
  message("\nsongR version: ", packageVersion("songR"))
}

message("\nAll dependencies checked.")
