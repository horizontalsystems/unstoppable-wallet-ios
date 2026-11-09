import RxRelay
import RxSwift
import UIKit

class AppIconManager {
    static let allAppIcons: [AppIcon] = [
        .main,
        .alternate(name: "AppIconOrange", imageName: "app_icon_orange", title: "Orange"),
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

    private static let legacyNames = ["AppIconDark": "AppIconOrange"]
    private static let legacyTitles = ["Dark": "Orange"]

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
        guard let alternateIconName = UIApplication.shared.alternateIconName else {
            return .main
        }

        let name = legacyNames[alternateIconName] ?? alternateIconName
        return allAppIcons.first { $0.name == name } ?? .main
    }

    static func appIcon(title: String) -> AppIcon {
        let title = legacyTitles[title] ?? title
        return allAppIcons.first { $0.title == title } ?? .main
    }
}
