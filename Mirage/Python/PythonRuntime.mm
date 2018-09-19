#include <locale>
#include <codecvt>
#include <string>
#include "PythonRuntime.h"
#include "Variant.h"
#include "pybind11/pybind11.h"
#include "pybind11/embed.h"
#include "pybind11/stl.h"
#include "pybind11/numpy.h"
namespace py = pybind11;




// ============================================================================
static std::vector<Scene> pythonScenes;
static py::object pythonEventHandler;
static py::object pythonControlsCallback;
static int currentSceneIndex = -1;

static py::dict variantDictionaryToPython(NSDictionary* dict);
static Node nodeHaving(const Node& node, py::kwargs kwargs);
static Node nodeFrom(py::kwargs kwargs);
static UserControlCpp userControlFrom(py::kwargs kwargs);
static void userParameterSetValue(UserControlCpp& p, py::object value);




// ============================================================================
@implementation PythonRuntime

+ (void) initializeInterpreter
{
    NSURL* python37 = [[NSBundle mainBundle] URLForResource:@"python37" withExtension:nil];
    NSURL* dynload = [python37 URLByAppendingPathComponent:@"lib-dynload"];
    NSURL* zipfile = [python37 URLByAppendingPathComponent:@"python37.zip"];
    NSString* pythonPath = [@[dynload.path, zipfile.path] componentsJoinedByString:@":"];

    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    std::wstring pythonPathWide = converter.from_bytes(pythonPath.UTF8String);

    Py_SetPythonHome(L"");
    Py_SetPath(pythonPathWide.data());

    pythonEventHandler = py::none();
    pythonControlsCallback = py::none();

    py::initialize_interpreter();
}

+ (void) finalizeInterpreter
{
    pythonEventHandler = py::object();
    pythonControlsCallback = py::object();

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
        // [PythonRuntime postMessageToConsole:"Success"];
    }
    catch (const std::exception& e) {
        [PythonRuntime postMessageToConsole:e.what()];
        // std::cerr << e.what() << std::endl;
    }
    return true;
}

+ (bool) evalString: (NSString*) expression
{
    try {
        py::eval([expression UTF8String]);
    }
    catch (const std::exception& e) {
        [PythonRuntime postMessageToConsole:e.what()];
    }
    return true;
}

