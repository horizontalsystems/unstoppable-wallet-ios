import UIKit
import ComponentKit

class PasteboardManager {

    var value: String? {
        UIPasteboard.general.string
    }

    func set(value: String) {
        UIPasteboard.general.string = value
    }

}

class CopyHelper {

    static func copyAndNotify(value: String) {
        UIPasteboard.general.string = value
        HudHelper.instance.show(banner: .copied)
    }

}
