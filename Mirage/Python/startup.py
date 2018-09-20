import sys
import numpy as np
import mirage



class _LogWriter:
    def flush(self):
        pass

    def write(self, s):
        mirage.log(s)


sys.stdout = _LogWriter()
sys.stderr = _LogWriter()



def lattice(u, v, dtype=np.float32):
    """
    Return an array of lattice points in 2D space, with shape (Nu, Nv, 2),
    from two 1D arrays of u and v coordinates.
    """
    L = np.zeros((len(u), len(v), 2), dtype=dtype)
    for i in range(len(u)): L[i,:,1] = v
    for j in range(len(v)): L[:,j,0] = u
    return L



def lift(L, f=None):
    """
    Return a 3D quadrilateral mesh, with shape (L.shape[0], L.shape[1], 3)
    from the given lattice and an optional mapping f: R2 -> R1 or R2 -> R3. If
    the function f is None, z-coordinates are all 0.0.
    """
    M = np.zeros((L.shape[0], L.shape[1], 3), dtype=L.dtype)

    if f is None:
        M[:,:,0] = L[:,:,0]
        M[:,:,1] = L[:,:,1]
        M[:,:,2] = 0.0
    else:
        F = f(L[:,:,0], L[:,:,1])   
        try:
            M[...] = F
        except ValueError:
            M[:,:,0] = L[:,:,0]
            M[:,:,1] = L[:,:,1]
            M[:,:,2] = F
    return M



def reach(path, point):
    """
    Return a sequence of triangles, each having the given 3D point as a vertex,
    and whose bases are the N - 1 segments in the given 3D path.
    """
    nseg = path.shape[0] - 1
    T = np.array([path[:-1], path[1:], np.repeat([point], nseg, axis=0)]).swapaxes(0,1)
    return T



def bridge(path1, path2):
    """
    Return a 3D quadrilateral mesh linking the given 3D paths.
    """
    Q = np.zeros([path1.shape[0], 2, 3])
    Q[:,0,:] = path1
    Q[:,1,:] = path2
    return Q



def gridlines(M):
    """
    Return an array of 3D vertices, with shape ((Nu - 1) * Nv + Nu * (Nv - 1),
    2, 3), describing the segments to adjacent vertices in a 3D quadrilateral
    mesh. Size 2 on axis 1 represents the vertices of the segment endpoints.
    """
    u = np.array([M[:-1,:], M[1:,:]]).swapaxes(0, 2).reshape(-1, 2, 3)
    v = np.array([M[:,:-1], M[:,1:]]).swapaxes(0, 2).reshape(-1, 2, 3)
    return np.vstack([u, v])



def triangulate(M):
    """
    Return an array of 3D vertices, with shape (Nu - 1, Nv - 1, 4, 3, 3),
    describing a list of triangles tesselating a 3D quadrilateral mesh. Each
    quad is broken into 4 triangles, all sharing a vertex at the quad centroid.
    """
    Nu = M.shape[0]
    Nv = M.shape[1]
    a = M[:-1,:-1]
    b = M[:-1,+1:]
    c = M[+1:,+1:]
    d = M[+1:,:-1]
    e = 0.25 * (a + b + c + d)
    return np.array([[e,a,b],[e,b,c],[e,c,d],[e,d,a]]).transpose(2,3,0,1,4).reshape(Nu-1,Nv-1,4,3,3)



def circle(num, dtype=np.float32):
    """
    Return a sequence of 3D vertices of shape (num + 1, 3), arranged on the
    unit circle in the x-y plane. The first and last vertices are identical.
    """
    V = np.zeros([num + 1, 3], dtype=dtype)
    t = np.linspace(0, 2 * np.pi, num + 1).astype(dtype)
    V[:,0] = np.cos(t)
    V[:,1] = np.sin(t)
    return V



def cone(num):
    return reach(circle(num), [0, 0, 1])



def tovert4(M):
    """
    Convert an array of 3D vertices to an array whose last axis has size 4 and
    is filled with ones. The result is flattened to a 1D array.
    """
    M4 = np.zeros(M.shape[:-1] + (4,), dtype=M.dtype)
    M4[...,0:3] = M
    M4[...,3] = 1.0
    return M4.flatten()



def to_spherical(q, p):
    x = np.sin(q) * np.cos(p)
    y = np.sin(q) * np.sin(p)
    z = np.cos(q)
    return np.array([x, y, z]).transpose(1,2,0)



def height_colors(verts):
    colors = np.zeros(verts.shape[:-1] + (4,), dtype=np.float32)
    colors[...,0] = 0 + verts[...,2]
    colors[...,1] = 1 - verts[...,2]
    colors[...,2] = 1 - verts[...,2] * 0.5
    colors[...,3] = 1.0
    return colors



def solid_colors(verts, rgba=[0,0,0,1]):
    colors = np.zeros(verts.shape[:-1] + (4,), dtype=np.float32)
    colors[...] = rgba
    return colors



def cycle_colors(verts):
    colors = np.zeros(verts.shape[:-1] + (4,), dtype=np.float32).reshape(-1, 4)
    colors[0::3] = [1.0, 0.0, 0.0, 1]
    colors[1::3] = [0.0, 1.0, 0.0, 1]
    colors[2::3] = [0.0, 0.0, 1.0, 1]
    return colors



def checkerboard(verts, dark=[0.4,0.4,0.4,1], light=[0.5,0.5,0.5,1]):
    """
    Return an array of RGBA colors corresponding to an array of 3D vertices
    having a shape (Nu, Nv, ..., 3). The ellipses stands for any number of
    intermediate axes.
    """
    e = np.indices(verts.shape[:2]).sum(axis=0) % 2 == 0
    o = np.indices(verts.shape[:2]).sum(axis=0) % 2 == 1
    colors = np.zeros(verts.shape[:-1] + (4,), dtype=np.float32)
    colors[e] = dark
    colors[o] = light
    return colors



def scene(name="Scene", *nodes):
    import mirage
    s = mirage.Scene()
    s.nodes = nodes
    s.name = name
    return s



def node(vertices, colors=solid_colors, primitive='triangle', position=[0, 0, 0]):
    import mirage

    # Demonstates data member piecewise construction
    node = mirage.Node()
    node.vertices  = tovert4(vertices)
    node.colors    = colors(vertices).flatten() if callable(colors) else colors.flatten()
    node.primitive = primitive
    node.position  = position
    return node



def text_node(text, scale=10):
    import mirage

    text = mirage.text(text)
    w = text.width
    h = text.height

    va = [0.0, 0.0 * h / w, 0, 0]
    vb = [0.0, 1.0 * h / w, 0, 0]
    vc = [1.0, 1.0 * h / w, 0, 0]
    vd = [1.0, 0.0 * h / w, 0, 0]
    ve = [0.5, 0.5 * h / w, 0, 0]
    tb = [0.0, 0.0, 0, 0]
    ta = [0.0, 1.0, 0, 0]
    td = [1.0, 1.0, 0, 0]
    tc = [1.0, 0.0, 0, 0]
    te = [0.5, 0.5, 0, 0]
    verts = [[ve,va,vb],[ve,vb,vc],[ve,vc,vd],[ve,vd,va]]
    texts = [[te,ta,tb],[te,tb,tc],[te,tc,td],[te,td,ta]]

    # Demonstates all-at-once construction
    return mirage.Node(
        vertices  = np.array(verts).flatten() * scale,
        colors    = np.array(texts).flatten(),
        position  = [-ve[0] * scale, -ve[1] * scale, 0],
        primitive = 'triangle',
        texture   = text)


