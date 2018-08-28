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



def tovert4(M):
    """
    Convert an array of 3D vertices to an array whose last axis has size 4 and
    is filled with ones. The result is flattened to a 1D array.
    """
    M4 = np.zeros(M.shape[:-1] + (4,), dtype=M.dtype)
    M4[:,:,0:3] = M
    M4[:,:,3] = 1.0
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



def solid_colors(num):
    colors = np.zeros([num, 4])
    colors[:,3] = 1
    return colors.flatten()



def height_colors(verts):
    verts = np.array(verts).reshape(-1, 4)
    colors = np.zeros([verts.shape[0], 4], dtype=np.float32)
    colors[:,0] = 0 + verts[:,2]
    colors[:,1] = 1 - verts[:,2]
    colors[:,2] = 1 - verts[:,2] * 0.5
    colors[:,3] = 1.0
    return colors.flatten()



def cycle_colors(num):
    colors = np.zeros([num, 4])
    for n in range(num):
        colors[n, n % 3] = 1
    return colors.flatten()



def example_gridlines():
    import mirage

    x = np.linspace(-1, 1, 24)
    y = np.linspace(-1, 1, 24)

    node = mirage.Node()
    node.vertices = tovert4(gridlines(lift(lattice(x, y))))
    node.colors = solid_colors(len(node.vertices) // 4)
    node.type = 'line'
    scene = mirage.Scene()
    scene.nodes = [node]
    scene.name = "Grid lines"
    return scene



def example_triangle():
    import mirage

    x = np.linspace(-1, 1, 14)
    y = np.linspace(-1, 1, 11)

    f = lambda x, y: x**2 + y**2

    node = mirage.Node()
    node.vertices = tovert4(triangulate(lift(lattice(x, y), f)))
    node.colors = height_colors(node.vertices)
    node.type = 'triangle'
    scene = mirage.Scene()
    scene.nodes = [node]
    scene.name = "Triangulate lattice"
    return scene



def run_mirage():
    import mirage
    mirage.show([example_gridlines(), example_triangle()])



if __name__ == "__main__":
    #test()
    run_mirage()