import Foundation




class WindowController: NSWindowController
{
    @IBAction func toggleConsole(_ sender: AnyObject?)
    {
        ((contentViewController as! NSSplitViewController).splitViewItems[1].viewController as! ContentAndConsole).toggleConsoleShowing()
    }

    @IBAction func clearConsole(_ sender: AnyObject?)
    {
        ((contentViewController as! NSSplitViewController).splitViewItems[1].viewController as! ContentAndConsole).clearConsole()
    }
}




class SplitViewController: NSSplitViewController
{
}
