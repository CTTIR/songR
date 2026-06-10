"""Single-env golden-fixture generator for the songR reference-parity tests.

Runs entirely in the pinned conda-forge `songref` env (see environment.yml).
Reproduce with:  python tests/testthat/fixtures/reference/gen_fixtures.py

Produces, from the vendored reference (.archive/SONG-master, Senanayake et al.):
  Tier A : tierA_spread_tightness.csv, tierA_scalars.json,
           tierA_{A,B,sqdist,argmin}.csv
  Tier B : tierB_blobs_{X,y,W,emb_nodisp}.csv + meta        (raw-space, no UMAP)
           tierB_{mnist,fmnist}_emb_umap.csv + meta          (UMAP-dispersed)
The MNIST/FMNIST inputs (tierB_{mnist,fmnist}_{X,y}.csv) are exported from R
(deterministic subsamples of the PCA->20 datasets) before running this script.
"""
import os
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
os.environ["OMP_NUM_THREADS"] = "1"
os.environ["NUMBA_NUM_THREADS"] = "1"
os.environ["MKL_NUM_THREADS"] = "1"
import sys, json
import numpy as np
from scipy.optimize import curve_fit
import numba
numba.config.THREADING_LAYER = "workqueue"
sys.path.insert(0, ".archive/SONG-master/SONG-master")
from song import util
from song.song import SONG

OUT = "tests/testthat/fixtures/reference"
STATUS = open(f"{OUT}/STATUS.txt", "w")
def step(m): STATUS.write(m + "\n"); STATUS.flush(); print(m, flush=True)

# ---------------- Tier A: scipy oracle ----------------
def find_spread_tightness(spread, min_dist):  # reference util.py:148-158
    def curve(x, a, b): return 1. / (1. + a * x ** (2 * b))
    xv = np.linspace(0, spread * 3, 300); yv = np.zeros(xv.shape)
    yv[xv < min_dist] = 1.; yv[xv >= min_dist] = np.exp(-(xv[xv >= min_dist] - min_dist) / spread)
    p, _ = curve_fit(curve, xv, yv); p = p.astype(np.float32); return p[0], p[1]

with open(f"{OUT}/tierA_spread_tightness.csv", "w") as f:
    f.write("spread,min_dist,a,b\n")
    for s, md in [(1.0,0.1),(1.0,0.25),(0.5,0.1),(2.0,0.1),(1.0,0.5)]:
        a, b = find_spread_tightness(s, md); f.write("%g,%g,%.8f,%.8f\n" % (s, md, float(a), float(b)))

def scalars(N,D,sf,eps,dim,ma,nn):
    return dict(thresh_g=float(-np.log(D)*np.log(sf)), prototypes=int(np.exp(np.log(N)/1.5)),
                min_strength=float(eps**(dim+ma)), im_neix=int(dim+nn))
json.dump({f"N{N}_D{D}": scalars(N,D,0.5,0.9,2,3,1) for (N,D) in [(150,4),(1600,20),(70000,20)]},
          open(f"{OUT}/tierA_scalars.json","w"), indent=2)
step("Tier A scipy OK")

# ---------------- Tier A: numba kernels (seed/order identical to committed) ----------------
np.random.seed(0)
A = np.random.rand(5, 4).astype(np.float32)
B = np.random.rand(7, 4).astype(np.float32)
np.savetxt(f"{OUT}/tierA_A.csv", A, delimiter=",")
np.savetxt(f"{OUT}/tierA_B.csv", B, delimiter=",")
np.savetxt(f"{OUT}/tierA_sqdist.csv", util.sq_eucl_opt(A, B), delimiter=",")
np.savetxt(f"{OUT}/tierA_argmin.csv", util.get_closest_for_inputs(A, B).astype(np.int64), fmt="%d")
step("Tier A numba OK")

# ---------------- Tier B nodisp: raw-space SONG on shared blobs ----------------
from sklearn.datasets import make_blobs
Xb, yb = make_blobs(n_samples=800, centers=8, n_features=20, random_state=1, cluster_std=3.0)
Xb = ((Xb - Xb.min(0)) / (Xb.max(0) - Xb.min(0))).astype(np.float32)
np.savetxt(f"{OUT}/tierB_blobs_X.csv", Xb, delimiter=",")
np.savetxt(f"{OUT}/tierB_blobs_y.csv", yb.astype(np.int64), fmt="%d")
m = SONG(n_components=2, n_neighbors=1, epsilon=0.99, spread_factor=0.5,
         so_steps=100, a=1.577, b=0.895, random_seed=1, dispersion_method=None)
m.fit(Xb, reduction=None)  # core SONG only (no transform: its dense reduction=None path has a .toarray bug)
args = util.get_closest_for_inputs(Xb, m.W.astype(np.float32))
np.savetxt(f"{OUT}/tierB_blobs_emb_nodisp.csv", np.asarray(m.Y[args], dtype=np.float64), delimiter=",")
np.savetxt(f"{OUT}/tierB_blobs_W.csv", np.asarray(m.W, dtype=np.float64), delimiter=",")
json.dump(dict(dataset="make_blobs(800,8,20D,std3,seed1)->[0,1]",
               ref_params="epsilon=0.99,n_neighbors=1,so_steps=100,a=1.577,b=0.895,seed=1,sf=0.5",
               reduction="None", dispersion="None", n_coding_nodisp=int(m.W.shape[0]),
               note="AMI computed in R; raw-space SONG, no PCA, no UMAP"),
          open(f"{OUT}/tierB_blobs_meta.json","w"), indent=2)
step("Tier B nodisp OK CVs=%d" % m.W.shape[0])

# ---------------- Tier B dispersed: UMAP back-end on MNIST / Fashion-MNIST (PCA->20) ----------------
disp_meta = {}
for name in ("mnist", "fmnist"):
    Xp = np.loadtxt(f"{OUT}/tierB_{name}_X.csv", delimiter=",").astype(np.float32)
    md = SONG(n_components=2, n_neighbors=1, epsilon=0.99, spread_factor=0.5,
              so_steps=100, a=1.577, b=0.895, random_seed=1, dispersion_method='UMAP',
              um_epochs=11, um_lr=0.01, um_min_dist=0.001)
    emb = np.asarray(md.fit_transform(Xp, reduction='PCA'), dtype=np.float64)
    np.savetxt(f"{OUT}/tierB_{name}_emb_umap.csv", emb, delimiter=",")
    disp_meta[name] = dict(n=int(Xp.shape[0]), n_coding=int(md.W.shape[0]))
    step("Tier B dispersed %s OK CVs=%d" % (name, md.W.shape[0]))
json.dump(dict(ref_umap="um_epochs=11,um_lr=0.01,um_min_dist=0.001,init=scaled SONG Y (x10)",
               ref_params="epsilon=0.99,n_neighbors=1,so_steps=100,a=1.577,b=0.895,seed=1,sf=0.5,reduction=PCA",
               datasets=disp_meta, note="AMI computed in R; songR uses uwot vs reference umap-learn"),
          open(f"{OUT}/tierB_dispersed_meta.json","w"), indent=2)
step("FIXTURES OK")
