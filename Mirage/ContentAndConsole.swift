import Foundation




// ============================================================================
class ContentAndConsole: NSViewController
{
    @IBOutlet weak var consoleView: NSView!
    @IBOutlet weak var metalView: MetalView!
    @IBOutlet var consoleOutput: NSTextView!

    @IBAction func toggleConsole(_ sender: NSButton)
    {
        consoleView.isHidden = !consoleView.isHidden
    }

    @IBAction func textFieldAction(_ sender: NSTextField)
    {
        PythonRuntime.execString(sender.stringValue)
    }

    override func viewDidLoad()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(consoleMessage), name: AppDelegate.ConsoleMesssage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(currentSceneChange), name: AppDelegate.CurrentSceneChange, object: nil)
    }

    @objc func currentSceneChange(_ notification: Notification)
    {
        metalView.representedObject = notification.object as? Int
    }

    @objc func consoleMessage(_ notification: Notification)
    {
        let message = notification.object as! String

        if message == "\n"
        {
            return
        }
        let font = NSFont(name: "Monaco", size: 10) as Any
        let color = message.contains("Error") ? NSColor.red : NSColor.black
        let attrs = [NSAttributedStringKey.font : font, NSAttributedStringKey.foregroundColor : color]
        consoleOutput.textStorage?.append(NSAttributedString(string: ">>> " + message + "\n", attributes: attrs))
        consoleOutput.scrollToEndOfDocument(self)
    }
}
