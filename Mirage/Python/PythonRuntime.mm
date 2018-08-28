#import "PythonRuntime.h"
#import "Python.h"
#include "pybind11/pybind11.h"
#include "pybind11/embed.h"
#include "pybind11/stl.h"
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
    }
    catch (const std::exception& e) {
        std::cout << e.what() << std::endl;
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

@end




// ============================================================================
PYBIND11_EMBEDDED_MODULE(mirage, m)
{
    pybind11::class_<Node>(m, "Node")
    .def(pybind11::init())
    .def_readwrite("vertices", &Node::vertices)
    .def_readwrite("colors", &Node::colors)
    .def_readwrite("x", &Node::x)
    .def_readwrite("y", &Node::y)
    .def_readwrite("z", &Node::z)
    .def_property ("position", &Node::getPosition, &Node::setPosition)
    .def_property ("type", &Node::getType, &Node::setType);

    py::class_<Scene>(m, "Scene")
    .def(py::init())
    .def(py::init<std::string>())
    .def_readwrite("name", &Scene::name)
    .def_readwrite("nodes", &Scene::nodes);

    m.def("show", [] (const std::vector<Scene>& scenes)
    {
        pythonScenes = scenes;
        NSNotification* notification = [[NSNotification alloc] initWithName:@"SceneListUpdated" object:nil userInfo:nil];
        [NSNotificationCenter.defaultCenter postNotification:notification];
    });
}
