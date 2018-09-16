import Foundation




class WindowController: NSWindowController
{
    var pythonSourceURL: URL?

    @IBAction func reload(_ sender: Any)
    {
        PythonRuntime.evalFile(self.pythonSourceURL)
    }

    @IBAction func openDocument(_ sender: AnyObject?)
    {
        let openPanel = NSOpenPanel()
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.allowedFileTypes = ["py"]

        openPanel.beginSheetModal(for: window!) { response in

            guard response.rawValue == NSFileHandlingPanelOKButton else {
                return
            }

            self.pythonSourceURL = openPanel.url
            PythonRuntime.evalFile(self.pythonSourceURL)
            self.window?.title = self.pythonSourceURL!.lastPathComponent
        }
    }
}
