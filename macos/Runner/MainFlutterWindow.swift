import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // ✅ Postavi početnu i minimalnu veličinu
    let initialSize = NSSize(width: 1440, height: 900)
    self.setContentSize(initialSize)
    self.minSize = NSSize(width: 1280, height: 800)
    
    // ✅ Centriraj prozor na ekranu
    self.center()
    
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}