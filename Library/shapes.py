

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



if __name__ == "__main__":
    for s in [
        example_gridlines(),
        example_triangle(),
        example_cone(),
        example_cylinder(),
        example_helix(),
        example_sphere(),
        example_text_quad(),
        example_plot_axes()]:

        mirage.show(s)

