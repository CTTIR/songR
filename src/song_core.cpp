// song_core.cpp — Faithful port of Python SONG (Senanayake et al., 2021)
//
// Reference: .archive/SONG-master/SONG-master/song/{song.py, util.py}
//
// Key functions ported:
//   song.py  → fit()                     → song_fit_cpp()
//   util.py  → train_for_batch_batch()   → inner loop of song_fit_cpp()
//   util.py  → train_neighborhood()      → SO + embedding per sample
//   util.py  → bulk_grow_with_drifters() → growth between epochs
//   util.py  → embed_batch_epochs()      → (not needed when non_so_rate=1)
//
// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>
#include <algorithm>
#include <vector>
#include <cmath>

// Forward declaration (defined in knn.cpp)
arma::uvec knn_search_cpp(const arma::rowvec& x, const arma::mat& C, int k);

// ─── Helpers ────────────────────────────────────────────────────────────────

// Python: positive_clip(x, v) — clip scalar to [-v, v]
static inline double pclip(double x, double v) {
  if (x >= v)  return v;
  if (x <= -v) return -v;
  return x;
}

// Python: get_so_rate(tau, sigma) = exp(-sigma * tau^2)
static inline double so_rate(double tau, double sigma) {
  return std::exp(-sigma * tau * tau);
}

// Random integer in [lo, hi] inclusive (Armadillo randi returns ivec, not int)
static inline int rand_int(int lo, int hi) {
  arma::ivec r = arma::randi<arma::ivec>(1, arma::distr_param(lo, hi));
  return r(0);
}


