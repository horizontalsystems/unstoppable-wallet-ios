enum BiometryType {
    case faceId
    case touchId

    var title: String {
        switch self {
        case .faceId: return "face_id".localized
        case .touchId: return "touch_id".localized
        }
    }

    var iconName: String {
        switch self {
        case .faceId: return "face_id_24"
        case .touchId: return "touch_id_2_24"
        }
    }
}
