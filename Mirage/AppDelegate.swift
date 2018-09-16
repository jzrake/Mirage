import Cocoa




// ============================================================================
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    static let ConsoleMesssage = Notification.Name("ConsoleMessage")
    static let SceneListUpdate = Notification.Name("SceneListUpdate")
    static let CurrentSceneChange = Notification.Name("CurrentSceneChange")

    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        PythonRuntime.initializeInterpreter()
        PythonRuntime.evalFile(Bundle.main.url(forResource: "startup", withExtension: "py"))
        PythonRuntime.add(toSystemPath: URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages"))
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        PythonRuntime.finalizeInterpreter()
    }
}
