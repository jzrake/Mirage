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

+ (NSString*) sceneName: (int) sceneIndex
{
    if (sceneIndex >= 0 && sceneIndex < pythonScenes.size())
    {
        return [[NSString alloc] initWithUTF8String:pythonScenes[sceneIndex].name.data()];
    }
    return @"";
}

+ (struct Node*) rootNode: (int) sceneIndex
{
    if (sceneIndex >= 0 && sceneIndex < pythonScenes.size())
    {
        return &pythonScenes[sceneIndex].root;
    }
    return nil;
}

+ (id<MTLBuffer>) nodeVertexData: (struct Node*) node
{
    return nil;
}

+ (id<MTLBuffer>) nodeColorsData: (struct Node*) node
{
    return nil;
}

@end




// ============================================================================
PYBIND11_EMBEDDED_MODULE(mirage, m)
{
    py::class_<Scene>(m, "Scene")
    .def(py::init())
    .def(py::init<std::string>())
    .def_readwrite("name", &Scene::name);

    m.def("show", [] (const std::vector<Scene>& scenes)
    {
        pythonScenes = scenes;
        NSNotification* notification = [[NSNotification alloc] initWithName:@"SceneListUpdated" object:nil userInfo:nil];
        [NSNotificationCenter.defaultCenter postNotification:notification];
    });
}
