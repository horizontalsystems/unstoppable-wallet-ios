import Foundation
import UIKit
import ComponentKit
import HUD

extension HudHelper {

    enum BannerType {
        case addedToWatchlist
        case removedFromWatchlist
        case addedToWallet
        case alreadyAddedToWallet
        case notSupportedYet
        case copied
        case saved
        case success
        case created
        case deleted
        case noInternet
        case disconnectingWalletConnect
        case disconnectedWalletConnect
        case enabling
        case enabled(coins: Int)
        case sending
        case sent
        case swapping
        case swapped
        case approving
        case approved
        case attention(string: String)
        case error(string: String)

        var icon: UIImage? {
            let image: UIImage?
            switch self {
            case .addedToWatchlist: image = UIImage(named: "star_24")
            case .removedFromWatchlist: image = UIImage(named: "star_off_24")
            case .addedToWallet: image = UIImage(named: "add_to_wallet_2_24")
            case .alreadyAddedToWallet: image = UIImage(named: "warning_2_24")
            case .notSupportedYet: image = UIImage(named: "warning_2_24")
            case .copied: image = UIImage(named: "copy_24")
            case .saved: image = UIImage(named: "download_24")
            case .success: image = UIImage(named: "circle_check_24")
            case .created: image = UIImage(named: "add_to_wallet_24")
            case .deleted: image = UIImage(named: "trash_24")
            case .noInternet: image = UIImage(named: "no_internet_24")
            case .disconnectingWalletConnect, .disconnectedWalletConnect: image = UIImage(named: "disconnecting_2_24")
            case .enabling: image = UIImage(named: "arrow_medium_2_down_24")
            case .enabled: image = UIImage(named: "circle_check_24")
            case .sending, .sent: image = UIImage(named: "arrow_medium_2_up_right_24")
            case .swapping, .swapped: image = UIImage(named: "arrow_swap_2_24")
            case .approving, .approved: image = UIImage(named: "unordered_24")
            case .attention: image = UIImage(named: "warning_2_24")
            case .error: image = UIImage(named: "warning_2_24")
            }
            return image?.withRenderingMode(.alwaysTemplate)
        }

        var color: UIColor {
            switch self {
            case .addedToWatchlist, .alreadyAddedToWallet, .notSupportedYet, .sent, .swapped, .approved, .attention: return .themeJacob
            case .removedFromWatchlist,  .deleted, .noInternet, .disconnectedWalletConnect, .error: return .themeLucian
            case .addedToWallet, .copied, .saved, .success, .created, .enabled: return .themeRemus
            case .disconnectingWalletConnect, .enabling, .sending, .swapping, .approving: return .themeGray
            }
        }

        var title: String {
            switch self {
            case .addedToWatchlist: return "alert.added_to_watchlist".localized
            case .removedFromWatchlist: return "alert.removed_from_watchlist".localized
            case .addedToWallet: return "alert.added_to_wallet".localized
            case .alreadyAddedToWallet: return "alert.already_added_to_wallet".localized
            case .notSupportedYet: return "alert.not_supported_yet".localized
            case .copied: return "alert.copied".localized
            case .saved: return "alert.saved".localized
            case .success: return "alert.success_action".localized
            case .created: return "alert.created".localized
            case .deleted: return "alert.deleted".localized
            case .noInternet: return "alert.no_internet".localized
            case .disconnectingWalletConnect: return "alert.disconnecting".localized
            case .disconnectedWalletConnect: return "alert.disconnected".localized
            case .enabling: return "alert.enabling".localized
            case .enabled(let count): return "alert.enabled_coins".localized(count)
            case .sending, .sent: return "alert.sending".localized
            case .swapping, .swapped: return "alert.swapping".localized
            case .approving, .approved: return "alert.approving".localized
            case .attention(let description): return description
            case .error(let description): return description
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
            case .disconnectedWalletConnect, .enabled, .sent, .swapped, .approved: return false
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
