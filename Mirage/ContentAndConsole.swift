import Foundation




// ============================================================================
class ContentAndConsole: NSViewController
{
    @IBOutlet weak var consoleView: NSView!

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
        let name = Notification.Name("ConsoleMessage")
        NotificationCenter.default.addObserver(self, selector: #selector(consoleMessage), name: name, object: nil)
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
