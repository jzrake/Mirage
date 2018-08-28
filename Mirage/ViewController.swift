import Cocoa



// ============================================================================
class WindowController: NSWindowController
{
    @IBAction func sidePanelButton(_ sender: NSButton)
    {
        let viewController = self.window?.contentViewController as? ViewController
        viewController?.leftRightSplitView!.subviews[0].isHidden = (sender.state.rawValue == 0)
    }

    @IBAction func reload(_ sender: Any)
    {
        let viewController = self.window?.contentViewController as? ViewController
        viewController?.refreshSource()
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
            self.contentViewController?.representedObject = openPanel.url
            self.window?.title = openPanel.url!.lastPathComponent
        }
    }
}




// ============================================================================
class ViewController: NSViewController
{
    @IBOutlet weak var topBottomSplitView: NSSplitView!
    @IBOutlet weak var leftRightSplitView: NSSplitView!
    @IBOutlet weak var sceneList: NSTableView!
    @IBOutlet weak var metalView: MetalView!

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let name = Notification.Name("SceneListUpdated")
        NotificationCenter.default.addObserver(self, selector: #selector(sceneListUpdate), name: name, object: nil)
    }

    override var representedObject: Any?
    {
        didSet
        {
            refreshSource()
        }
    }

    func refreshSource()
    {
        guard let url = representedObject else { print("no source file"); return }
        PythonRuntime.evalFile((url as! NSURL) as URL?)
    }

    @objc func sceneListUpdate(_ notification: Notification)
    {
        let selectedRowIndexes = sceneList.selectedRowIndexes
        sceneList.reloadData()
        sceneList.selectRowIndexes(selectedRowIndexes, byExtendingSelection: true)
    }
}




// ============================================================================
extension ViewController: NSSplitViewDelegate
{
    func splitViewDidResizeSubviews(_ notification: Notification)
    {
        // This is a work-around for a bug (maybe in NSSplitView) where the
        // subview's resize method is not called, even though the split view
        // has updated the subview's size.
        self.metalView.updateSize()
    }
}




// ============================================================================
extension ViewController: NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return Int(PythonRuntime.numberOfScenes())
    }
}




// ============================================================================
extension ViewController: NSTableViewDelegate
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
        self.metalView.representedObject = i == -1 ? nil : i
    }
}
