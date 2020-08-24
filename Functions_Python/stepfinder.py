
import numpy as np
from sklearn.tree import DecisionTreeRegressor


def find_steps(x, y, min_step_size, min_plateau_length=1):
    """Find steps in a signal using a decision tree. Nota bene: steps can go up or down, so blinking is also detected.

    Parameters
    ----------
    x : numpy array of floats
        x values
    y : numpy array of floats
        y values (signal).
    min_step_size : float
        Minimum step size.
    min_plateau_length : int
        Minimum length of plateaus. Default: 1.

    Returns
    -------
    step_locs : numpy array of ints
        Location indices of steps.
    step_sizes : numpy array of floats
        Sizes of steps.
    sig_det : numpy array of floats
        Detected signal, only containing steps.
    """

    # Define decision tree model; fit and predict.
    model = DecisionTreeRegressor(min_samples_leaf=min_plateau_length,
                                  min_impurity_decrease=min_step_size)
    x_fit = np.array(x).reshape((-1, 1))
    model.fit(x_fit, y)
    sig_det = model.predict(x_fit)

    # Even out steps that are too small; start with smallest step.
    # Iterate until there are no steps that are under min_step_size.
    small_step = True
    step_locs = []
    step_sizes = []
    while small_step:

        # Store step locations and sizes.
        step_locs = []
        step_sizes = []
        for i in range(len(y) - 1):
            if sig_det[i+1] != sig_det[i]:
                step_locs.append(i+1)
                step_sizes.append(sig_det[i] - sig_det[i+1])
        step_locs = np.array(step_locs, dtype=int)
        step_sizes = np.array(step_sizes)

        if len(step_sizes) == 0:
            return [], [], sig_det

        # Get rid of smallest step.
        if np.amin(step_sizes) < min_step_size and len(step_sizes) > 0:
            i_min = step_sizes.argmin()
            if i_min > 0:
                x_start = step_locs[i_min - 1]
            else:
                x_start = 0
            if i_min < len(step_sizes) - 1:
                x_end = step_locs[i_min + 1]
            else:
                x_end = len(x)
            sig_det[x_start:x_end] = np.mean(sig_det[x_start:x_end])
        else:
            small_step = False

    return step_locs, step_sizes, sig_det

def running_mean(x, n):
    rmean = np.zeros(len(x))
    for i in range(len(x)):
        diff_start = max(0, i - n)
        diff_end = len(x) - min(len(x), i + n)
        diff = min(min(diff_start, diff_end), n)
        rmean[i] = np.mean(x[i-diff:i+diff+1])
    return rmean