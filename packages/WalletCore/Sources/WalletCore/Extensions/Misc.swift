import UIKit

extension String {
    var headerImageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/header-images/\(self)@\(scale)x.png"
    }

    var fiatImageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/fiat-icons/\(self)@\(scale)x.png"
    }
}
