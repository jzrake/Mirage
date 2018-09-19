import Cocoa




// Nice article on modern Cocoa apps:
// https://medium.com/@avaidyam/an-exercise-in-modern-cocoa-views-e88bbdea277f




// Code for opening files:
//        let openPanel = NSOpenPanel()
//        openPanel.showsHiddenFiles = false
//        openPanel.canChooseFiles = true
//        openPanel.canChooseDirectories = true
//        openPanel.allowedFileTypes = ["py"]
//
//        openPanel.beginSheetModal(for: window!) { response in
//            guard response.rawValue == NSFileHandlingPanelOKButton else {
//                return
//            }
//            let myUrl = openPanel.url
//        }




// ============================================================================
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    // ========================================================================
    static let LogMesssageFromPython = Notification.Name("LogMesssageFromPython")
    static let LogMesssageFromApp    = Notification.Name("LogMesssageFromApp")
    static let SceneListUpdate       = Notification.Name("SceneListUpdate")
    static let SceneReplace          = Notification.Name("SceneReplace")
    static let CurrentSceneChange    = Notification.Name("CurrentSceneChange")
    static let UserControlsChange    = Notification.Name("UserControlsChange")

    // weak var mainDocumentWindow: WindowController?

    // ========================================================================
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        // clearUserDefaults()

        PythonRuntime.initializeInterpreter()
        PythonRuntime.add(toSystemPath: URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages"))
        PythonRuntime.evalFile(Bundle.main.url(forResource: "startup", withExtension: "py"))

        watchedPaths = (UserDefaults.standard.array(forKey: "watchedPaths") as? [String]) ?? []

        NotificationCenter.default.addObserver(self, selector: #selector(userControlsChange), name: AppDelegate.UserControlsChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(currentSceneChange), name: AppDelegate.CurrentSceneChange, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        PythonRuntime.finalizeInterpreter()
        UserDefaults.standard.set(watchedPaths, forKey: "watchedPaths")
    }

    // ========================================================================
    private func clearUserDefaults()
    {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
    }

    // ========================================================================
    @objc func currentSceneChange(_ notification: Notification)
    {
        PythonRuntime.setCurrentSceneIndex(Int32(notification.object as! Int))
    }

    @objc func userControlsChange(_ notification: Notification)
    {
        guard let dict = notification.object as? [String : Variant] else {
            print("UserControlChange for non-double value")
            return
        }
        PythonRuntime.pass(dict)
    }

    // ========================================================================
    private var witness: Witness?

    var watchedPaths = [String]() {
        didSet {
            if watchedPaths.isEmpty {
                witness = nil
            }
            else {
                witness = Witness(paths: watchedPaths, flags: .FileEvents, latency: 0.1)
                { [weak self] events in
                    for e in events
                    {
                        self?.handleFileEvent(e)
                    }
                }
            }
        }
    }

    private func handleFileEvent(_ event: FileEvent)
    {
        let url = URL(fileURLWithPath: event.path)

        if url.pathExtension == "py"
        {
            NotificationCenter.default.post(name: AppDelegate.LogMesssageFromApp, object: "Reload " + url.path)
            PythonRuntime.evalFile(url)
        }
    }
}
