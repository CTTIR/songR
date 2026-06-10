import json, numpy as np
from scipy.optimize import curve_fit
OUT = "tests/testthat/fixtures/reference"
def find_spread_tightness(spread, min_dist):   # reference util.py:148-158, verbatim objective
    def curve(x, a, b): return 1. / (1. + a * x ** (2 * b))
    xv = np.linspace(0, spread * 3, 300); yv = np.zeros(xv.shape)
    yv[xv < min_dist] = 1.; yv[xv >= min_dist] = np.exp(-(xv[xv >= min_dist] - min_dist) / spread)
    p,_ = curve_fit(curve, xv, yv); p = p.astype(np.float32); return p[0], p[1]
with open(f"{OUT}/tierA_spread_tightness.csv","w") as f:
    f.write("spread,min_dist,a,b\n")
    for s,md in [(1.0,0.1),(1.0,0.25),(0.5,0.1),(2.0,0.1),(1.0,0.5)]:
        a,b = find_spread_tightness(s,md); f.write("%g,%g,%.8f,%.8f\n"%(s,md,float(a),float(b)))
def scalars(N,D,sf,eps,dim,ma,nn):
    return dict(thresh_g=float(-np.log(D)*np.log(sf)), prototypes=int(np.exp(np.log(N)/1.5)),
                min_strength=float(eps**(dim+ma)), im_neix=int(dim+nn))
json.dump({f"N{N}_D{D}":scalars(N,D,0.5,0.9,2,3,1) for (N,D) in [(150,4),(1600,20),(70000,20)]},
          open(f"{OUT}/tierA_scalars.json","w"), indent=2)
print("TIERA_SCIPY_OK")
