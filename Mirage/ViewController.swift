import Cocoa




// ============================================================================
//class WindowController: NSWindowController
//{
//    @IBAction func sidePanelButtonAction(_ sender: NSButton)
//    {
//        (self.contentViewController as! ViewController).toggleSidebar(self)
//    }
//
//    @IBAction func reload(_ sender: Any)
//    {
//        (self.contentViewController as! ViewController).reloadSource()
//    }
//
//    @IBAction func reloadSource(_ sender: Any)
//    {
//        (self.contentViewController as! ViewController).reloadSource()
//    }
//
//    @IBAction func openDocument(_ sender: AnyObject?)
//    {
//        let openPanel = NSOpenPanel()
//        openPanel.showsHiddenFiles = false
//        openPanel.canChooseFiles = true
//        openPanel.canChooseDirectories = true
//        openPanel.allowedFileTypes = ["py"]
//
//        openPanel.beginSheetModal(for: window!) { response in
//            guard response.rawValue == NSFileHandlingPanelOKButton else {
//                return
//            }
//            self.contentViewController?.representedObject = openPanel.url
//            self.window?.title = openPanel.url!.lastPathComponent
//        }
//    }
//}




// ============================================================================
class ViewController: NSSplitViewController
{
    var sceneListViewController: SceneListViewController?
    var contentViewController: ContentViewController?
    var consoleViewController: ConsoleViewController?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let consoleContentController = splitViewItems[1].viewController as? NSSplitViewController
        self.sceneListViewController = splitViewItems[0].viewController as? SceneListViewController
        self.contentViewController = consoleContentController?.splitViewItems[0].viewController as? ContentViewController
        self.consoleViewController = consoleContentController?.splitViewItems[1].viewController as? ConsoleViewController

        (splitViewItems[0].viewController as! SceneListViewController).currentSceneIndexSetter =
        {
            sceneIndex in
            (self.contentViewController?.view as! MetalView).representedObject = sceneIndex
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("SceneReplaced"), object: nil, queue: nil, using:
        {
            [weak self] obj in
            (self?.contentViewController?.view as! MetalView).render()
        })
    }


    override var representedObject: Any?
    {
        didSet
        {
            reloadSource()
        }
    }

    func reloadSource()
    {
        guard let url = representedObject as? URL else { return }
        PythonRuntime.evalFile(url)
    }
}




// ============================================================================
class SceneListViewController: NSViewController
{
    @IBOutlet weak var sceneList: NSTableView!
    var currentSceneIndexSetter:((Int) -> Void)?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let name = Notification.Name("SceneListUpdated")
        NotificationCenter.default.addObserver(self, selector: #selector(sceneListUpdate), name: name, object: nil)
    }

    @objc func sceneListUpdate(_ notification: Notification)
    {
        let selectedRowIndexes = sceneList.selectedRowIndexes
        sceneList.reloadData()
        sceneList.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)

        if (sceneList.numberOfRows == 0)
        {
            currentSceneIndexSetter! (-1)
        }
        else if (selectedRowIndexes.isEmpty)
        {
            sceneList.selectRowIndexes([0], byExtendingSelection: false)
        }
    }
}




// ============================================================================
extension SceneListViewController: NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return Int(PythonRuntime.numberOfScenes())
    }
}




// ============================================================================
extension SceneListViewController: NSTableViewDelegate
{
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        let cellIdentifier = NSUserInterfaceItemIdentifier("C1")
        
        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
        {
            let scene = PythonRuntime.scene(Int32(row))
            cell.textField?.stringValue = SceneAPI.name(scene)
            return cell
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification)
    {
        let i = sceneList.selectedRow
        currentSceneIndexSetter! (i)
    }
}




// ============================================================================
class ContentViewController: NSViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
}




// ============================================================================
class ConsoleViewController: NSViewController
{
    @IBOutlet var consoleOutput: NSTextView!

    @IBAction func sliderMoved(_ sender: NSSlider)
    {
        PythonRuntime.handleEvent(sender.doubleValue)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        let name = Notification.Name("ConsoleMessage")
        NotificationCenter.default.addObserver(self, selector: #selector(consoleMessage), name: name, object: nil)
    }

    @objc func consoleMessage(_ notification: Notification)
    {
        let message = notification.object as! String
        let font = NSFont(name: "Monaco", size: 10) as Any
        let color = message.contains("Error") ? NSColor.red : NSColor.black
        let attrs = [NSAttributedStringKey.font : font, NSAttributedStringKey.foregroundColor : color]
        consoleOutput.textStorage?.append(NSAttributedString(string: ">>> " + message + "\n", attributes: attrs))
        consoleOutput.scrollToEndOfDocument(self)
    }
}
