import Foundation




// ============================================================================
class TreeNode: NSObject
{
    var data: String
    var children: [TreeNode]

    init(data: String="", children: [TreeNode]=[])
    {
        self.data = data
        self.children = children
    }

    static func makeTestTree() -> TreeNode
    {
        return TreeNode(data: "Root", children: [TreeNode(data: "Child 1"),
                                                 TreeNode(data: "Child 2", children: [TreeNode(data: "Grand 1"),
                                                                                      TreeNode(data: "Grand 2")])])
    }
}




// ============================================================================
class SceneOutline: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource
{
    let root = TreeNode.makeTestTree()
    let dataCellId = NSUserInterfaceItemIdentifier(rawValue: "DataCell")

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
    {
        return !(item as! TreeNode).children.isEmpty
    }
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
    {
        return item == nil ? 1 : (item as! TreeNode).children.count
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
    {
        return item == nil ? root : (item as! TreeNode).children[index]
    }
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
    {
        var view: NSTableCellView?

        if let node = item as? TreeNode
        {
            view = outlineView.makeView(withIdentifier: dataCellId, owner: self) as? NSTableCellView

            if let textField = view?.textField
            {
                textField.stringValue = node.data
            }
        }
        return view
    }
}

