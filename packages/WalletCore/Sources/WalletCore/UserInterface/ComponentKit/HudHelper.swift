import UIKit

public class HudHelper {
    public static let instance = HudHelper()

    func hide() {
        HUD.instance.hide()
    }
}

extension HudHelper {
    enum BannerType {
        static let waitingForSessionKey = "waiting_for_session"

        case addedToWatchlist
        case removedFromWatchlist
        case addedToWallet
        case removedFromWallet
        case alreadyAddedToWallet
        case notSupportedYet
        case copied
        case saved
        case savedToCloud
        case passwordFromKeychain
        case done
        case restored
        case created
        case imported
        case walletAdded
        case deleted
        case noInternet
        case disconnectingWalletConnect
        case disconnectedWalletConnect
        case connectedWalletConnect
        case waitingForSession
        case enabling
        case enabled(coins: Int)
        case preparing
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
            case .addedToWatchlist: image = UIImage(named: "heart")
            case .removedFromWatchlist: image = UIImage(named: "heart_off")
            case .addedToWallet: image = UIImage(named: "wallet_in")
            case .removedFromWallet: image = UIImage(named: "wallet_remove")
            case .alreadyAddedToWallet: image = UIImage(named: "warning")
            case .notSupportedYet: image = UIImage(named: "warning")
            case .copied: image = UIImage(named: "copy")
            case .saved: image = UIImage(named: "arrow_in")
            case .savedToCloud: image = UIImage(named: "cloud")
            case .passwordFromKeychain: image = UIImage(named: "cloud")
            case .done: image = UIImage(named: "done_e_filled")
            case .restored: image = UIImage(named: "arrow_in")
            case .created: image = UIImage(named: "wallet_add")
            case .imported: image = UIImage(named: "wallet_in")
            case .walletAdded: image = UIImage(named: "binocular")
            case .deleted: image = UIImage(named: "trash")
            case .noInternet: image = UIImage(named: "cloud_off")
            case .waitingForSession: image = UIImage(named: "disconnecting_2")
            case .disconnectingWalletConnect, .disconnectedWalletConnect: image = UIImage(named: "disconnecting_2")
            case .connectedWalletConnect: image = UIImage(named: "done_e_filled")
            case .enabling: image = UIImage(named: "arrow_m_down")
            case .enabled: image = UIImage(named: "done_e_filled")
            case .preparing: image = UIImage(named: "arrow_m_up")
            case .sending, .sent: image = UIImage(named: "arrow_m_up")
            case .swapping, .swapped: image = UIImage(named: "swap_e")
            case .approving, .approved, .revoking, .revoked: image = UIImage(named: "list")
            case .success: image = UIImage(named: "done_e_filled")
            case .attention: image = UIImage(named: "warning")
            case .error: image = UIImage(named: "warning_filled")
            }
            return image?.withRenderingMode(.alwaysTemplate)
        }

        var color: UIColor {
            switch self {
            case .addedToWatchlist, .alreadyAddedToWallet, .notSupportedYet, .sent, .swapped, .approved, .revoked, .attention: return .themeJacob
            case .removedFromWallet, .removedFromWatchlist, .deleted, .noInternet, .disconnectedWalletConnect, .error: return .themeLucian
            case .addedToWallet, .copied, .saved, .savedToCloud, .done, .restored, .created, .imported, .walletAdded, .enabled, .success, .connectedWalletConnect, .passwordFromKeychain: return .themeRemus
            case .waitingForSession, .disconnectingWalletConnect, .enabling, .preparing, .sending, .swapping, .approving, .revoking: return .themeGray
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
            case .passwordFromKeychain: return "alert.fetched_from_keychain".localized
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
            case .connectedWalletConnect: return "alert.connected".localized
            case .enabling: return "alert.enabling".localized
            case let .enabled(count): return "alert.enabled_coins".localized(count)
            case .preparing: return "alert.preparing".localized
            case .sending: return "alert.sending".localized
            case .sent: return "alert.sent".localized
            case .swapping: return "alert.swapping".localized
            case .swapped: return "alert.swapped".localized
            case .approving: return "alert.approving".localized
            case .approved: return "alert.approved".localized
            case .revoking: return "alert.revoking".localized
            case .revoked: return "alert.revoked".localized
            case let .success(description): return description
            case let .attention(description): return description
            case let .error(description): return description
            }
        }

        var showingTime: TimeInterval? {
            switch self {
            case .waitingForSession, .disconnectingWalletConnect, .preparing, .sending, .enabling: return nil
            default: return 2
            }
        }

        var isLoading: Bool {
            switch self {
            case .waitingForSession, .disconnectingWalletConnect, .enabling, .preparing, .sending, .swapping, .approving, .revoking: return true
            default: return false
            }
        }

        var isUserInteractionEnabled: Bool {
            switch self {
            case .disconnectingWalletConnect, .enabling, .preparing, .sending: return false
            default: return true
            }
        }

        var forced: Bool {
            switch self {
            case .attention, .disconnectedWalletConnect, .enabled, .sent, .swapped, .approved, .revoked: return false
            default: return true
            }
        }

        var tag: String {
            switch self {
            case .waitingForSession: return Self.waitingForSessionKey
            default: return ""
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
        config.backgroundColor = .themeAndy
        config.blurEffectIntensity = 0.4

        config.cornerRadius = 28

        let viewItem = HUD.ViewItem(
            icon: banner.icon,
            iconColor: banner.color,
            title: banner.title,
            tag: banner.tag,
            showingTime: banner.showingTime,
            isLoading: banner.isLoading
        )

        let statusBarStyle = UIWindow.keyWindow?.windowScene?.statusBarManager?.statusBarStyle
        HUD.instance.show(config: config, viewItem: viewItem, statusBarStyle: statusBarStyle, forced: banner.forced)
    }
}
