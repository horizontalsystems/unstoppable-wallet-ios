import MarketKit
import UIKit

extension Analytics.Audit {
    static func logoUrl(name: String) -> String? {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/auditor-icons/\(name)@\(scale)x.png".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}
