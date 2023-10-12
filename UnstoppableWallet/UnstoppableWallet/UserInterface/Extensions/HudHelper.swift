import Foundation
import UIKit
import ComponentKit
import HUD

extension HudHelper {

    enum BannerType {
        case addedToWatchlist
        case removedFromWatchlist
        case addedToWallet
        case removedFromWallet
        case alreadyAddedToWallet
        case notSupportedYet
        case copied
        case saved
        case savedToCloud
        case done
        case restored
        case created
        case imported
        case walletAdded
        case deleted
        case noInternet
        case disconnectingWalletConnect
        case disconnectedWalletConnect
        case waitingForSession
        case enabling
        case enabled(coins: Int)
        case sending
        case sent
        case swapping
        case swapped
        case approving
        case revoking
        case approved
        case revoked
        case success(string: String)
        case attention(string: String)
        case error(string: String)

        var icon: UIImage? {
            let image: UIImage?
            switch self {
            case .addedToWatchlist: image = UIImage(named: "star_24")
            case .removedFromWatchlist: image = UIImage(named: "star_off_24")
            case .addedToWallet: image = UIImage(named: "add_to_wallet_2_24")
            case .removedFromWallet: image = UIImage(named: "empty_wallet_24")
            case .alreadyAddedToWallet: image = UIImage(named: "warning_2_24")
            case .notSupportedYet: image = UIImage(named: "warning_2_24")
            case .copied: image = UIImage(named: "copy_24")
            case .saved: image = UIImage(named: "download_24")
            case .savedToCloud: image = UIImage(named: "icloud_24")
            case .done: image = UIImage(named: "circle_check_24")
            case .restored: image = UIImage(named: "download_24")
            case .created: image = UIImage(named: "add_to_wallet_24")
            case .imported: image = UIImage(named: "add_to_wallet_2_24")
            case .walletAdded: image = UIImage(named: "binocule_24")
            case .deleted: image = UIImage(named: "trash_24")
            case .noInternet: image = UIImage(named: "no_internet_24")
            case .waitingForSession: image = UIImage(named: "disconnecting_2_24")
            case .disconnectingWalletConnect, .disconnectedWalletConnect: image = UIImage(named: "disconnecting_2_24")
            case .enabling: image = UIImage(named: "arrow_medium_2_down_24")
            case .enabled: image = UIImage(named: "circle_check_24")
            case .sending, .sent: image = UIImage(named: "arrow_medium_2_up_right_24")
            case .swapping, .swapped: image = UIImage(named: "arrow_swap_2_24")
            case .approving, .approved, .revoking, .revoked: image = UIImage(named: "unordered_24")
            case .success: image = UIImage(named: "circle_check_24")
            case .attention: image = UIImage(named: "warning_2_24")
            case .error: image = UIImage(named: "circle_warning_24")
            }
            return image?.withRenderingMode(.alwaysTemplate)
        }

        var color: UIColor {
            switch self {
            case .addedToWatchlist, .alreadyAddedToWallet, .notSupportedYet, .sent, .swapped, .approved, .revoked, .attention: return .themeJacob
            case .removedFromWallet, .removedFromWatchlist,  .deleted, .noInternet, .disconnectedWalletConnect, .error: return .themeLucian
            case .addedToWallet, .copied, .saved, .savedToCloud, .done, .restored, .created, .imported, .walletAdded, .enabled, .success: return .themeRemus
            case .waitingForSession, .disconnectingWalletConnect, .enabling, .sending, .swapping, .approving, .revoking: return .themeGray
            }
        }

        var title: String {
            switch self {
            case .addedToWatchlist: return "alert.added_to_watchlist".localized
            case .removedFromWatchlist: return "alert.removed_from_watchlist".localized
            case .addedToWallet: return "alert.added_to_wallet".localized
            case .removedFromWallet: return "alert.removed_from_wallet".localized
            case .alreadyAddedToWallet: return "alert.already_added_to_wallet".localized
            case .notSupportedYet: return "alert.not_supported_yet".localized
            case .copied: return "alert.copied".localized
            case .saved: return "alert.saved".localized
            case .savedToCloud: return "alert.saved_to_icloud".localized
            case .done: return "alert.success_action".localized
            case .restored: return "alert.restored".localized
            case .created: return "alert.created".localized
            case .imported: return "alert.imported".localized
            case .walletAdded: return "alert.wallet_added".localized
            case .deleted: return "alert.deleted".localized
            case .noInternet: return "alert.no_internet".localized
            case .waitingForSession: return "alert.waiting_for_session".localized
            case .disconnectingWalletConnect: return "alert.disconnecting".localized
            case .disconnectedWalletConnect: return "alert.disconnected".localized
            case .enabling: return "alert.enabling".localized
            case .enabled(let count): return "alert.enabled_coins".localized(count)
            case .sending: return "alert.sending".localized
            case .sent: return "alert.sent".localized
            case .swapping: return "alert.swapping".localized
            case .swapped: return "alert.swapped".localized
            case .approving: return "alert.approving".localized
            case .approved: return "alert.approved".localized
            case .revoking: return "alert.revoking".localized
            case .revoked: return "alert.revoked".localized
            case .success(let description): return description
            case .attention(let description): return description
            case .error(let description): return description
            }
        }

        var showingTime: TimeInterval? {
            switch self {
            case .waitingForSession, .disconnectingWalletConnect, .sending, .enabling: return nil
            default: return 2
            }
        }

        var isLoading: Bool {
            switch self {
            case .waitingForSession, .disconnectingWalletConnect, .enabling, .sending, .swapping, .approving, .revoking: return true
            default: return false
            }
        }

        var isUserInteractionEnabled: Bool {
            switch self {
            case .disconnectingWalletConnect, .enabling, .sending: return false
            default: return true
            }
        }

        var forced: Bool {
            switch self {
            case .attention, .disconnectedWalletConnect, .enabled, .sent, .swapped, .approved, .revoked: return false
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
        config.coverBackgroundColor = .themeBlackTenTwenty

        config.blurEffectStyle = .themeHud
        config.backgroundColor = .themeSteel30
        config.blurEffectIntensity = 0.4

        config.cornerRadius = 28

        let viewItem = HUD.ViewItem(
                icon: banner.icon,
                iconColor: banner.color,
                title: banner.title,
                showingTime: banner.showingTime,
                isLoading: banner.isLoading
        )

        let statusBarStyle = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.windowScene?.statusBarManager?.statusBarStyle
        HUD.instance.show(config: config, viewItem: viewItem, statusBarStyle: statusBarStyle, forced: banner.forced)
    }

}
