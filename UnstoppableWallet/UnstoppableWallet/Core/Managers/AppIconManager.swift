import RxSwift
import RxRelay
import StorageKit
import UIKit

class AppIconManager {
    let allAppIcons: [AppIcon] = [
        .main,
        .alternate(name: "AppIconDark", title: "Dark"),
        .alternate(name: "AppIconMono", title: "Mono"),
        .alternate(name: "AppIconLeo", title: "Leo"),
        .alternate(name: "AppIconMustang", title: "Mustang"),
        .alternate(name: "AppIconYak", title: "Yak"),
        .alternate(name: "AppIconPunk", title: "Punk"),
        .alternate(name: "AppIconApe", title: "Ape"),
        .alternate(name: "AppIconDoodle", title: "Doodle")
    ]

    private let appIconRelay = PublishRelay<AppIcon>()
    var appIcon: AppIcon {
        didSet {
            appIconRelay.accept(appIcon)
            UIApplication.shared.setAlternateIconName(appIcon.name)
        }
    }

    init() {
        if let alternateIconName: String = UIApplication.shared.alternateIconName, let appIcon = allAppIcons.first(where: { $0.name == alternateIconName }) {
            self.appIcon = appIcon
        } else {
            appIcon = .main
        }
    }

}

extension AppIconManager {

    var appIconObservable: Observable<AppIcon> {
        appIconRelay.asObservable()
    }

}
