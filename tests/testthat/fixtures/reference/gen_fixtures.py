import os
# numba-backed reference functions + end-to-end SONG. Tier-A scipy oracles
# (find_spread_tightness, scalars) are generated separately by gen_spread.py
# using the base env, because curve_fit's LAPACK aborts inside the songref env.
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
os.environ["OMP_NUM_THREADS"] = "1"
os.environ["NUMBA_NUM_THREADS"] = "1"
os.environ["MKL_NUM_THREADS"] = "1"
import sys, json
import numpy as np
import numba
numba.config.THREADING_LAYER = "workqueue"
sys.path.insert(0, ".archive/SONG-master/SONG-master")
from song import util
from song.song import SONG

OUT = "tests/testthat/fixtures/reference"
STATUS = open(f"{OUT}/STATUS.txt", "w")
def step(m): STATUS.write(m + "\n"); STATUS.flush()
np.random.seed(0)
step("imports OK")

# ---- Tier A: exact reference numba kernels ----
A = np.random.rand(5, 4).astype(np.float32)
B = np.random.rand(7, 4).astype(np.float32)
np.savetxt(f"{OUT}/tierA_A.csv", A, delimiter=",")
np.savetxt(f"{OUT}/tierA_B.csv", B, delimiter=",")
np.savetxt(f"{OUT}/tierA_sqdist.csv", util.sq_eucl_opt(A, B), delimiter=",")
np.savetxt(f"{OUT}/tierA_argmin.csv", util.get_closest_for_inputs(A, B).astype(np.int64), fmt="%d")
step("sq_eucl + argmin OK")

# ---- Tier B: end-to-end on a SHARED dataset (explicit a,b => no curve_fit) ----
from sklearn.datasets import make_blobs
Xb, yb = make_blobs(n_samples=800, centers=8, n_features=20, random_state=1, cluster_std=3.0)
Xb = ((Xb - Xb.min(0)) / (Xb.max(0) - Xb.min(0))).astype(np.float32)
np.savetxt(f"{OUT}/tierB_blobs_X.csv", Xb, delimiter=",")
np.savetxt(f"{OUT}/tierB_blobs_y.csv", yb.astype(np.int64), fmt="%d")
step("blobs data saved")

# dispersion=None, reduction=None: raw-space SONG, the apples-to-apples match
# for songR's dispersion=FALSE. We avoid SONG.transform() entirely (its
# reduction=None branch assumes sparse input -> .toarray(); reduction='PCA'
# hits songref's broken LAPACK). Instead we reproduce transform()'s core:
#   min_dist_args = get_closest_for_inputs(X, W);  Y_out = self.Y[args]
# AMI is computed in R (sklearn KMeans also hits the broken LAPACK here).
m = SONG(n_components=2, n_neighbors=1, epsilon=0.99, spread_factor=0.5,
         so_steps=100, a=1.577, b=0.895, random_seed=1, dispersion_method=None)
m.fit(Xb, reduction=None)
step("ref fit done CVs=%d" % m.W.shape[0])
args = util.get_closest_for_inputs(Xb, m.W.astype(np.float32))
emb_n = np.asarray(m.Y[args], dtype=np.float64)
np.savetxt(f"{OUT}/tierB_blobs_emb_nodisp.csv", emb_n, delimiter=",")
np.savetxt(f"{OUT}/tierB_blobs_W.csv", np.asarray(m.W, dtype=np.float64), delimiter=",")
step("ref nodisp embedding saved")

meta = dict(dataset="make_blobs(800,8,20D,std3,seed1)->[0,1]",
            ref_params="epsilon=0.99,n_neighbors=1,so_steps=100,a=1.577,b=0.895,seed=1,sf=0.5",
            reduction="None", dispersion="None",
            n_coding_nodisp=int(m.W.shape[0]),
            note="AMI computed in R (songref LAPACK broken); raw-space SONG, no PCA, no UMAP")
json.dump(meta, open(f"{OUT}/tierB_blobs_meta.json","w"), indent=2)
step("FIXTURES OK")
print("FIXTURES OK"); print(json.dumps(meta, indent=2))
