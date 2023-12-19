import ComponentKit
import UIKit

class PasteboardManager {
    var value: String? {
        UIPasteboard.general.string
    }

    func set(value: String) {
        UIPasteboard.general.string = value
    }
}

enum CopyHelper {
    static func copyAndNotify(value: String) {
        UIPasteboard.general.string = value
        HudHelper.instance.show(banner: .copied)
    }
}
