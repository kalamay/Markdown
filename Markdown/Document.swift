import Cocoa
import Dispatch

class Document: NSDocument {
	var parser:MarkdownParser
	var tree:MarkdownTree?
	var html:String?
	var event:DispatchSourceFileSystemObject?
	var view:ViewController?
	
	override init() {
		parser = MarkdownParser()
		super.init()
	}
	
	deinit {
		event?.cancel()
	}
	
	override var isInViewingMode: Bool {
		return true
	}
	
	override func makeWindowControllers() {
		let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
		self.addWindowController(windowController)
		let vc = windowController.contentViewController as! ViewController
		vc.representedObject = html
		view = vc
	}
	
	override func read(from data: Data, ofType typeName: String) throws {
		try read(from: data, atURL: nil, ofType: typeName)
	}
	
	override func read(from url: URL, ofType typeName: String) throws {
		try read(from: Data(contentsOf: url), atURL: url, ofType: typeName)
	}
	
	func read(from data: Data, atURL url: URL?, ofType typeName: String) throws {
		if let t = parser.parse(data), let s = t.renderHTML() {
			tree = t
			html = s
			watch(url: url)
		}
		else {
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}
	
	func watch(url: URL?) {
		event?.cancel()
		event = nil
		
		guard let u = url else { return }
		guard u.isFileURL else { return }
		
		let fd = Darwin.open(u.path, O_RDONLY)
		guard fd >= 0 else { return }
		
		event = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: fd,
			eventMask: [.write, .link])
		event?.setEventHandler {
			DispatchQueue.main.async {
				[weak self] in
				self?.sourceChanged(atURL: u)
			}
		}
		event?.setCancelHandler {
			Darwin.close(fd)
		}
		event?.resume()
	}
	
	func sourceChanged(atURL url: URL) {
		guard let ev = event else { return }
		let m = ev.data
		
		do {
			let data = try Data(contentsOf: url)
			if let t = parser.parse(data), let s = t.renderHTML() {
				tree = t
				html = s
				if let vc = view {
					vc.representedObject = html
				}
			}
		}
		catch {}
		
		if m.contains(.link) {
			watch(url: url)
		}
	}
}
