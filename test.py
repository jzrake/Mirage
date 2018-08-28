# import mirage
# import numpy as np

# scene1 = mirage.Scene("scene1")
# scene2 = mirage.Scene("scene2")

# mirage.show([scene1, scene2])


import mirage
import numpy as np



def triangle():
    return np.array([
        [-1.0, -1.0, 0.0, 0.0],
        [-1.0, +1.0, 0.0, 0.0],
        [+1.0, +1.0, 0.0, 0.0]])



def quad():
    return np.array([
        [-1.0, -1.0, 0.0, 0.0],
        [-1.0, +1.0, 0.0, 0.0],
        [+1.0, +1.0, 0.0, 0.0],
        [+1.0, -1.0, 0.0, 0.0]])



def grid(x, y):
    """Return line primitives describing a logically cartesian grid in the x-y
    plane, generated from the given lists of x and y coordinates.
    """
    vertices = list()

    for i in range(len(x) - 1):
        for j in range(len(y) - 1):
            vertices.append([x[i + 0], y[j], 0, 0])
            vertices.append([x[i + 1], y[j], 0, 0])
            vertices.append([x[i], y[j + 0], 0, 0])
            vertices.append([x[i], y[j + 1], 0, 0])

    for i in range(len(x) - 1):
        vertices.append([x[i + 0], y[-1], 0, 0])
        vertices.append([x[i + 1], y[-1], 0, 0])

    for j in range(len(y) - 1):
        vertices.append([x[-1], y[j + 0], 0, 0])
        vertices.append([x[-1], y[j + 1], 0, 0])

    return np.array(vertices)



def regular_polygon(sides):
    t = np.linspace(0, 2 * np.pi, sides, endpoint=False)
    vertices = list()

    for n in range(sides):

        x0 = np.cos(t[(n + 0) % sides])
        y0 = np.sin(t[(n + 0) % sides])
        x1 = np.cos(t[(n + 1) % sides])
        y1 = np.sin(t[(n + 1) % sides])

        vertices.append([ 0,  0, 0, 0])
        vertices.append([x0, y0, 0, 0])
        vertices.append([x1, y1, 0, 0])

    return np.array(vertices)



def polygonal_annulus(sides, inner, outer):
    t = np.linspace(0, 2 * np.pi, sides, endpoint=False)
    vertices = list()

    for n in range(sides):

        x0A = outer * np.cos(t[(n + 0) % sides])
        y0A = outer * np.sin(t[(n + 0) % sides])
        x1A = outer * np.cos(t[(n + 1) % sides])
        y1A = outer * np.sin(t[(n + 1) % sides])
        x0B = inner * np.cos(t[(n + 0) % sides])
        y0B = inner * np.sin(t[(n + 0) % sides])
        x1B = inner * np.cos(t[(n + 1) % sides])
        y1B = inner * np.sin(t[(n + 1) % sides])

        verts = np.array([
                [x0A, y0A, 0, 0],
                [x1A, y1A, 0, 0],
                [x1B, y1B, 0, 0],
                [x0B, y0B, 0, 0]])

        vertices += triangulate_quad(verts).tolist()

    return np.array(vertices)



def triangulate_quad(verts):
    assert(verts.shape[0] == 4)
    x0, x1, x2, x3 = verts[0], verts[1], verts[2], verts[3]
    xc = (x0 + x1 + x2 + x3) * 0.25
    return np.array([xc, x0, x1, xc, x1, x2, xc, x2, x3, xc, x3, x0])



def cycle_colors(num):
    colors = np.zeros([num, 4])

    for n in range(num):
        colors[n, n % 3] = 1

    return colors



def solid_colors(num):
    colors = np.zeros([num, 4])
    colors[:,3] = 1
    return colors



scene = mirage.Scene()
node1 = mirage.Node()
node2 = mirage.Node()
node3 = mirage.Node()

node1.position = [0, 0, +0.5]
node2.position = [0, 0, -0.5]
node3.position = [0, 0, 0]

node1.vertices = polygonal_annulus(12, 1.0, 1.5).flatten()
node2.vertices = triangle().flatten()
node3.vertices = grid(np.linspace(-2, 2, 64), np.linspace(-2, 2, 64)).flatten()

node1.colors = cycle_colors(len(node1.vertices) // 4).flatten()
node2.colors = cycle_colors(3).flatten()
node3.colors = solid_colors(len(node3.vertices) // 4).flatten()

node1.type = "triangle"
node2.type = "triangle"
node3.type = "line"

scene.nodes = [node1, node2, node3]

mirage.show([scene])
