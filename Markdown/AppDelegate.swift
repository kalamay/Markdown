import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		core_extensions_ensure_registered()
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
	}
}
