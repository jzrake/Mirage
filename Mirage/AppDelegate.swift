import Cocoa




// ============================================================================
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        PythonRuntime.initializeInterpreter()
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        PythonRuntime.finalizeInterpreter()
    }
}
