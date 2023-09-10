enum AppIcon {
    case main
    case alternate(name: String, title: String)

    var name: String? {
        switch self {
        case .main: return nil
        case let .alternate(name, _): return name
        }
    }

    var title: String {
        switch self {
        case .main: return "Main"
        case let .alternate(_, title): return title
        }
    }

    var imageName: String {
        switch self {
        case .main: return "AppIcon60x60"
        case let .alternate(name, _): return "\(name)60x60"
        }
    }
}

extension AppIcon: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .main:
            hasher.combine("main")
        case let .alternate(name, _):
            hasher.combine("alternate")
            hasher.combine(name)
        }
    }
}

extension AppIcon: Equatable {
    public static func == (lhs: AppIcon, rhs: AppIcon) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main): return true
        case let (.alternate(lhsName, _), .alternate(rhsName, _)): return lhsName == rhsName
        default: return false
        }
    }
}
