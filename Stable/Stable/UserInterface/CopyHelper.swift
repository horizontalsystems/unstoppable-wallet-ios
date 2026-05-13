import UIKit

enum CopyHelper {
    static func copyAndNotify(value: String) {
        UIPasteboard.general.string = value
        // HudHelper.instance.show(banner: .copied)
    }
}
