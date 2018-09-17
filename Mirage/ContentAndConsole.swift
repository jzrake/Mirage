import Foundation




// Article on using NSGridView:
// http://www.tothenew.com/blog/nsgridview-a-new-layout-container-for-macos/




// ============================================================================
class PropertyPanel: NSView
{
    let stack = NSStackView()

    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        self.commonInit()
    }

    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
        self.commonInit()
    }

    private func commonInit()
    {
        for _ in 0...4
        {
            let slider = NSSlider()
            slider.target = self
            slider.action = #selector(handler)
            slider.identifier = NSUserInterfaceItemIdentifier(rawValue: "Thing")
            stack.addArrangedSubview(slider)
        }
        stack.orientation = NSUserInterfaceLayoutOrientation.vertical
        addSubview(stack)
    }

    override func layout() {
        stack.frame = bounds
    }

    @objc func handler(_ sender: NSSlider)
    {
    }
}




// ============================================================================
class ContentAndConsole: NSViewController
{
    @IBOutlet weak var consoleDisclosureButton: NSButton!
    @IBOutlet weak var consoleView: NSView!
    @IBOutlet weak var metalView: MetalView!
    @IBOutlet var consoleOutput: NSTextView!

    @IBAction func toggleConsole(_ sender: AnyObject?)
    {
        consoleView.animator().isHidden = !consoleView.isHidden
    }

    @IBAction func textFieldAction(_ sender: NSTextField)
    {
        PythonRuntime.execString(sender.stringValue)
    }

    // let propertyPanel = PropertyPanel()

    override func viewDidLoad()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(consoleMessage), name: AppDelegate.ConsoleMesssage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(currentSceneChange), name: AppDelegate.CurrentSceneChange, object: nil)

        // view.addSubview(propertyPanel)
    }

    override func viewDidLayout()
    {
        // propertyPanel.frame = NSRect(x: 50, y: 50, width: 200, height: 200)
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

    func toggleConsoleShowing()
    {
        consoleDisclosureButton.performClick(nil)
    }
}
