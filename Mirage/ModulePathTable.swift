import Foundation



class ModulePathTable: NSViewController
{
    let pathColumnId = NSUserInterfaceItemIdentifier(rawValue: "PathColumn")
    let app = NSApp.delegate as! AppDelegate

    @IBOutlet weak var tableView: NSTableView!

    @IBAction func addPathAction(_ sender: NSButton)
    {
        app.watchedPaths.append("/")

        reloadDataKeepingSelection()
    }

    @IBAction func editAction(_ sender: NSTextField)
    {
        app.watchedPaths[tableView.selectedRow] = sender.stringValue
        reloadDataKeepingSelection()
    }

    @IBAction func delete(_ sender: Any)
    {
        if tableView.selectedRow != -1
        {
            app.watchedPaths.remove(at: tableView.selectedRow)
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
        let urls = app.watchedPaths
        let view = tableView.makeView(withIdentifier: pathColumnId, owner: self) as! NSTableCellView
        view.textField?.stringValue = urls[row]
        view.imageView?.image = NSWorkspace.shared.icon(forFile: urls[row]) //statusImage(for: urls[row])
        return view
    }

    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return app.watchedPaths.count
    }

    private func reloadDataKeepingSelection()
    {
        let selected = tableView.selectedRowIndexes
        tableView.reloadData()
        tableView.selectRowIndexes(selected, byExtendingSelection: true)
    }

    private func statusImage(for path: String) -> NSImage
    {
        let image: NSImage!
        var pathIsDirectory: ObjCBool = false
        let pathExists = FileManager.default.fileExists(atPath: path, isDirectory: &pathIsDirectory)

        if pathExists && pathIsDirectory.boolValue
        {
            image = NSImage(named: NSImage.Name.folder)
        }
        else if pathExists
        {
            image = NSImage(named: NSImage.Name.multipleDocuments)
        }
        else
        {
            image = NSImage(named: NSImage.Name.statusUnavailable)
        }
        return image
    }
}
