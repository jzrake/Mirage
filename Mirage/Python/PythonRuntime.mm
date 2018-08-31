#import "PythonRuntime.h"
#import "Python.h"
#include "pybind11/pybind11.h"
#include "pybind11/embed.h"
#include "pybind11/stl.h"
#include "pybind11/numpy.h"
namespace py = pybind11;




static std::vector<Scene> pythonScenes;




// ============================================================================
@implementation PythonRuntime

+ (void) initializeInterpreter
{
    py::initialize_interpreter();
}

+ (void) finalizeInterpreter
{
    py::finalize_interpreter();
}

+ (void) addToSystemPath: (NSURL*) directory
{
    auto sys = py::module::import("sys");
    sys.attr("path").attr("append")(std::string([directory.path UTF8String]));
}

+ (bool) evalFile: (NSURL*) filename
{
    try {
        py::eval_file([filename.path UTF8String]);
        [PythonRuntime postMessageToConsole:"Success"];
    }
    catch (const std::exception& e) {
        [PythonRuntime postMessageToConsole:e.what()];
        // std::cerr << e.what() << std::endl;
    }
    return true;
}

+ (int) numberOfScenes
{
    return int (pythonScenes.size());
}

+ (struct Scene*) scene: (int) atIndex
{
    if (atIndex >= 0 && atIndex < pythonScenes.size())
    {
        return &pythonScenes[atIndex];
    }
    return nil;
}

+ (void) postMessageToConsole: (std::string) message
{
    NSString* m = [[NSString alloc] initWithUTF8String:message.data()];
    NSNotification* notification = [[NSNotification alloc] initWithName:@"ConsoleMessage" object:m userInfo:nil];
    [NSNotificationCenter.defaultCenter postNotification:notification];
}

+ (void) postSceneListUpdated
{
    NSNotification* notification = [[NSNotification alloc] initWithName:@"SceneListUpdated" object:nil userInfo:nil];
    [NSNotificationCenter.defaultCenter postNotification:notification];
}
@end




// ============================================================================
PYBIND11_EMBEDDED_MODULE(mirage, m)
{
    using texture_t = py::array_t<unsigned char, py::array::c_style | py::array::forcecast>;

    pybind11::class_<Node>(m, "Node")
    .def(pybind11::init())
    .def_readwrite("vertices", &Node::vertices)
    .def_readwrite("colors", &Node::colors)
    .def_readwrite("x", &Node::x)
    .def_readwrite("y", &Node::y)
    .def_readwrite("z", &Node::z)
    .def_property("position", nullptr, &Node::setPosition)
    .def_property("type", &Node::getType, &Node::setType)
    .def_property("texture", nullptr, [] (Node& node, texture_t data)
    {
        auto buffer = std::vector<unsigned char> (data.data(0), data.data(0) + data.size());
        auto shape = std::vector<int> (data.shape(), data.shape() + data.ndim());
        node.setTexture (buffer, shape);
    });

    py::class_<Scene>(m, "Scene")
    .def(py::init())
    .def(py::init<std::string>())
    .def_readwrite("name", &Scene::name)
    .def_readwrite("nodes", &Scene::nodes);

    m.def("log", [] (std::string message)
    {
        [PythonRuntime postMessageToConsole:message];
    });

    m.def("show", [] (const std::vector<Scene>& scenes)
    {
        pythonScenes = scenes;
        [PythonRuntime postSceneListUpdated];
    });
}
