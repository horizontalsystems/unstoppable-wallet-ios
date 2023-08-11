import UIKit

enum Cex: String, CaseIterable {
    case binance

    var title: String {
        switch self {
        case .binance: return "Binance"
        }
    }

    var url: String {
        switch self {
        case .binance: return "https://www.binance.com"
        }
    }

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/cex-icons/\(rawValue)@\(scale)x.png"
    }

    var withdrawalAllowed: Bool {
        switch self {
        case .binance: return false
        }
    }

    func restoreViewController(returnViewController: UIViewController?) -> UIViewController {
        switch self {
        case .binance: return RestoreBinanceModule.viewController(returnViewController: returnViewController)
        }
    }

}