// ─── Main training loop ────────────────────────────────────────────────────
//
// Mirrors the full Python fit() → train_for_batch_batch() → train_neighborhood()
// pipeline.  Variable names match the Python source where possible:
//   W = coding vectors (= C in R model)
//   Y = low-dim embedding
//   adj = adjacency matrix (= G in Python; identity diagonal for active nodes)
//   E_q = accumulated quantization error per node
//
// [[Rcpp::export]]
Rcpp::List song_fit_cpp(
    const arma::mat& X,       // n × D  input data
    int d_out,                 // output dimensionality (Python: self.dim)
    int im_neix,               // neighborhood size (Python: dim + n_neighbors)
    double epsilon,            // edge decay rate (Python default 0.9)
    int max_its,               // training iterations (Python: self.ss, default 50)
    double lrst,               // initial SO learning rate (Python: self.lrst = lr)
    double a_param,            // rational quadratic kernel a
    double b_param,            // rational quadratic kernel b
    double spread_factor,      // growth spread factor
    int ns_rate,               // negative sampling rate (Python default 5)
    double min_strength,       // min edge strength = epsilon^(dim + max_age)
    int max_prototypes,        // max coding vectors (Python: self.prototypes)
    double lr_sigma,           // SO lr decay sigma (Python default 5.0)
    bool verbose,
    int seed
) {
  int n = X.n_rows;
  int D = X.n_cols;
  (void)seed;  // set at R level via set.seed()

  // ── Growth threshold ──
  // Python: thresh_g = -np.log(X.shape[1]) * np.log(self.sf)
  double theta_g = -std::log((double)D) * std::log(spread_factor);

  // ── Initialize coding vectors ──
  int n_init = std::min(im_neix, n);
  int capacity = std::max(max_prototypes + 200, n_init + 500);

  arma::uvec init_idx = arma::randperm(n, n_init);

  arma::mat W = arma::zeros<arma::mat>(capacity, D);
  for (int i = 0; i < n_init; i++) {
    W.row(i) = X.row(init_idx(i));
  }
  W.rows(0, n_init - 1) += arma::randu<arma::mat>(n_init, D) * 0.0001;

  arma::mat Y = arma::zeros<arma::mat>(capacity, d_out);
  Y.rows(0, n_init - 1) = arma::randu<arma::mat>(n_init, d_out);

  // Adjacency — identity for active nodes (Python: G = np.identity)
  arma::mat adj = arma::zeros<arma::mat>(capacity, capacity);
  for (int i = 0; i < n_init; i++) adj(i, i) = 1.0;

  arma::vec E_q = arma::zeros<arma::vec>(capacity);

  int n_coding = n_init;

  // ── Progressive batch-size schedule ──
  // Python: batch_sizes = (n - min_batch) * sratios**10 + min_batch
  int min_batch = std::min(1000, n);
  arma::vec batch_sizes(max_its);
  for (int i = 0; i < max_its; i++) {
    double sratio = (max_its > 1) ? (double)i / (max_its - 1) : 1.0;
    batch_sizes(i) = (double)(n - min_batch) * std::pow(sratio, 10.0)
                     + (double)min_batch;
  }

  arma::uvec data_order = arma::regspace<arma::uvec>(0, n - 1);

  for (int epoch = 0; epoch < max_its; epoch++) {
    Rcpp::checkUserInterrupt();

    // ── Bulk growth between epochs ──
    // Python: bulk_grow_with_drifters(shp, E_q, thresh_g, drifters, G, W, Y)
    if (epoch > 0 && n_coding < max_prototypes) {
      // Collect all nodes exceeding growth threshold
      std::vector<int> growing;
      for (int b = 0; b < n_coding; b++) {
        if (E_q(b) >= theta_g) growing.push_back(b);
      }

      for (size_t gi = 0; gi < growing.size(); gi++) {
        if (n_coding >= max_prototypes) break;
        int b = growing[gi];

        // Python: closests = shp[G[b] == 1]  (strong outgoing edges)
        std::vector<int> closests;
        for (int j = 0; j < n_coding; j++) {
          if (j != b && adj(b, j) == 1.0) closests.push_back(j);
        }
        if (closests.empty()) continue;

        // Expand capacity if needed
        if (n_coding >= capacity) {
          int new_cap = capacity + std::max(capacity / 2, 200);
          arma::mat na = arma::zeros<arma::mat>(new_cap, new_cap);
          na.submat(0, 0, capacity - 1, capacity - 1) = adj;
          adj = na;
          W.resize(new_cap, D);
          Y.resize(new_cap, d_out);
          arma::vec ne = arma::zeros<arma::vec>(new_cap);
          ne.head(capacity) = E_q;
          E_q = ne;
          capacity = new_cap;
        }

        // New CV placement
        // Python: W_n = (1-0.1)*W[b] + 0.1*mean(W[closests])
        //         Y_n = (1-1e-8)*Y[b] + 1e-8*mean(Y[closests])
        arma::rowvec w_mean = arma::zeros<arma::rowvec>(D);
        arma::rowvec y_mean = arma::zeros<arma::rowvec>(d_out);
        for (size_t ci = 0; ci < closests.size(); ci++) {
          w_mean += W.row(closests[ci]);
          y_mean += Y.row(closests[ci]);
        }
        w_mean /= (double)closests.size();
        y_mean /= (double)closests.size();

        int nw = n_coding;
        W.row(nw) = 0.9 * W.row(b) + 0.1 * w_mean;
        Y.row(nw) = (1.0 - 1e-8) * Y.row(b) + 1e-8 * y_mean;
        E_q(nw) = 0.0;

        // Connect new → b and new → closests (one-way)
        // Python: G[new][b] = 1; G[b][new] = 0
        //         G[new][closests] = 1; G[closests][:,new] = 0
        adj(nw, b) = 1.0;
        adj(b, nw) = 0.0;
        for (size_t ci = 0; ci < closests.size(); ci++) {
          adj(nw, closests[ci]) = 1.0;
          adj(closests[ci], nw) = 0.0;
        }

        // Disconnect b ↔ closests
        // Python: G[b][closests] = 0; G[closests][:,b] = 0
        for (size_t ci = 0; ci < closests.size(); ci++) {
          adj(b, closests[ci]) = 0.0;
          adj(closests[ci], b) = 0.0;
        }

        // Reset neighbor errors
        // Python: E_q[closests] *= 0
        for (size_t ci = 0; ci < closests.size(); ci++) {
          E_q(closests[ci]) = 0.0;
        }

        n_coding++;
      }
    }

    // ── Shuffle data, determine batch size ──
    data_order = arma::shuffle(data_order);
    int batch_size = std::min((int)std::round(batch_sizes(epoch)), n);

    // ── SO learning rate for this epoch ──
    // Python: so_lr = lrst * get_so_rate(i / max_its, lr_sigma)
    double so_lr = lrst * so_rate((double)epoch / (double)max_its, lr_sigma);

    int nei_len = std::min(im_neix, n_coding);
    double total_qe = 0.0;

    // ════════════════════════════════════════════════════════════════════════
    //  Process batch  (Python: train_for_batch_batch)
    // ════════════════════════════════════════════════════════════════════════
    for (int ki = 0; ki < batch_size; ki++) {
      int sample_idx = data_order(ki);
      arma::rowvec x = X.row(sample_idx);

      // ── k-NN search ──
      arma::mat W_active = W.rows(0, n_coding - 1);
      arma::uvec neilist = knn_search_cpp(x, W_active, nei_len);
      int b = neilist(0);  // BMU

      // Squared distances to ALL active CVs
      // Python: pdists = sq_eucl_opt(X_chunk, W); dist_H = pdists[k]
      arma::vec dist_H(n_coding);
      for (int j = 0; j < n_coding; j++) {
        arma::rowvec diff = x - W.row(j);
        dist_H(j) = arma::dot(diff, diff);
      }

      total_qe += std::sqrt(dist_H(b));

      // ────────────────────────────────────────────────────────────────────
      //  Edge curation  (Python: train_for_batch_batch lines 282–288)
      //    G[b] *= epsilon
      //    G[b][neilist] = 1
      //    G[b][G[b] < min_strength] = 0
      //    G[:,b][G[:,b] < min_strength] = 0
      // ────────────────────────────────────────────────────────────────────
      for (int j = 0; j < n_coding; j++) {
        if (j != b) adj(b, j) *= epsilon;
      }
      // adj(b,b) left untouched (Python: identity diagonal stays)

      for (int ji = 0; ji < nei_len; ji++) {
        adj(b, neilist(ji)) = 1.0;
      }

      for (int j = 0; j < n_coding; j++) {
        if (adj(b, j) > 0.0 && adj(b, j) < min_strength) adj(b, j) = 0.0;
      }
      for (int j = 0; j < n_coding; j++) {
        if (adj(j, b) > 0.0 && adj(j, b) < min_strength) adj(j, b) = 0.0;
      }

      // Symmetric neighbors: Python nei_bin = (G[b] + G[:,b]) > 0
      std::vector<int> neighbors;
      for (int j = 0; j < n_coding; j++) {
        if (adj(b, j) + adj(j, b) > 0.0) neighbors.push_back(j);
      }
      int n_nbrs = (int)neighbors.size();

      // denom = dist to k-th nearest (for SO neighbourhood function)
      double denom = std::max(dist_H(neilist(nei_len - 1)), 1e-10);

      // ────────────────────────────────────────────────────────────────────
      //  Self-Organization  (Python: train_neighborhood, SO block)
      //    sigma = 1
      //    h_pull = 1 if j==b else exp(-sigma * hdist)
      //    W[j] += h_pull * so_lr * (x - W[j])
      // ────────────────────────────────────────────────────────────────────
      for (int ni = 0; ni < n_nbrs; ni++) {
        int j = neighbors[ni];
        double hdist = dist_H(j) / denom;
        double h_pull = (j == b) ? 1.0 : std::exp(-1.0 * hdist);
        W.row(j) += h_pull * so_lr * (x - W.row(j));
      }

      // ────────────────────────────────────────────────────────────────────
      //  Embedding (topology preservation)
      //  Python: train_neighborhood, embedding block
      //
      //  Two separate schedules:
      //    epoch_vector[j] = int((adj[b][j] + adj[j][b]) / 2 + 1)
      //    neg_epoch_vector[j] = int(ns_rate * (1 - (adj[b][j]+adj[j][b])/2) + 1)
      //
      //  Embedding lr: lr = (1 - tau) where
      //    tau = (epoch * batch_size + ki) / (max_its * batch_size)
      // ────────────────────────────────────────────────────────────────────
      double tau = ((double)epoch * batch_size + ki)
                 / ((double)max_its * batch_size);
      double lr = std::max(1.0 - tau, 0.0);

      arma::rowvec y_b(d_out);
      for (int di = 0; di < d_out; di++) y_b(di) = Y(b, di);

      for (int ni = 0; ni < n_nbrs; ni++) {
        int j = neighbors[ni];
        double e_sym = (adj(b, j) + adj(j, b)) / 2.0;
        int epochs_j  = (int)(e_sym + 1.0);
        int neg_j     = (int)(ns_rate * (1.0 - e_sym) + 1.0);

        for (int e = 0; e < epochs_j; e++) {
          // ── Repulsion (negative sampling) ──
          // Python does NOT skip neighbors; random from all CVs
          for (int s = 0; s < neg_j; s++) {
            int rn = rand_int(0, n_coding - 1);

            double ldist_sq = 0.0;
            for (int di = 0; di < d_out; di++) {
              double d_ = y_b(di) - Y(rn, di);
              ldist_sq += d_ * d_;
            }

            // push_grad = 2*b / (1 + a * ldist_sq^b)
            double push_grad = 2.0 * b_param
              / (1.0 + a_param * std::pow(std::max(ldist_sq, 1e-10), b_param));

            if (ldist_sq > 0.0) {
              double push_f = push_grad / (ldist_sq + 0.001);
              // Sequential per-component update (matches Python exactly)
              for (int di = 0; di < d_out; di++) {
                double diff = y_b(di) - Y(rn, di);
                double g = pclip(push_f * diff, 4.0);
                y_b(di) += g * lr;
                // Recompute diff with updated y_b
                diff = y_b(di) - Y(rn, di);
                g = pclip(push_f * diff, 4.0);
                Y(rn, di) -= g * lr;
              }
            } else if (b != rn) {
              // Python: y_b[i] += lr * 4  (push coincident point away)
              for (int di = 0; di < d_out; di++) {
                y_b(di) += lr * 4.0;
              }
            }
          }

          // ── Attraction ──
          // Python: pull_grad = 2*a*b * ldist^(b-1) / (1 + a * ldist^b)
          double ldist_sq_j = 0.0;
          for (int di = 0; di < d_out; di++) {
            double d_ = y_b(di) - Y(j, di);
            ldist_sq_j += d_ * d_;
          }
          ldist_sq_j = std::max(ldist_sq_j, 1e-10);

          double pull_grad = 2.0 * a_param * b_param
            * std::pow(ldist_sq_j, b_param - 1.0)
            / (1.0 + a_param * std::pow(ldist_sq_j, b_param));

          // Sequential per-component update (matches Python exactly)
          for (int di = 0; di < d_out; di++) {
            double diff = y_b(di) - Y(j, di);
            double g = pclip(pull_grad * diff, 4.0);
            Y(j, di) += g * lr;
            // Recompute diff with updated Y[j]
            diff = y_b(di) - Y(j, di);
            g = pclip(pull_grad * diff, 4.0);
            y_b(di) -= g * lr;
          }
        }  // end epochs_j
      }  // end neighbors

      // Write y_b back to Y[b]
      for (int di = 0; di < d_out; di++) Y(b, di) = y_b(di);

      // ── Accumulate quantization error ──
      // Python: E_q[b] += dist_H[b]  (squared distance to BMU)
      E_q(b) += dist_H(b);

    }  // end batch loop

    if (verbose) {
      Rprintf("Epoch %d/%d | CVs: %d | QE: %.4f | so_lr: %.4f | lr: %.4f\n",
              epoch + 1, max_its, n_coding, total_qe / batch_size, so_lr,
              std::max(1.0 - (double)epoch / max_its, 0.0));
    }
  }  // end epoch loop

  // ═══════════════════════════════════════════════════════════════════════════
  //  Compute assignments & embedding
  // ═══════════════════════════════════════════════════════════════════════════
  arma::mat W_out = W.rows(0, n_coding - 1);
  arma::mat Y_out = Y.rows(0, n_coding - 1);

  arma::ivec assignments(n);
  arma::mat  embedding(n, d_out);
  for (int i = 0; i < n; i++) {
    arma::uvec nn = knn_search_cpp(X.row(i), W_out, 1);
    assignments(i) = (int)nn(0) + 1;   // 1-based for R
    embedding.row(i) = Y_out.row(nn(0));
  }

  // Directed edges = adj without diagonal
  arma::mat E_out = adj.submat(0, 0, n_coding - 1, n_coding - 1);
  E_out.diag().zeros();
  arma::mat E_s_out = (E_out + E_out.t()) / 2.0;

  return Rcpp::List::create(
    Rcpp::Named("C")           = W_out,
    Rcpp::Named("Y")           = Y_out,
    Rcpp::Named("E")           = E_out,
    Rcpp::Named("E_s")         = E_s_out,
    Rcpp::Named("adj")         = adj.submat(0, 0, n_coding - 1, n_coding - 1),
    Rcpp::Named("E_q")         = E_q.head(n_coding),
    Rcpp::Named("assignments") = assignments,
    Rcpp::Named("embedding")   = embedding,
    Rcpp::Named("n_coding")    = n_coding,
    Rcpp::Named("n_epochs")    = max_its,
    Rcpp::Named("converged")   = false
  );
}


