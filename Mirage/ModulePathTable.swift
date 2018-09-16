import Foundation



class ModulePathTable: NSViewController
{
    var urls = [URL]()
    let pathColumnId = NSUserInterfaceItemIdentifier(rawValue: "PathColumn")

    @IBOutlet weak var tableView: NSTableView!

    @IBAction func addPathAction(_ sender: NSButton)
    {
        urls.append(URL(fileURLWithPath: "/"))
        reloadDataKeepingSelection()
    }

    @IBAction func editAction(_ sender: NSTextField)
    {
        urls[tableView.selectedRow] = URL(fileURLWithPath: sender.stringValue)
        reloadDataKeepingSelection()
    }

    @IBAction func delete(_ sender: Any)
    {
        if tableView.selectedRow != -1
        {
            urls.remove(at: tableView.selectedRow)
            reloadDataKeepingSelection()
        }
    }
}



extension ModulePathTable: NSTableViewDelegate, NSTableViewDataSource
{
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool
    {
        return false
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        let view = tableView.makeView(withIdentifier: pathColumnId, owner: self) as! NSTableCellView
        view.textField?.stringValue = urls[row].path
        view.imageView?.image = statusImage(for: urls[row])
        return view
    }

    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return urls.count
    }

    private func reloadDataKeepingSelection()
    {
        let selected = tableView.selectedRowIndexes
        tableView.reloadData()
        tableView.selectRowIndexes(selected, byExtendingSelection: true)
    }

    private func statusImage(for url: URL) -> NSImage
    {
        let image: NSImage!
        var pathIsDirectory: ObjCBool = false
        let pathExists = FileManager.default.fileExists(atPath: url.path, isDirectory: &pathIsDirectory)

        if pathExists && pathIsDirectory.boolValue
        {
            image = NSImage(named: NSImage.Name.statusAvailable)
        }
        else
        {
            image = NSImage(named: NSImage.Name.statusUnavailable)
        }
        return image
    }
}
