import UIKit
import ComponentKit

class PasteboardManager {

    var value: String? {
        UIPasteboard.general.string
    }

    func set(value: String) {
        UIPasteboard.general.setValue(value, forPasteboardType: "public.plain-text")
    }

}

class CopyHelper {

    static func copyAndNotify(value: String) {
        UIPasteboard.general.setValue(value, forPasteboardType: "public.plain-text")
        HudHelper.instance.show(banner: .copied)
    }

}
