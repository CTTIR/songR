# songR: Self-Organizing Nebulous Growths for Dimensionality Reduction

A SONG-inspired tool for nonlinear dimensionality reduction and data
visualization in R, implementing the Self-Organizing Nebulous Growths
(SONG) algorithm of Senanayake et al. (2021)
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)
natively in R and C++ and staying as close to the reference
implementation as is feasible across the two ecosystems. SONG is a
parametric method that supports incremental addition of new data to
existing visualizations without reinitialization, handles both
homogeneous and heterogeneous data increments, and is robust to noise
and highly mixed clusters. Clustering quality matches the reference
closely (validated by reference-parity tests); the default visualization
is close in global structure but not identical in absolute layout.
Includes an interactive Shiny application for comparing SONG, t-SNE, and
UMAP visualizations side-by-side.

## References

Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
Self-Organizing Nebulous Growths for Robust and Incremental Data
Visualization. *IEEE Transactions on Neural Networks and Learning
Systems*, 32(10), 4588–4602.
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)

## See also

Useful links:

- <https://cttir.github.io/songR/>

- <https://github.com/cttir/songR>

- Report bugs at <https://github.com/cttir/songR/issues>

## Author

**Maintainer**: R. Heller <raban.heller@uni-ulm.de>
([ORCID](https://orcid.org/0000-0001-8006-9742)) \[copyright holder\]

Authors:

- R. Heller <raban.heller@uni-ulm.de>
  ([ORCID](https://orcid.org/0000-0001-8006-9742)) \[copyright holder\]

Other contributors:

- Damith A. Senanayake (Author of the original SONG algorithm and its
  BSD-3-Clause Python implementation; see inst/COPYRIGHTS) \[copyright
  holder\]
