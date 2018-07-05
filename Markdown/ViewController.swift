import Cocoa
import WebKit

class ViewController: NSViewController, WKNavigationDelegate {
	
	@IBOutlet weak var webView: WKWebView!
	@IBOutlet weak var gradView: NSView!
	
	var color = NSColor.white
	var ready = false
	
	func updateHTML() {
		guard ready else { return }
		guard let str = representedObject as? String else { return }
		do {
			let json = try JSONSerialization.data(withJSONObject: [str])
			if let json = String(data: json, encoding: .utf8) {
				self.webView.evaluateJavaScript("update(\(json)[0]);") { (result, error) in
					if let r = result { Swift.print(r) }
					if let e = error { Swift.print(e) }
				}
			}
		}
		catch {}
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		ready = true
		updateHTML()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.window?.backgroundColor = NSColor.white
		
		let gradient = CAGradientLayer()
		gradient.colors = [color.cgColor.copy(alpha: 0.0)!, color.cgColor]
		gradient.bounds = gradView.bounds
		gradView.layer = gradient
		
		let url = Bundle.main.url(forResource: "view", withExtension: "html")
		if let url = url {
			self.webView.loadFileURL(url, allowingReadAccessTo: url)
		}
	}
	
	override var representedObject: Any? {
		didSet { updateHTML() }
	}
}

class WindowController: NSWindowController {
	var color = NSColor.white
	
	override func windowDidLoad() {
		super.windowDidLoad()
		self.window?.backgroundColor = color
	}
}
