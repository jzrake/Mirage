import Cocoa



// ============================================================================
class WindowController: NSWindowController
{
    @IBAction func sidePanelButton(_ sender: NSButton)
    {
        let viewController = self.window?.contentViewController as? ViewController
        viewController?.leftRightSplitView!.subviews[0].isHidden = (sender.state.rawValue == 0)
    }

    @IBAction func refreshSource(_ sender: Any)
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
        }
    }
}




// ============================================================================
class ViewController: NSViewController, NSSplitViewDelegate
{
    @IBOutlet weak var topBottomSplitView: NSSplitView!
    @IBOutlet weak var leftRightSplitView: NSSplitView!
    @IBOutlet weak var sceneList: NSTableView!

    override func viewDidLoad()
    {
        super.viewDidLoad()

        
        let name = Notification.Name("SceneListUpdated")
        NotificationCenter.default.addObserver(self, selector: #selector(notify), name: name, object: nil)
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
        PythonEnvironment.evalFile((url as! NSURL) as URL!)
    }

    @objc func notify(_ notification: Notification)
    {
        let selectedRowIndexes = sceneList.selectedRowIndexes
        sceneList.reloadData()
        sceneList.selectRowIndexes(selectedRowIndexes, byExtendingSelection: true)
    }
}




// ============================================================================
extension ViewController: NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return Int(PythonEnvironment.numberOfScenes())
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
            cell.textField?.stringValue = PythonEnvironment.sceneName(Int32(row))
            return cell
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification)
    {
        print(notification)
    }
}
