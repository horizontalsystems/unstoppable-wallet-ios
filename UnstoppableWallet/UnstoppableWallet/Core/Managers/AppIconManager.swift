import RxRelay
import RxSwift
import UIKit

class AppIconManager {
    static let allAppIcons: [AppIcon] = [
        .main,
        .alternate(name: "AppIconDark", imageName: "app_icon_dark", title: "Dark"),
        .alternate(name: "AppIconMono", imageName: "app_icon_mono", title: "Mono"),
        .alternate(name: "AppIconLeo", imageName: "app_icon_leo", title: "Leo"),
        .alternate(name: "AppIconMustang", imageName: "app_icon_mustang", title: "Mustang"),
        .alternate(name: "AppIconYak", imageName: "app_icon_yak", title: "Yak"),
        .alternate(name: "AppIconPunk", imageName: "app_icon_punk", title: "Punk"),
        .alternate(name: "AppIcon1874", imageName: "app_icon_1874", title: "#1874"),
        .alternate(name: "AppIcon8ball", imageName: "app_icon_8ball", title: "8ball"),
        .alternate(name: "AppIconPepe", imageName: "app_icon_pepe", title: "Pepe"),
        .alternate(name: "AppIconDoge", imageName: "app_icon_doge", title: "Doge"),
        .alternate(name: "AppIconGigaChad", imageName: "app_icon_giga_chad", title: "Gigachad"),
        .alternate(name: "AppIconPlFlag", imageName: "app_icon_pl_flag", title: "PL"),
        .alternate(name: "AppIconYesChad", imageName: "app_icon_yes_chad", title: "Yeschad"),
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
