import Foundation




// ============================================================================
class SceneOutline: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource
{
    @IBOutlet weak var outlineView: NSOutlineView!

    let dataCellId = NSUserInterfaceItemIdentifier(rawValue: "DataCell")

    override func viewDidLoad()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(sceneListUpdate), name: AppDelegate.SceneListUpdate, object: nil)
    }
    @objc func sceneListUpdate(_ notification: Notification)
    {
        outlineView.reloadData()
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
    {
        return false
    }
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
    {
        return Int(PythonRuntime.numberOfScenes())
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
    {
        return PythonRuntime.scene(Int32(index))
    }
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
    {
        var view: NSTableCellView?

        if let scene = item as? OpaquePointer
        {
            view = outlineView.makeView(withIdentifier: dataCellId, owner: self) as? NSTableCellView

            if let textField = view?.textField
            {
                textField.stringValue = SceneAPI.name(scene)
            }
        }
        return view
    }
    func outlineViewSelectionDidChange(_ notification: Notification)
    {
        NotificationCenter.default.post(name: AppDelegate.CurrentSceneChange,
                                        object: (notification.object as! NSOutlineView).selectedRow)
    }
}
