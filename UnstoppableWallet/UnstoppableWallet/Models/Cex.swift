import UIKit

enum Cex: String, CaseIterable {
    case binance
    case coinzix

    var title: String {
        switch self {
        case .binance: return "Binance"
        case .coinzix: return "Coinzix"
        }
    }

    var url: String {
        switch self {
        case .binance: return "https://www.binance.com"
        case .coinzix: return "https://coinzix.com"
        }
    }

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/cex-icons/\(rawValue)@\(scale)x.png"
    }

    func restoreViewController(returnViewController: UIViewController?) -> UIViewController {
        switch self {
        case .binance: return RestoreBinanceModule.viewController(returnViewController: returnViewController)
        case .coinzix: return RestoreCoinzixModule.viewController(returnViewController: returnViewController)
        }
    }

}
