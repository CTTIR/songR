# Verifies the single repaired env can do every native op the fixtures need.
import os
os.environ["KMP_DUPLICATE_LIB_OK"]="TRUE"; os.environ["OMP_NUM_THREADS"]="1"
os.environ["NUMBA_NUM_THREADS"]="1"; os.environ["MKL_NUM_THREADS"]="1"
import numpy as np
from scipy.optimize import curve_fit
from sklearn.decomposition import PCA
from sklearn.cluster import KMeans
from umap import UMAP
rng = np.random.RandomState(0)
X = rng.rand(120, 8).astype(np.float32)
# 1 curve_fit
curve_fit(lambda x,a,b: 1./(1.+a*x**(2*b)), np.linspace(0,3,50), np.exp(-np.linspace(0,3,50)))
# 2 PCA
PCA(n_components=5, random_state=0).fit_transform(X)
# 3 KMeans
KMeans(n_clusters=4, n_init=3, random_state=0).fit_predict(X)
# 4 UMAP (provided init, tiny)
UMAP(n_components=2, n_epochs=11, init=rng.rand(120,2), min_dist=0.001).fit_transform(X)
print("SMOKE_OK: curve_fit + PCA + KMeans + UMAP all pass")
