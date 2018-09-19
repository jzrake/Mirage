import Foundation




// ============================================================================
class UserControlPanelController: NSViewController
{
    @IBOutlet var userControlPanel: UserControlPanel!

    override func viewDidLoad()
    {
        userControlPanel.controlList = PythonRuntime.getUserControls()
    }
}




// ============================================================================
class UserControlPanel: NSView
{
    private var grid: NSGridView?

    var controlList = [UserControl]()
    {
        didSet { setupGrid() }
    }

    override func layout()
    {
        grid?.frame = bounds
    }

    private func setupGrid()
    {
        if grid != nil
        {
            grid!.removeFromSuperview()
        }
        grid = NSGridView()

        if (controlList.isEmpty)
        {
            return
        }
        for control in controlList
        {
            grid!.addRow(with: [makeLabel(for: control), makeControl(for: control)])
        }
        grid!.row(at: 0).topPadding = 20
        grid!.row(at: controlList.count - 1).bottomPadding = 20
        grid!.column(at: 0).xPlacement = .trailing
        grid!.column(at: 0).leadingPadding = 20
        grid!.column(at: 1).trailingPadding = 20
        grid!.rowAlignment = .none
        grid!.columnSpacing = 16
        grid!.rowSpacing = 16
        grid!.autoresizingMask = [.height, .width]
        grid!.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        grid!.setContentHuggingPriority(.defaultHigh, for: .vertical)
        addSubview(grid!)
    }

    private func makeControl(for control: UserControl) -> NSView
    {
        switch control.type {
        case .slider:
            let view = NSSlider()
            view.identifier = NSUserInterfaceItemIdentifier(control.name ?? "")
            view.target = self
            view.action = #selector(sliderHander)
            view.doubleValue = control.value?.asDouble() ?? 0.0
            return view
        case .text:
            let view = NSTextField()
            view.identifier = NSUserInterfaceItemIdentifier(control.name ?? "")
            view.target = self
            view.action = #selector(textHandler)
            view.stringValue = control.value?.asString() ?? ""
            return view
        }
    }

    private func makeLabel(for control: UserControl) -> NSTextField
    {
        return NSTextField(labelWithString: control.name ?? "")
    }

    @objc func sliderHander(_ sender: NSSlider)
    {
        let dict: [String: Variant] = [sender.identifier!.rawValue : Variant(double: sender.doubleValue)];
        NotificationCenter.default.post(name: AppDelegate.UserControlsChange, object: dict)
    }

    @objc func textHandler(_ sender: NSTextField)
    {
        let dict: [String: Variant] = [sender.identifier!.rawValue : Variant(string: sender.stringValue)];
        NotificationCenter.default.post(name: AppDelegate.UserControlsChange, object: dict)
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

    override func viewDidLoad()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(consoleMessage), name: AppDelegate.ConsoleMesssage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(currentSceneChange), name: AppDelegate.CurrentSceneChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneReplace), name: AppDelegate.SceneReplace, object: nil)
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

    @objc func sceneReplace(_ notification: Notification)
    {
        metalView.render()
    }

    func toggleConsoleShowing()
    {
        consoleDisclosureButton.performClick(nil)
    }
    
    func clearConsole()
    {
        consoleOutput.string = ""
    }
}
