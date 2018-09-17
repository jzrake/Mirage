import Cocoa




// Nice article on modern Cocoa apps:
// https://medium.com/@avaidyam/an-exercise-in-modern-cocoa-views-e88bbdea277f




// ============================================================================
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    static let ConsoleMesssage      = Notification.Name("ConsoleMessage")
    static let SceneListUpdate      = Notification.Name("SceneListUpdate")
    static let SceneReplace         = Notification.Name("SceneReplace")
    static let CurrentSceneChange   = Notification.Name("CurrentSceneChange")
    static let UserParametersChange = Notification.Name("UserParametersChange")

    weak var mainDocumentWindow: WindowController?
    var currentSceneIndex = 0

    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        PythonRuntime.initializeInterpreter()
        PythonRuntime.add(toSystemPath: URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages"))
        PythonRuntime.evalFile(Bundle.main.url(forResource: "startup", withExtension: "py"))
        mainDocumentWindow?.pythonSourceURL = UserDefaults.standard.url(forKey: "pythonSourceURL")

        NotificationCenter.default.addObserver(self, selector: #selector(userParameterChange), name: AppDelegate.UserParametersChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(currentSceneChange), name: AppDelegate.CurrentSceneChange, object: nil)
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

    @objc func currentSceneChange(_ notification: Notification)
    {
        currentSceneIndex = notification.object as! Int
    }

    @objc func userParameterChange(_ notification: Notification)
    {
        guard let dict = notification.object as? [String : Variant] else {
            print("UserParameterChange for non-double value")
            return
        }
        PythonRuntime.pass(dict)
    }
}
