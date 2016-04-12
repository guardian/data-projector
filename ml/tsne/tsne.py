# augmented from Cyrille Rossant's and O'Reilly's blog post: 
# https://www.oreilly.com/learning/an-illustrated-introduction-to-the-t-sne-algorithm
import logging, argparse, os, multiprocessing
from datetime import datetime
from functools import partial

import numpy as np
from numpy import linalg
from numpy.linalg import norm
from scipy.spatial.distance import squareform, pdist

# sklearn
import sklearn
from sklearn.manifold import TSNE
from sklearn.datasets import load_digits
from sklearn.preprocessing import scale
from sklearn.cluster import KMeans

# sklearn 0.17.1 for monkey patching
from sklearn.metrics.pairwise import pairwise_distances
from sklearn.manifold.t_sne import _joint_probabilities, _kl_divergence
from sklearn.utils.extmath import _ravel

# matplotlib for graphics
import matplotlib.pyplot as plt
import matplotlib.patheffects as PathEffects
import matplotlib

# seaborn for pretty plots
import seaborn as sns
sns.set_style('darkgrid')
sns.set_palette('muted')
sns.set_context("notebook", font_scale=1.5, rc={"lines.linewidth": 2.5})

# moviepy for animations
from moviepy.video.io.bindings import mplfig_to_npimage
import moviepy.editor as mpy

def scatter(x, colors):
    # We choose a color palette with seaborn.
    n_colors = len(set(colors))
    palette = np.array(sns.color_palette("hls", n_colors))

    # We create a scatter plot.
    f = plt.figure(figsize=(8, 8))
    ax = plt.subplot(aspect='equal')
    sc = ax.scatter(x[:,0], x[:,1], lw=0, s=40, c=palette[colors.astype(np.int)])
    plt.xlim(-25, 25)
    plt.ylim(-25, 25)
    ax.axis('off')
    ax.axis('tight')

    # We add the labels for each digit.
    txts = []
    ''' 
    # TODO fix text.py bug with matplotlib. passing in NaN as labels when doing median
    for i in range(n_colors):
        # Position of each label.
        xtext, ytext = np.median(x[colors == i, :], axis=0)
        txt = ax.text(xtext, ytext, str(i), fontsize=24)
        txt.set_path_effects([
            PathEffects.Stroke(linewidth=5, foreground="w"),
            PathEffects.Normal()])
        txts.append(txt)
    '''
    return f, ax, sc, txts

def _gradient_descent(objective, p0, it, n_iter, objective_error=None,
                      n_iter_check=1, n_iter_without_progress=50,
                      momentum=0.5, learning_rate=1000.0, min_gain=0.01,
                      min_grad_norm=1e-7, min_error_diff=1e-7, verbose=0,
                      args=None, kwargs=None):
    '''monkey patched sklearn v0.17.1: sklearn.manifold.t_sne.__gradient_descent method.'''
    if args is None:
        args = []
    if kwargs is None:
        kwargs = {}

    p = p0.copy().ravel()
    update = np.zeros_like(p)
    gains = np.ones_like(p)
    error = np.finfo(np.float).max
    best_error = np.finfo(np.float).max
    best_iter = 0

    for i in range(it, n_iter):
        # We save the current position.
        global positions
        positions.append(p.copy())

        new_error, grad = objective(p, *args, **kwargs)
        grad_norm = linalg.norm(grad)

        inc = update * grad >= 0.0
        dec = np.invert(inc)
        gains[inc] += 0.05
        gains[dec] *= 0.95
        np.clip(gains, min_gain, np.inf)
        grad *= gains
        update = momentum * update - learning_rate * grad
        p += update

        if (i + 1) % n_iter_check == 0:
            if new_error is None:
                new_error = objective_error(p, *args)
            error_diff = np.abs(new_error - error)
            error = new_error

            if verbose >= 2:
                m = "[t-SNE] Iteration %d: error = %.7f, gradient norm = %.7f"
                print(m % (i + 1, error, grad_norm))

            if error < best_error:
                best_error = error
                best_iter = i
            elif i - best_iter > n_iter_without_progress:
                if verbose >= 2:
                    print("[t-SNE] Iteration %d: did not make any progress "
                          "during the last %d episodes. Finished."
                          % (i + 1, n_iter_without_progress))
                break
            if grad_norm <= min_grad_norm:
                if verbose >= 2:
                    print("[t-SNE] Iteration %d: gradient norm %f. Finished."
                          % (i + 1, grad_norm))
                break
            if error_diff <= min_error_diff:
                if verbose >= 2:
                    m = "[t-SNE] Iteration %d: error difference %f. Finished."
                    print(m % (i + 1, error_diff))
                break

        if new_error is not None:
            error = new_error

    return p, error, i

def make_tsne_frame_mpl(t):
    i = int(t*40)
    x = X_iter[..., i]
    sc.set_offsets(x)
    for j, txt in zip(range(10), txts):
        xtext, ytext = np.median(x[y == j, :], axis=0)
        txt.set_x(xtext)
        txt.set_y(ytext)
    return mplfig_to_npimage(f)

if __name__ == '__main__':
    from gensim.models import Doc2Vec

    # setup custom logging
    logfile = '{abspath}/logs/{time}.log'.format(
        abspath = os.path.dirname(os.path.abspath(__file__)),
        time = datetime.now())
    logging.basicConfig(filename=logfile, level=logging.WARNING)

    # parse cmd line arguments
    parser = argparse.ArgumentParser(description='t-SNE on doc2vec embeddings including visualization of convergence')
    parser.add_argument('-m','--model', required=True, help='path to doc2vec model')
    parser.add_argument('-s','--seed', default=None, help='pass deterministic seed to t-sne')
    arg = parser.parse_args()

    # t-sne random state
    RS = 20150101 if arg.seed else None

    # load doc2vec model from file path
    d2v = Doc2Vec.load(arg.model)

    # grab doc2vec embedded representations
    X = np.vstack([v for v in d2v.docvecs])

    # record point positions on every iteration of t-SNE
    global positions
    positions = []

    # monkey patch sklearn's _gradient_descent method to capture point positions during t-sne
    sklearn.manifold.t_sne._gradient_descent = _gradient_descent

    # t-SNE!
    print 'running t-sne'
    X_proj = TSNE(random_state=RS).fit_transform(X)

    # reshape t-SNE positions for graphing
    X_iter = np.dstack(position.reshape(-1, 2) for position in positions)

    # perform k-means on the document vectors
    # these high-dimensional clusters will be our coloring scheme after reducing the dimensionality
    for n_clusters in range(6,13):
        print 'k-means. num clusters:', n_clusters
        kmeans = KMeans(n_clusters=n_clusters,
                        precompute_distances=True, 
                        n_jobs=multiprocessing.cpu_count())
        kmeans.fit(X)
        y = kmeans.labels_

        # create scatter plot animation of t-SNE converging
        f, ax, sc, txts = scatter(X_iter[..., -1], y)
        animation = mpy.VideoClip(make_tsne_frame_mpl, duration=X_iter.shape[2]/40.)
        # TODO dynamically mkdir for imgs/<d2v-model>/*
        animation.write_gif("imgs/tsne-animation-clusters{}.gif".format(n_clusters), fps=20)
