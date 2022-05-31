enum AppIcon {
    case main
    case alternate(name: String, title: String)

    var name: String? {
        switch self {
        case .main: return nil
        case .alternate(let name, _): return name
        }
    }

    var title: String {
        switch self {
        case .main: return "Main"
        case .alternate(_, let title): return title
        }
    }

    var imageName: String {
        switch self {
        case .main: return "AppIcon"
        case .alternate(let name, _): return name
        }
    }

}

extension AppIcon: Equatable {

    public static func ==(lhs: AppIcon, rhs: AppIcon) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main): return true
        case (.alternate(let lhsName, _), .alternate(let rhsName, _)): return lhsName == rhsName
        default: return false
        }
    }

}
