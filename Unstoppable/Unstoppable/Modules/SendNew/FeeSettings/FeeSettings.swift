enum FeeSettings {
    enum FeeValue {
        case spinner
        case none
        case value(primary: String, secondary: String?)
    }

    struct ViewItem {
        let title: String
        let value: String?
        let subValue: String?
    }
}
