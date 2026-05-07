enum AppIcon {
    case main
    case alternate(name: String, imageName: String, title: String)

    var name: String? {
        switch self {
        case .main: return nil
        case let .alternate(name, _, _): return name
        }
    }

    var title: String {
        switch self {
        case .main: return "Main"
        case let .alternate(_, _, title): return title
        }
    }

    var imageName: String {
        switch self {
        case .main: return "app_icon_main"
        case let .alternate(_, imageName, _): return imageName
        }
    }
}

extension AppIcon: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .main:
            hasher.combine("main")
        case let .alternate(name, _, _):
            hasher.combine("alternate")
            hasher.combine(name)
        }
    }
}

extension AppIcon: Equatable {
    public static func == (lhs: AppIcon, rhs: AppIcon) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main): return true
        case let (.alternate(lhsName, _, _), .alternate(rhsName, _, _)): return lhsName == rhsName
        default: return false
        }
    }
}
