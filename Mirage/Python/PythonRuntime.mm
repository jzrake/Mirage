#include <locale>
#include <codecvt>
#include <string>
#import "PythonRuntime.h"
#include "pybind11/pybind11.h"
#include "pybind11/embed.h"
#include "pybind11/stl.h"
#include "pybind11/numpy.h"
namespace py = pybind11;




// ============================================================================
#import <Cocoa/Cocoa.h>

class Image
{
public:
    Image (NSBitmapImageRep* image) : image (image) {}
    int getWidth() const { return int(image.pixelsWide); }
    int getHeight() const { return int(image.pixelsHigh); }
    NSBitmapImageRep* image;
};




static std::vector<Scene> pythonScenes;




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
    .def_property("rotation", nullptr, &Node::setRotation)
    .def_property("type", &Node::getType, &Node::setType)
    .def_property("texture", nullptr, [] (Node& node, const Image& image) { node.setImageTexture (image.image); });

    py::class_<Scene>(m, "Scene")
    .def(py::init())
    .def(py::init<std::string>())
    .def_readwrite("name", &Scene::name)
    .def_readwrite("nodes", &Scene::nodes);

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
