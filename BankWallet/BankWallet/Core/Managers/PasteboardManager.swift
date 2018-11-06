import UIKit

class PasteboardManager: IPasteboardManager {

    func set(value: String) {
        UIPasteboard.general.setValue(value, forPasteboardType: "public.plain-text")
    }

}
