#import "PythonRuntime.h"
#import "Python.h"
#include "pybind11/pybind11.h"
#include "pybind11/embed.h"
#include "pybind11/stl.h"
namespace py = pybind11;




class Scene
{
public:
    std::string name = "Scene";
};


static std::vector<Scene> mirageScenes;




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
    return int (mirageScenes.size());
}

+ (NSString*) sceneName: (int) sceneIndex
{
    if (sceneIndex >= 0 && sceneIndex < mirageScenes.size())
    {
        return [[NSString alloc] initWithUTF8String:mirageScenes[sceneIndex].name.data()];
    }
    return @"";
}

@end




// ============================================================================
PYBIND11_EMBEDDED_MODULE(mirage, m)
{
    py::class_<Scene>(m, "Scene")
    .def(py::init())
    .def_readwrite("name", &Scene::name);

    m.def("show", [] (const std::vector<Scene>& scenes)
    {
        mirageScenes = scenes;
        NSNotification* notification = [[NSNotification alloc] initWithName:@"SceneListUpdated" object:nil userInfo:nil];
        [NSNotificationCenter.defaultCenter postNotification:notification];
    });
}
