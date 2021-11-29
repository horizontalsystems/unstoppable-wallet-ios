import UIKit
import ComponentKit

class PasteboardManager: IPasteboardManager {

    var value: String? {
        return UIPasteboard.general.string
    }

    func set(value: String) {
        UIPasteboard.general.setValue(value, forPasteboardType: "public.plain-text")
    }

}

class CopyHelper {

    static func copyAndNotify(value: String) {
        UIPasteboard.general.setValue(value, forPasteboardType: "public.plain-text")
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
