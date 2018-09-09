import numpy as np



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



def example_triangle(t=1.0):
    x = np.linspace(-1, 1, 14) * t
    y = np.linspace(-1, 1, 11) * t
    f = lambda x, y: x**2 + y**2
    return scene("Triangular lattice", node(triangulate(lift(lattice(x, y), f)), height_colors))



def example_cone():
    node1 = node(cone(24), height_colors, 'triangle', [0, 0, 0.50])
    node2 = node(cone(24), solid_colors, 'line strip', [0, 0, 0.51])
    return scene("Cone", node1, node2)



def example_cylinder():
    path1 = circle(10) + [0, 0, 1]
    path2 = circle(10) - [0, 0, 1]
    n = node(triangulate(bridge(path1, path2)), cycle_colors)
    return scene("Cylinder", n)



def example_sphere():
    q = np.linspace(0, 1 * np.pi, 20)
    p = np.linspace(0, 2 * np.pi, 20)
    verts = triangulate(lift(lattice(q, p), to_spherical))
    n = node(verts, cycle_colors)
    return scene("Sphere", n)



def example_text_quad():
    return scene("Text quad", text_node("Here you go the text for you!"))



def example_helix():
    t = np.linspace(-8 * np.pi, 8 * np.pi, 300)
    path1 = np.array([np.cos(t), np.sin(t), t * 0.1]).T
    path2 = path1.copy()
    path2[:,0:2] *= 0.8
    path2[:,2] += 0.1
    n = node(triangulate(bridge(path1, path2)), cycle_colors)
    return scene("Helix", n)



def example_plot_axes(t=0.75):
    from functools import partial

    path1 = circle(90) * 0.25 + [0, 0, 10]
    path2 = circle(90) * 0.25
    verts = triangulate(bridge(path1, path2))

    x = np.linspace(0, 10, 30)
    y = np.linspace(0, 10, 30)
    q = np.linspace(0, 1 * np.pi, 15)
    p = np.linspace(0, 2 * np.pi, 31)

    sphere_verts = triangulate(lift(lattice(q, p), to_spherical)) * t
    plane_verts = triangulate(lift(lattice(x, y)))

    r = partial(solid_colors, rgba=[1,0,0,1])
    g = partial(solid_colors, rgba=[0,1,0,1])
    b = partial(solid_colors, rgba=[0,0,1,1])
    k = partial(solid_colors, rgba=[0.8,0.0,0.8,1])

    xaxis = node(verts, r)
    yaxis = node(verts, g)
    zaxis = node(verts, b)
    plane = node(plane_verts, checkerboard)
    origin = node(sphere_verts, partial(checkerboard, dark=[0.5,0,0.7,1], light=[0.7,0,0.5,1]))

    for n in [xaxis, yaxis, zaxis, plane, origin]:
        n.position = [-5, -5, 0]

    xaxis.rotation = [0, 1, 0, np.pi / 2]
    yaxis.rotation = [1, 0, 0,-np.pi / 2]

    return scene("Plot axes", xaxis, yaxis, zaxis, origin, plane)



class Plot3D(object):
    def __init__(self):
        from functools import partial

        path1 = circle(90) * 0.25 + [0, 0, 10]
        path2 = circle(90) * 0.25
        verts = triangulate(bridge(path1, path2))

        x = np.linspace(0, 10, 30)
        y = np.linspace(0, 10, 30)
        q = np.linspace(0, 1 * np.pi, 16)
        p = np.linspace(0, 2 * np.pi, 31)

        sphere_verts = triangulate(lift(lattice(q, p), to_spherical))
        plane_verts = triangulate(lift(lattice(x, y)))

        r = partial(solid_colors, rgba=[1,0,0,1])
        g = partial(solid_colors, rgba=[0,1,0,1])
        b = partial(solid_colors, rgba=[0,0,1,1])
        k = partial(solid_colors, rgba=[0.8,0.0,0.8,1])

        xaxis = node(verts, r)
        yaxis = node(verts, g)
        zaxis = node(verts, b)
        plane = node(plane_verts, checkerboard)
        origin = node(sphere_verts, partial(checkerboard, dark=[0.5,0,0.7,1], light=[0.7,0,0.5,1]))

        for n in [xaxis, yaxis, zaxis, plane, origin]:
            n.position = [-5, -5, 0]

        xaxis.rotation = [0, 1, 0, np.pi / 2]
        yaxis.rotation = [1, 0, 0,-np.pi / 2]

        self.nodes = [xaxis, yaxis, zaxis, plane, origin]
        self.sphere_verts = tovert4(sphere_verts)

    def scene(self, t=1):
        self.nodes[-1].vertices = self.sphere_verts * t
        return scene("Plot axes", *self.nodes)



def run_mirage():
    import mirage

    plot3d = Plot3D()

    def handler(t):
        mirage.replace_scene(plot3d.scene(t))
        mirage.replace_scene(example_triangle(t))

    mirage.set_event_handler(handler)

    mirage.show([
        example_gridlines(),
        example_triangle(),
        example_cone(),
        example_cylinder(),
        example_helix(),
        example_sphere(),
        example_text_quad(),
        plot3d.scene()])



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
    assert(triangles.shape == (7, 8, 4, 3, 3))



if __name__ == "__main__":
    #test()

    import mirage
    n = mirage.Node()
    n.having(vertices=[1, 2, 3])
    run_mirage()

