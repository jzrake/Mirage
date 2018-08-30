import Cocoa




// ============================================================================
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        PythonRuntime.initializeInterpreter()
        PythonRuntime.add(toSystemPath: URL(fileURLWithPath: "/Users/jzrake/Work/Mirage"))
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        PythonRuntime.finalizeInterpreter()
    }
}