// ─── Incremental update ────────────────────────────────────────────────────
//
// Mirrors Python's fit() with self.trained = True.
// Continues training on new data using existing W, Y, adj, E_q.
// Allows further growth up to max_prototypes * 1.5 (Python: prot_inc_portion).
//
// [[Rcpp::export]]
Rcpp::List song_update_cpp(
    const arma::mat& X_new,
    arma::mat W,
    arma::mat Y,
    arma::mat adj_in,          // full adj with diagonal
    arma::vec E_q_in,
    int d_out,
    int im_neix,
    double epsilon,
    int max_its,
    double lrst,
    double a_param,
    double b_param,
    double spread_factor,
    int ns_rate,
    double min_strength,
    int max_prototypes,
    double lr_sigma,
    bool verbose,
    int seed
) {
  int n_new  = X_new.n_rows;
  int D      = X_new.n_cols;
  int n_coding = W.n_rows;
  (void)seed;

  double theta_g = -std::log((double)D) * std::log(spread_factor);

  // Expand capacity
  int capacity = std::max(max_prototypes + 200, n_coding + 500);
  {
    arma::mat na = arma::zeros<arma::mat>(capacity, capacity);
    na.submat(0, 0, n_coding - 1, n_coding - 1) = adj_in;
    adj_in = na;
    W.resize(capacity, D);
    Y.resize(capacity, d_out);
    arma::vec ne = arma::zeros<arma::vec>(capacity);
    ne.head(n_coding) = E_q_in;
    E_q_in = ne;
  }
  arma::mat& adj = adj_in;
  arma::vec& E_q = E_q_in;

  int min_batch = std::min(1000, n_new);
  arma::vec batch_sizes(max_its);
  for (int i = 0; i < max_its; i++) {
    double sratio = (max_its > 1) ? (double)i / (max_its - 1) : 1.0;
    batch_sizes(i) = (double)(n_new - min_batch) * std::pow(sratio, 10.0)
                     + (double)min_batch;
  }

  arma::uvec data_order = arma::regspace<arma::uvec>(0, n_new - 1);

  for (int epoch = 0; epoch < max_its; epoch++) {
    Rcpp::checkUserInterrupt();

    // Bulk growth
    if (epoch > 0 && n_coding < max_prototypes) {
      std::vector<int> growing;
      for (int b = 0; b < n_coding; b++) {
        if (E_q(b) >= theta_g) growing.push_back(b);
      }
      for (size_t gi = 0; gi < growing.size(); gi++) {
        if (n_coding >= max_prototypes) break;
        int b = growing[gi];
        std::vector<int> closests;
        for (int j = 0; j < n_coding; j++) {
          if (j != b && adj(b, j) == 1.0) closests.push_back(j);
        }
        if (closests.empty()) continue;
        if (n_coding >= capacity) {
          int new_cap = capacity + std::max(capacity / 2, 200);
          arma::mat na2 = arma::zeros<arma::mat>(new_cap, new_cap);
          na2.submat(0, 0, capacity - 1, capacity - 1) = adj;
          adj = na2;
          W.resize(new_cap, D);
          Y.resize(new_cap, d_out);
          arma::vec ne2 = arma::zeros<arma::vec>(new_cap);
          ne2.head(capacity) = E_q;
          E_q = ne2;
          capacity = new_cap;
        }
        arma::rowvec w_mean = arma::zeros<arma::rowvec>(D);
        arma::rowvec y_mean = arma::zeros<arma::rowvec>(d_out);
        for (size_t ci = 0; ci < closests.size(); ci++) {
          w_mean += W.row(closests[ci]);
          y_mean += Y.row(closests[ci]);
        }
        w_mean /= (double)closests.size();
        y_mean /= (double)closests.size();
        int nw = n_coding;
        W.row(nw) = 0.9 * W.row(b) + 0.1 * w_mean;
        Y.row(nw) = (1.0 - 1e-8) * Y.row(b) + 1e-8 * y_mean;
        E_q(nw) = 0.0;
        adj(nw, b) = 1.0; adj(b, nw) = 0.0;
        for (size_t ci = 0; ci < closests.size(); ci++) {
          adj(nw, closests[ci]) = 1.0;
          adj(closests[ci], nw) = 0.0;
          adj(b, closests[ci]) = 0.0;
          adj(closests[ci], b) = 0.0;
          E_q(closests[ci]) = 0.0;
        }
        n_coding++;
      }
    }

    data_order = arma::shuffle(data_order);
    int batch_size = std::min((int)std::round(batch_sizes(epoch)), n_new);
    double so_lr = lrst * so_rate((double)epoch / (double)max_its, lr_sigma);
    int nei_len = std::min(im_neix, n_coding);
    double total_qe = 0.0;

    for (int ki = 0; ki < batch_size; ki++) {
      int sample_idx = data_order(ki);
      arma::rowvec x = X_new.row(sample_idx);
      arma::mat W_active = W.rows(0, n_coding - 1);
      arma::uvec neilist = knn_search_cpp(x, W_active, nei_len);
      int b = neilist(0);

      arma::vec dist_H(n_coding);
      for (int j = 0; j < n_coding; j++) {
        arma::rowvec diff = x - W.row(j);
        dist_H(j) = arma::dot(diff, diff);
      }
      total_qe += std::sqrt(dist_H(b));

      // Edge curation
      for (int j = 0; j < n_coding; j++) {
        if (j != b) adj(b, j) *= epsilon;
      }
      for (int ji = 0; ji < nei_len; ji++) adj(b, neilist(ji)) = 1.0;
      for (int j = 0; j < n_coding; j++) {
        if (adj(b, j) > 0.0 && adj(b, j) < min_strength) adj(b, j) = 0.0;
      }
      for (int j = 0; j < n_coding; j++) {
        if (adj(j, b) > 0.0 && adj(j, b) < min_strength) adj(j, b) = 0.0;
      }

      std::vector<int> neighbors;
      for (int j = 0; j < n_coding; j++) {
        if (adj(b, j) + adj(j, b) > 0.0) neighbors.push_back(j);
      }
      int n_nbrs = (int)neighbors.size();
      double denominator = std::max(dist_H(neilist(nei_len - 1)), 1e-10);

      // Self-organization
      for (int ni = 0; ni < n_nbrs; ni++) {
        int j = neighbors[ni];
        double hdist = dist_H(j) / denominator;
        double h_pull = (j == b) ? 1.0 : std::exp(-hdist);
        W.row(j) += h_pull * so_lr * (x - W.row(j));
      }

      // Embedding
      double tau = ((double)epoch * batch_size + ki)
                 / ((double)max_its * batch_size);
      double lr = std::max(1.0 - tau, 0.0);
      arma::rowvec y_b(d_out);
      for (int di = 0; di < d_out; di++) y_b(di) = Y(b, di);

      for (int ni = 0; ni < n_nbrs; ni++) {
        int j = neighbors[ni];
        double e_sym = (adj(b, j) + adj(j, b)) / 2.0;
        int epochs_j = (int)(e_sym + 1.0);
        int neg_j    = (int)(ns_rate * (1.0 - e_sym) + 1.0);

        for (int e = 0; e < epochs_j; e++) {
          for (int s = 0; s < neg_j; s++) {
            int rn = rand_int(0, n_coding - 1);
            double ldist_sq = 0.0;
            for (int di = 0; di < d_out; di++) {
              double d_ = y_b(di) - Y(rn, di);
              ldist_sq += d_ * d_;
            }
            double push_grad = 2.0 * b_param
              / (1.0 + a_param * std::pow(std::max(ldist_sq, 1e-10), b_param));
            if (ldist_sq > 0.0) {
              double push_f = push_grad / (ldist_sq + 0.001);
              for (int di = 0; di < d_out; di++) {
                double diff = y_b(di) - Y(rn, di);
                double g = pclip(push_f * diff, 4.0);
                y_b(di) += g * lr;
                diff = y_b(di) - Y(rn, di);
                g = pclip(push_f * diff, 4.0);
                Y(rn, di) -= g * lr;
              }
            } else if (b != rn) {
              for (int di = 0; di < d_out; di++) y_b(di) += lr * 4.0;
            }
          }
          double ldist_sq_j = 0.0;
          for (int di = 0; di < d_out; di++) {
            double d_ = y_b(di) - Y(j, di);
            ldist_sq_j += d_ * d_;
          }
          ldist_sq_j = std::max(ldist_sq_j, 1e-10);
          double pull_grad = 2.0 * a_param * b_param
            * std::pow(ldist_sq_j, b_param - 1.0)
            / (1.0 + a_param * std::pow(ldist_sq_j, b_param));
          for (int di = 0; di < d_out; di++) {
            double diff = y_b(di) - Y(j, di);
            double g = pclip(pull_grad * diff, 4.0);
            Y(j, di) += g * lr;
            diff = y_b(di) - Y(j, di);
            g = pclip(pull_grad * diff, 4.0);
            y_b(di) -= g * lr;
          }
        }
      }
      for (int di = 0; di < d_out; di++) Y(b, di) = y_b(di);
      E_q(b) += dist_H(b);
    }

    if (verbose) {
      Rprintf("Update Epoch %d/%d | CVs: %d | QE: %.4f | so_lr: %.4f\n",
              epoch + 1, max_its, n_coding, total_qe / batch_size, so_lr);
    }
  }

  arma::mat W_out = W.rows(0, n_coding - 1);
  arma::mat Y_out = Y.rows(0, n_coding - 1);

  arma::ivec assignments(n_new);
  arma::mat  embedding(n_new, d_out);
  for (int i = 0; i < n_new; i++) {
    arma::uvec nn = knn_search_cpp(X_new.row(i), W_out, 1);
    assignments(i) = (int)nn(0) + 1;
    embedding.row(i) = Y_out.row(nn(0));
  }

  arma::mat E_out = adj.submat(0, 0, n_coding - 1, n_coding - 1);
  E_out.diag().zeros();
  arma::mat E_s_out = (E_out + E_out.t()) / 2.0;

  return Rcpp::List::create(
    Rcpp::Named("C")           = W_out,
    Rcpp::Named("Y")           = Y_out,
    Rcpp::Named("E")           = E_out,
    Rcpp::Named("E_s")         = E_s_out,
    Rcpp::Named("adj")         = adj.submat(0, 0, n_coding - 1, n_coding - 1),
    Rcpp::Named("E_q")         = E_q.head(n_coding),
    Rcpp::Named("assignments") = assignments,
    Rcpp::Named("embedding")   = embedding,
    Rcpp::Named("n_coding")    = n_coding,
    Rcpp::Named("n_epochs")    = max_its,
    Rcpp::Named("converged")   = false
  );
}
