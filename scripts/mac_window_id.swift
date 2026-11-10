import CoreGraphics
import Foundation
let pid = Int(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as! [[String: Any]]
var best: (Int, Double) = (0, 0)
for w in list where (w[kCGWindowOwnerPID as String] as? Int) == pid {
    let b = w[kCGWindowBounds as String] as! [String: Any]
    let area = (b["Width"] as! Double) * (b["Height"] as! Double)
    if (w[kCGWindowLayer as String] as? Int) == 0, area > best.1 { best = (w[kCGWindowNumber as String] as! Int, area) }
}
print(best.0)
