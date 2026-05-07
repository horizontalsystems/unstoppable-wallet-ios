enum AppFlavor: String {
    case regular
    case stable

    static let current: AppFlavor = {
        #if STABLE
            return .stable
        #else
            return .regular
        #endif
    }()
}
