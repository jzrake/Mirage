import Foundation




// ============================================================================
class UserParameterPanelController: NSViewController
{
    @IBOutlet var userParameterPanel: UserParameterPanel!

    override func viewDidLoad()
    {
        guard let scene = PythonRuntime.currentScene() else { return }
        userParameterPanel.parameterList = SceneAPI.userParameters(scene)
    }
}




// ============================================================================
class UserParameterPanel: NSView
{
    private var grid: NSGridView?

    var parameterList = [UserParameter]()
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

        if (parameterList.isEmpty)
        {
            return
        }
        for parameter in parameterList
        {
            grid!.addRow(with: [makeLabel(for: parameter), makeControl(for: parameter)])
        }
        grid!.row(at: 0).topPadding = 20
        grid!.row(at: parameterList.count - 1).bottomPadding = 20
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

    private func makeControl(for parameter: UserParameter) -> NSView
    {
        switch parameter.control() {
        case .slider:
            let control = NSSlider()
            control.identifier = NSUserInterfaceItemIdentifier(parameter.name())
            control.target = self
            control.action = #selector(sliderHander)
            return control
        case .text:
            let control = NSTextField()
            control.identifier = NSUserInterfaceItemIdentifier(parameter.name())
            control.target = self
            control.action = #selector(textHandler)
            return control
        }
    }

    private func makeLabel(for parameter: UserParameter) -> NSTextField
    {
        return NSTextField(labelWithString: parameter.name())
    }

    @objc func sliderHander(_ sender: NSSlider)
    {
        let dict: [String: Variant] = [sender.identifier!.rawValue : Variant(double: sender.doubleValue)];
        NotificationCenter.default.post(name: AppDelegate.UserParametersChange, object: dict)
    }

    @objc func textHandler(_ sender: NSTextField)
    {
        let dict: [String: Variant] = [sender.identifier!.rawValue : Variant(string: sender.stringValue)];
        NotificationCenter.default.post(name: AppDelegate.UserParametersChange, object: dict)
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
}
