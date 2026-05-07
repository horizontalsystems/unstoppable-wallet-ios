import RxRelay
import RxSwift
import UIKit

class AppIconManager {
    static let allAppIcons: [AppIcon] = [
        .main,
        .alternate(name: "AppIconDark", imageName: "app_icon_dark", title: "Dark"),
        .alternate(name: "AppIconMono", imageName: "app_icon_mono", title: "Mono"),
        .alternate(name: "AppIcon8ball", imageName: "app_icon_8ball", title: "8ball"),
        .alternate(name: "AppIconMonero", imageName: "app_icon_monero", title: "Monero"),
        .alternate(name: "AppIconZcash", imageName: "app_icon_zcash", title: "Zcash"),
        .alternate(name: "AppIconPepe", imageName: "app_icon_pepe", title: "Pepe"),
        .alternate(name: "AppIconDoge", imageName: "app_icon_doge", title: "Doge"),
        .alternate(name: "AppIconPunk", imageName: "app_icon_punk", title: "Punk"),
        .alternate(name: "AppIcon1874", imageName: "app_icon_1874", title: "#1874"),
        .alternate(name: "AppIconPlFlag", imageName: "app_icon_pl_flag", title: "PL"),
        .alternate(name: "AppIconYS", imageName: "app_icon_ys", title: "Sinwar"),
        .alternate(name: "AppIconYesChad", imageName: "app_icon_yes_chad", title: "Yeschad"),
        .alternate(name: "AppIconGigaChad", imageName: "app_icon_giga_chad", title: "Gigachad"),
    ]

    private let appIconRelay = PublishRelay<AppIcon>()
    var appIcon: AppIcon {
        didSet {
            appIconRelay.accept(appIcon)
            UIApplication.shared.setAlternateIconName(appIcon.name)
        }
    }

    init() {
        appIcon = Self.currentAppIcon
    }
}

extension AppIconManager {
    var appIconObservable: Observable<AppIcon> {
        appIconRelay.asObservable()
    }

    static var currentAppIcon: AppIcon {
        if let alternateIconName: String = UIApplication.shared.alternateIconName, let appIcon = allAppIcons.first(where: { $0.name == alternateIconName }) {
            return appIcon
        } else {
            return .main
        }
    }
}
