import Cocoa




// ============================================================================
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        PythonEnvironment.initializeInterpreter()
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        PythonEnvironment.finalizeInterpreter()
    }
}
