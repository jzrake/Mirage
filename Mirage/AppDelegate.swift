import Cocoa




// Nice article on modern Cocoa apps:
// https://medium.com/@avaidyam/an-exercise-in-modern-cocoa-views-e88bbdea277f




// ============================================================================
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    static let ConsoleMesssage = Notification.Name("ConsoleMessage")
    static let SceneListUpdate = Notification.Name("SceneListUpdate")
    static let CurrentSceneChange = Notification.Name("CurrentSceneChange")

    weak var mainDocumentWindow: WindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        PythonRuntime.initializeInterpreter()
        PythonRuntime.add(toSystemPath: URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages"))
        PythonRuntime.evalFile(Bundle.main.url(forResource: "startup", withExtension: "py"))
        mainDocumentWindow?.pythonSourceURL = UserDefaults.standard.url(forKey: "pythonSourceURL")
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        PythonRuntime.finalizeInterpreter()
        UserDefaults.standard.set(mainDocumentWindow?.pythonSourceURL, forKey: "pythonSourceURL")
    }

    func clearUserDefaults()
    {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
    }
}
