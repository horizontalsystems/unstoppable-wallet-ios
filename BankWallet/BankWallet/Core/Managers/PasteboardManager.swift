import UIKit

class PasteboardManager: IPasteboardManager {

    var value: String? {
        return UIPasteboard.general.string
    }

    func set(value: String) {
        UIPasteboard.general.setValue(value, forPasteboardType: "public.plain-text")
    }

}
