import Foundation

public enum BiometryType {
    case faceId
    case touchId

    public var title: LocalizedStringResource {
        switch self {
        case .faceId: return .package("face_id")
        case .touchId: return .package("touch_id")
        }
    }

    public var iconName: String {
        switch self {
        case .faceId: return "face_id_24"
        case .touchId: return "touch_id_2_24"
        }
    }
}
