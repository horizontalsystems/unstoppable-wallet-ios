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
        .alternate(name: "AppIconIvfun", imageName: "app_icon_ivfun", title: "Ivfun"),
        .alternate(name: "AppIconDuck", imageName: "app_icon_duck", title: "Duck"),
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