+ (bool) execString: (NSString*) expression
{
    try {
        py::exec([expression UTF8String]);
    }
    catch (const std::exception& e) {
        [PythonRuntime postMessageToConsole:e.what()];
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

+ (struct Scene*) currentScene
{
    return currentSceneIndex == -1 ? nullptr : &pythonScenes[currentSceneIndex];
}

+ (void) setCurrentSceneIndex: (int) index
{
    currentSceneIndex = index;
}

+ (void) passDictionary: (NSDictionary*) dict
{
    try {
        pythonEventHandler(variantDictionaryToPython(dict));
    }
    catch (std::exception& e) {
        [PythonRuntime postMessageToConsole:e.what()];
    }
}

+ (NSArray<UserControl*>*) getUserControls
{
    try {
        auto controls = pythonControlsCallback().cast<std::vector<UserControlCpp>>();
        NSMutableArray<UserControl*>* objcControls = [[NSMutableArray<UserControl*> alloc] init];

        for (const auto& c : controls)
            [objcControls addObject:c.objc];
        return objcControls;
    }
    catch (const std::exception& e) {
        [PythonRuntime postMessageToConsole:e.what()];
        return @[];
    }
}

+ (void) postMessageToConsole: (std::string) message
{
    NSString* m = [[NSString alloc] initWithUTF8String:message.data()];
    NSNotification* notification = [[NSNotification alloc] initWithName:@"LogMesssageFromPython" object:m userInfo:nil];
    [NSNotificationCenter.defaultCenter postNotification:notification];
}

+ (void) postSceneListUpdated
{
    NSNotification* notification = [[NSNotification alloc] initWithName:@"SceneListUpdate" object:nil userInfo:nil];
    [NSNotificationCenter.defaultCenter postNotification:notification];
}

+ (void) postSceneReplaced: (std::string) name
{
    NSString* m = [[NSString alloc] initWithUTF8String:name.data()];
    NSNotification* notification = [[NSNotification alloc] initWithName:@"SceneReplace" object:m userInfo:nil];
    [NSNotificationCenter.defaultCenter postNotification:notification];
}
@end




// ============================================================================
using array_t = py::array_t<float, py::array::c_style | py::array::forcecast>;

py::dict variantDictionaryToPython(NSDictionary* dict)
{
    auto pythonDict = py::dict();

    for (NSString* key in dict)
    {
        py::str k = std::string([key UTF8String]);
        Variant* v = dict[key];

        switch (v.type)
        {
            case integerVariant: pythonDict[k] = v.asInteger; break;
            case doubleVariant:  pythonDict[k] = v.asDouble; break;
            case stringVariant:  pythonDict[k] = std::string([v.asString UTF8String]); break;
        }
    }
    return pythonDict;
}

Node nodeHaving(const Node& node, py::kwargs kwargs)
{
    py::object n = py::cast(node);

    for (auto k : kwargs)
        py::setattr(n, k.first, k.second);
    return n.cast<Node>();
}

Node nodeFrom(py::kwargs kwargs)
{
    return nodeHaving(Node(), kwargs);
}

UserControlCpp userControlFrom(py::kwargs kwargs)
{
    UserControlCpp p;
    py::object q = py::cast(p);

    for (auto k : kwargs)
        py::setattr(q, k.first, k.second);
    return q.cast<UserControlCpp>();
}

void userParameterSetValue(UserControlCpp& p, py::object value)
{
    try { p.setDoubleValue(value.cast<double>()); return; } catch (...) {}
    try { p.setStringValue(value.cast<std::string>()); return; } catch (...) {}
    throw std::invalid_argument("value must have type str or float");
}




// ============================================================================
PYBIND11_EMBEDDED_MODULE(mirage, m)
{
    using texture_t = py::array_t<unsigned char, py::array::c_style | py::array::forcecast>;

    py::class_<Node>(m, "Node")
    .def(py::init())
    .def(py::init(&nodeFrom))
    .def_property("primitive", nullptr, &Node::setType)
    .def_property("vertices",  nullptr, [] (Node& node, array_t data) { node.setVertices(data.data(0), data.size()); })
    .def_property("colors",    nullptr, [] (Node& node, array_t data) { node.setColors(data.data(0), data.size()); })
    .def_property("texture",   nullptr, &Node::setImageTexture)
    .def_property("position",  nullptr, &Node::setPosition)
    .def_property("rotation",  nullptr, &Node::setRotation)
    .def("with_vertices", [] (Node& node, array_t data) { return node.withVertices(data.data(0), data.size()); })
    .def("with_colors",   [] (Node& node, array_t data) { return node.withColors(data.data(0), data.size()); })
    .def("with_texture",  &Node::withImageTexture)
    .def("with_position", &Node::withPosition)
    .def("with_rotation", &Node::withRotation)
    .def("having", nodeHaving);

    py::class_<UserControlCpp>(m, "Control")
    .def(py::init())
    .def(py::init(&userControlFrom))
    .def_property("control", nullptr, &UserControlCpp::setControl)
    .def_property("name", nullptr, &UserControlCpp::setName)
    .def_property("value", nullptr, &userParameterSetValue);

    py::class_<Scene>(m, "Scene")
    .def(py::init())
    .def(py::init<std::string>())
    .def_readwrite("name", &Scene::name)
    .def_readwrite("nodes", &Scene::nodes);
    // .def_readwrite("parameters", &Scene::parameters);

    py::class_<Image>(m, "Image")
    .def_property_readonly("width", &Image::getWidth)
    .def_property_readonly("height", &Image::getHeight);

    m.def("log", [] (py::object obj)
    {
        [PythonRuntime postMessageToConsole:py::str(obj)];
    });

    m.def("show", [] (const std::vector<Scene>& scenes)
    {
        pythonScenes = scenes;
        [PythonRuntime postSceneListUpdated];
    });

    m.def("show", [] (const Scene& scene)
    {
        for (auto& s : pythonScenes)
        {
            if (s.name == scene.name)
            {
                s = scene;
                [PythonRuntime postSceneReplaced:scene.name];
                return;
            }
        }
        pythonScenes.push_back(scene);
        [PythonRuntime postSceneListUpdated];
    });

    m.def("set_event_handler", [] (py::object handler) { pythonEventHandler = handler; });
    m.def("set_controls_callback", [] (py::object callback) { pythonControlsCallback = callback; });
    m.def("current_scene_name", [] () -> py::object
    {
        if (currentSceneIndex == -1)
            return py::none();
        return py::str(pythonScenes[currentSceneIndex].name);
    });

    m.def("text", [] (std::string str)
    {
        NSFont* font = [NSFont fontWithName:@"Monaco" size:72];
        NSMutableParagraphStyle* paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.lineBreakMode = NSLineBreakByClipping;

        NSAttributedString* A = [[NSAttributedString alloc]
                                 initWithString:[[NSString alloc] initWithUTF8String:str.data()]
                                 attributes:@{NSFontAttributeName: font,
                                              NSParagraphStyleAttributeName: paragraph}];

        NSTextField* L = [[NSTextField alloc] init];
        L.attributedStringValue = A;
        L.bezeled         = NO;
        L.editable        = NO;
        L.drawsBackground = NO;
        L.frame = NSMakeRect(0, 0, A.size.width, A.size.height);

        NSBitmapImageRep* image = [L bitmapImageRepForCachingDisplayInRect:L.bounds];
        [L cacheDisplayInRect:L.bounds toBitmapImageRep:image];
        return Image (image);
    });
}
