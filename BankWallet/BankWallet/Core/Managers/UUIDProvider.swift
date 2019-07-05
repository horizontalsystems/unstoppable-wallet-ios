import Foundation

class UUIDProvider: IUUIDProvider {
    static let shared = UUIDProvider()

    func generate() -> String {
        return UUID().uuidString
    }

}
