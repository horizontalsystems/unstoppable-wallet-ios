import Foundation
import UIKit
import ComponentKit
import HUD

extension HudHelper {

    enum BannerType {
        case addedToWatchlist
        case removedFromWatchlist
        case addedToWallet
        case alreadyAddedToWatchlist
        case notSupportedYet
        case copied
        case created
        case deleted
        case noInternet
        case disconnectingWalletConnect
        case disconnectedWalletConnect
        case enabling
        case enabled(coins: Int)
        case sending
        case swapping
        case approving

        var icon: UIImage? {
            let image: UIImage?
            switch self {
            case .addedToWatchlist: image = UIImage(named: "star_24")
            case .removedFromWatchlist: image = UIImage(named: "star_off_24")
            case .addedToWallet: image = UIImage(named: "add_to_wallet_2_24")
            case .alreadyAddedToWatchlist: image = UIImage(named: "warning_2_24")
            case .notSupportedYet: image = UIImage(named: "warning_2_24")
            case .copied: image = UIImage(named: "copy_24")
            case .created: image = UIImage(named: "add_to_wallet_24")
            case .deleted: image = UIImage(named: "trash_24")
            case .noInternet: image = UIImage(named: "no_internet_24")
            case .disconnectingWalletConnect, .disconnectedWalletConnect: image = UIImage(named: "disconnecting_2_24")
            case .enabling: image = UIImage(named: "arrow_medium_2_down_24")
            case .enabled: image = UIImage(named: "circle_check_24")
            case .sending: image = UIImage(named: "arrow_medium_2_up_right_24")
            case .swapping: image = UIImage(named: "arrow_swap_2_24")
            case .approving: image = UIImage(named: "unordered_24")
            }
            return image?.withRenderingMode(.alwaysTemplate)
        }

        var color: UIColor {
            switch self {
            case .addedToWatchlist, .alreadyAddedToWatchlist, .notSupportedYet: return .themeJacob
            case .removedFromWatchlist,  .deleted, .noInternet, .disconnectedWalletConnect: return .themeLucian
            case .addedToWallet, .copied, .created, .enabled: return .themeRemus
            case .disconnectingWalletConnect, .enabling, .sending, .swapping, .approving: return .themeGray
            }
        }

        var title: String {
            switch self {
            case .addedToWatchlist: return "alert.added_to_watchlist".localized
            case .removedFromWatchlist: return "alert.removed_from_watchlist".localized
            case .addedToWallet: return "alert.added_to_wallet".localized
            case .alreadyAddedToWatchlist: return "alert.already_added_to_wallet".localized
            case .notSupportedYet: return "alert.not_supported_yet".localized
            case .copied: return "alert.copied".localized
            case .created: return "alert.created".localized
            case .deleted: return "alert.deleted".localized
            case .noInternet: return "alert.no_internet".localized
            case .disconnectingWalletConnect: return "alert.disconnecting".localized
            case .disconnectedWalletConnect: return "alert.disconnected".localized
            case .enabling: return "alert.enabling".localized
            case .enabled(let count): return "alert.enabled_coins".localized(count)
            case .sending: return "alert.sending".localized
            case .swapping: return "alert.swapping".localized
            case .approving: return "alert.approving".localized
            }
        }

        var showingTime: TimeInterval? {
            switch self {
            case .disconnectingWalletConnect, .enabling: return nil
            default: return 2
            }
        }

        var isLoading: Bool {
            switch self {
            case .disconnectingWalletConnect, .enabling, .sending, .swapping, .approving: return true
            default: return false
            }
        }

        var isUserInteractionEnabled: Bool {
            switch self {
            case .disconnectingWalletConnect, .enabling: return false
            default: return true
            }
        }

        var forced: Bool {
            switch self {
            case .disconnectedWalletConnect, .enabled: return false
            default: return true
            }
        }

    }

    func show(banner: BannerType) {
        var config = HUDConfig()

        config.style = .banner(.top)
        config.appearStyle = .moveOut
        config.userInteractionEnabled = banner.isUserInteractionEnabled
        config.preferredSize = CGSize(width: 114, height: 56)

        config.coverBlurEffectStyle = nil
        config.coverBlurEffectIntensity = nil
        config.coverBackgroundColor = .themeBlack50

        config.blurEffectStyle = .themeHud
        config.backgroundColor = .themeAndy
        config.blurEffectIntensity = 0.4

        config.cornerRadius = 28

        let viewItem = HUD.ViewItem(
                icon: banner.icon,
                iconColor: banner.color,
                title: banner.title,
                showingTime: banner.showingTime,
                isLoading: banner.isLoading
        )

        HUD.instance.show(config: config, viewItem: viewItem, forced: banner.forced)
    }

}
