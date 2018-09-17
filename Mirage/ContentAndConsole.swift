import Foundation




// Article on using NSGridView:
// http://www.tothenew.com/blog/nsgridview-a-new-layout-container-for-macos/




// ============================================================================
class UserParameter
{
    enum ControlType {
        case slider
        case textBox
        case codeBox
    }
    var control: ControlType = .textBox
    var name: String = String()

    init(name: String, control: ControlType)
    {
        self.name = name
        self.control = control
    }

    func makeControl() -> NSView
    {
        switch control {
        case .slider:
            let slider = NSSlider()
            slider.identifier = NSUserInterfaceItemIdentifier(name)
            slider.target = self
            slider.action = #selector(sliderHander)
            return slider
        case .textBox: return NSTextField()
        case .codeBox: return NSTextField()
        }
    }

    func makeLabel() -> NSTextField
    {
        return NSTextField(labelWithString: name)
    }

    @objc func sliderHander(_ sender: NSSlider)
    {
        let dict: [String: Variant] = [sender.identifier!.rawValue : Variant.init(double: sender.doubleValue)];
        NotificationCenter.default.post(name: AppDelegate.UserParametersChange, object: dict)
    }
}




// ============================================================================
class UserParameterPanelController: NSViewController
{
    @IBOutlet var userParameterPanel: UserParameterPanel!

    override func viewDidLoad()
    {
        userParameterPanel.parameterList = [UserParameter(name: "Option 1", control: .textBox),
                                            UserParameter(name: "Option 2", control: .slider)]
    }
}




// ============================================================================
class UserParameterPanel: NSView
{
    private var grid: NSGridView!

    var parameterList = [UserParameter]()
    {
        didSet { setupGrid() }
    }

    override func layout()
    {
        grid.frame = bounds
    }

    private func setupGrid()
    {
        if grid != nil
        {
            grid.removeFromSuperview()
        }
        grid = NSGridView()

        for parameter in parameterList
        {
            grid.addRow(with: [parameter.makeLabel(), parameter.makeControl()])
        }
        grid.row(at: 0).topPadding = 20
        grid.row(at: parameterList.count - 1).bottomPadding = 20
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 0).leadingPadding = 20
        grid.column(at: 1).trailingPadding = 20
        grid.rowAlignment = .none
        grid.columnSpacing = 16
        grid.rowSpacing = 16
        grid.autoresizingMask = [.height, .width]
        grid.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        grid.setContentHuggingPriority(.defaultHigh, for: .vertical)
        addSubview(grid)
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
