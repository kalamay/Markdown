import Cocoa

class MarkdownParser {
    var mem:UnsafeMutablePointer<cmark_mem>!
    var parser:OpaquePointer!
    var extensions:UnsafeMutablePointer<cmark_llist>!
    
    convenience init() {
        self.init(withExtensions: ["table", "strikethrough", "autolink", "tagfilter"])
    }
    
    init(withExtensions ext:[String]) {
        mem = cmark_get_default_mem_allocator()
        if let p = cmark_parser_new_with_mem(CMARK_OPT_DEFAULT, mem) {
            var list:UnsafeMutablePointer<cmark_llist>!
            for name in ext {
                if let ext = cmark_find_syntax_extension(name) {
                    if cmark_parser_attach_syntax_extension(p, ext) == 1 {
                        list = cmark_llist_append(mem, list, UnsafeMutableRawPointer(ext))
                    }
                }
            }
            parser = p
            extensions = list
        }
    }
    
    deinit {
        cmark_parser_free(parser)
        cmark_llist_free(mem, extensions)
    }
    
    func parse(_ data: Data) -> MarkdownTree? {
        var tree:MarkdownTree?
        data.withUnsafeBytes {(bytes: UnsafePointer<Int8>)->Void in
            cmark_parser_feed(parser, bytes, data.count)
            if let doc = cmark_parser_finish(parser) {
                tree = MarkdownTree(doc, parser: self)
            }
        }
        return tree
    }
}

class MarkdownTree {
    var root:OpaquePointer!
    var parser:MarkdownParser
    
    init(_ root:OpaquePointer!, parser: MarkdownParser) {
        self.root = root
        self.parser = parser
    }
    
    deinit {
        cmark_node_free(root)
    }
    
    func renderHTML() -> String? {
        if let p = cmark_render_html_with_mem(root, CMARK_OPT_DEFAULT, parser.extensions, parser.mem) {
            return String(bytesNoCopy: p, length: strlen(p), encoding: .utf8, freeWhenDone: true)
        }
        return nil
    }
    
    func renderPlainText(width: Int32) -> String? {
        if let p = cmark_render_plaintext_with_mem(root, CMARK_OPT_DEFAULT, width, parser.mem) {
            return String(bytesNoCopy: p, length: strlen(p), encoding: .utf8, freeWhenDone: true)
        }
        return nil
    }
    
    func renderMan(width: Int32) -> String? {
        if let p = cmark_render_man_with_mem(root, CMARK_OPT_DEFAULT, width, parser.mem) {
            return String(bytesNoCopy: p, length: strlen(p), encoding: .utf8, freeWhenDone: true)
        }
        return nil
    }
    
    func renderLaTeX(width: Int32) -> String? {
        if let p = cmark_render_latex_with_mem(root, CMARK_OPT_DEFAULT, width, parser.mem) {
            return String(bytesNoCopy: p, length: strlen(p), encoding: .utf8, freeWhenDone: true)
        }
        return nil
    }
}
