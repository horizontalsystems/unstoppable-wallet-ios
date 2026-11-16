import RxRelay
import RxSwift
import UIKit

final class AppIconManager {
    static let allAppIcons: [AppIcon] = [
        .main,
        .alternate(name: "AppIconOrange", imageName: "app_icon_orange", title: "Orange"),
        .alternate(name: "AppIconLight", imageName: "app_icon_light", title: "Light"),
        .alternate(name: "AppIcon8ball", imageName: "app_icon_8ball", title: "8Ball"),
    ]

    private static let legacyNames = ["AppIconDark": "AppIconOrange", "AppIconMono": "AppIconLight"]
    private static let legacyTitles = ["Dark": "Orange", "Mono": "Light", "8ball": "8Ball"]

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

    var isSystemIconOutOfSync: Bool {
        UIApplication.shared.alternateIconName != appIcon.name
    }

    static var currentAppIcon: AppIcon {
        appIcon(alternateIconName: UIApplication.shared.alternateIconName)
    }

    private static func appIcon(alternateIconName: String?) -> AppIcon {
        guard let alternateIconName else {
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
