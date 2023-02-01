import UIKit
import MarketKit

extension Auditor {

    var logoUrl: String? {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/auditor-icons/\(name)@\(scale)x.png".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

}
