import numpy as np



def lattice(u, v):
    """
    Return an array of lattice points in 2D space, with shape (Nu, Nv, 2),
    from two 1D arrays of u and v coordinates.
    """
    assert(u.dtype == v.dtype)
    L = np.zeros((len(u), len(v), 2), dtype=u.dtype)
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
    Return an array of 3D vertices, with shape ((Nu - 1) * (Nv - 1) * 4, 3, 3),
    describing a list of triangles tesselating a 3D quadrilateral mesh.
    """
    a = M[:-1,:-1]
    b = M[:-1,+1:]
    c = M[+1:,+1:]
    d = M[+1:,:-1]
    e = 0.25 * (a + b + c + d)
    return np.array([[e,a,b],[e,b,c],[e,c,d],[e,d,a]]).transpose(2,3,0,1,4).reshape(-1,3,3)



def reach(path, point):
    """
    Return a sequence of triangles, each having the given 3D point as a vertex,
    and whose bases are the N - 1 segments in the given 3D path.
    """
    nseg = path.shape[0] - 1
    T = np.array([path[:-1], path[1:], np.repeat([point], nseg, axis=0)]).swapaxes(0,1)
    return T



def circle(num, dtype=np.float32):
    """
    Return a sequence of `num` (unique) 3D vertices arranged on the unit
    circle in the x-y plane. The first and last vertices are identical.
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



def test():
    x = np.linspace(0, 1, 8).astype(np.float32)
    y = np.linspace(0, 1, 9).astype(np.float32)
    L = lattice(x, y)
    assert(L.shape == (8, 9, 2))
    assert(L[2, 3, 0] == x[2])
    assert(L[2, 3, 1] == y[3])

    M = lift(L)
    assert(M.shape == (8, 9, 3))

    M = lift(L, lambda x, y: np.zeros((x.shape[0], y.shape[1], 3)))
    assert(M.shape == (8, 9, 3))

    M = lift(L, lambda x, y: x + y)
    assert((M[:,:,2] == M[:,:,0] + M[:,:,1]).all())

    lines = gridlines(M)
    assert(lines.shape == ((len(x) - 1) * len(y) + len(x) * (len(y) - 1), 2, 3))

    triangles = triangulate(M)
    assert(triangles.shape == (224, 3, 3))



def height_colors(verts):
    verts = np.array(verts).reshape(-1, 4)
    colors = np.zeros([verts.shape[0], 4], dtype=np.float32)
    colors[:,0] = 0 + verts[:,2]
    colors[:,1] = 1 - verts[:,2]
    colors[:,2] = 1 - verts[:,2] * 0.5
    colors[:,3] = 1.0
    return colors.flatten()



def solid_colors(verts):
    colors = np.zeros_like(verts).reshape(-1, 4)
    colors[:,3] = 1.0
    return colors.flatten()



def cycle_colors(num):
    colors = np.zeros([num, 4])
    for n in range(num):
        colors[n, n % 3] = 1
    return colors.flatten()



def node(vertices, colors=solid_colors, primitive='triangle'):
    import mirage
    node = mirage.Node()
    node.vertices = tovert4(vertices)
    node.colors = colors(node.vertices) if callable(colors) else colors
    node.type = primitive
    return node



def scene(name="Scene", *nodes):
    import mirage
    s = mirage.Scene()
    s.nodes = nodes
    s.name = name
    return s



def example_gridlines():
    import mirage
    x = np.linspace(-1, 1, 24)
    y = np.linspace(-1, 1, 24)
    return scene("Gridlines", node(gridlines(lift(lattice(x, y))), primitive='line'))



def example_triangle():
    x = np.linspace(-1, 1, 14)
    y = np.linspace(-1, 1, 11)
    f = lambda x, y: x**2 + y**2
    return scene("Triangular lattice", node(triangulate(lift(lattice(x, y), f)), height_colors))



def example_cone():
    node1 = node(cone(24) * 1.00, height_colors, 'triangle')
    node2 = node(cone(24) * 1.01, solid_colors, 'line strip')
    return scene("Cone", node1, node2)



def run_mirage():
    import mirage
    mirage.show([example_gridlines(), example_triangle(), example_cone()])



if __name__ == "__main__":
    #test()
    run_mirage()