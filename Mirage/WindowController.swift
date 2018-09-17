import Foundation




class WindowController: NSWindowController
{
    var pythonSourceURL: URL?
    {
        didSet {
            if pythonSourceURL != nil
            {
                PythonRuntime.evalFile(self.pythonSourceURL)
                window?.title = pythonSourceURL!.lastPathComponent
            }
        }
    }

    @IBAction func reload(_ sender: Any)
    {
        PythonRuntime.evalFile(self.pythonSourceURL)
    }

    @IBAction func toggleConsole(_ sender: AnyObject?)
    {
        ((contentViewController as! NSSplitViewController).splitViewItems[1].viewController as! ContentAndConsole).toggleConsoleShowing()
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
        }
    }

    override func windowDidLoad()
    {
        super.windowDidLoad()
        (NSApp.delegate as! AppDelegate).mainDocumentWindow = self
    }
}



class SplitViewController: NSSplitViewController
{
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
