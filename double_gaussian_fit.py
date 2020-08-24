import numpy
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt

# Define some test data which is close to Gaussian
data = plt.hist(step_sizes_list,50)
bin_centres = data[1][1:]
hist = data[0]

# Define model function to be used to fit to the data above:
# Adapt it to as many gaussians you may want
# by copying the function with different A2,mu2,sigma2 parameters
def gauss(x, *p):
    A, mu, sigma = p
    return A*numpy.exp(-(x-mu)**2/(2.*sigma**2))

def gauss2(x, *p):
    A1, mu1, sigma1, A2, mu2, sigma2 = p
    return A1*numpy.exp(-(x-mu1)**2/(2.*sigma1**2)) + A2*numpy.exp(-(x-mu2)**2/(2.*sigma2**2))

# p0 is the initial guess for the fitting coefficients initialize them differently so the optimization algorithm works better
p0 = [100., 100., 10.,20., 200., 10.]

#optimize and in the end you will have 6 coeff (3 for each gaussian)
coeff, var_matrix = curve_fit(gauss2, bin_centres, hist, p0=p0)

#you can plot each gaussian separately using 
pg1 = coeff[0:3]
pg2 = coeff[3:]

g1 = gauss(bin_centres, *pg1)
g2 = gauss(bin_centres, *pg2)

fig = plt.figure()
 
plt.plot(bin_centres, hist, label='Data')
plt.plot(bin_centres, g1, label='Gaussian1', 'r--')
plt.plot(bin_centres, g2, label='Gaussian2','r--')
plt.legend()

plt.show()