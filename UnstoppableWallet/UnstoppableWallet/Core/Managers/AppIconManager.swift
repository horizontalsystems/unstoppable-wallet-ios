import RxSwift
import RxRelay
import StorageKit
import UIKit

class AppIconManager {
    static let allAppIcons: [AppIcon] = [
        .main,
        .alternate(name: "AppIconDark", title: "Dark"),
        .alternate(name: "AppIconMono", title: "Mono"),
        .alternate(name: "AppIconLeo", title: "Leo"),
        .alternate(name: "AppIconMustang", title: "Mustang"),
        .alternate(name: "AppIconYak", title: "Yak"),
        .alternate(name: "AppIconPunk", title: "Punk"),
        .alternate(name: "AppIcon1874", title: "#1874"),
        .alternate(name: "AppIcon1009", title: "#1009")
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
