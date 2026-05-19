public enum BiometryType {
    case faceId
    case touchId

    public var title: String {
        switch self {
        case .faceId: return "face_id".localized
        case .touchId: return "touch_id".localized
        }
    }

    public var iconName: String {
        switch self {
        case .faceId: return "face_id_24"
        case .touchId: return "touch_id_2_24"
        }
    }
}
