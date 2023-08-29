import numpy as np

x = np.array([[0, 1], [2, 3]], dtype='int64')
b = x[0,1]
print(b.astype('int8').tobytes())
print(x.tobytes())