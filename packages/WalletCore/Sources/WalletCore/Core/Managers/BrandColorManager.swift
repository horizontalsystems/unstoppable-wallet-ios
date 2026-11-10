import Combine
import Foundation
import HsExtensions

public final class BrandColorManager {
    static let userDefaultsKey = "brand_color"

    public static let shared = BrandColorManager()

    private let userDefaults: UserDefaults

    @PostPublished public private(set) var brandColor: BrandColor {
        didSet {
            userDefaults.set(brandColor.rawValue, forKey: Self.userDefaultsKey)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let rawValue = userDefaults.string(forKey: Self.userDefaultsKey), let stored = BrandColor(rawValue: rawValue) {
            brandColor = stored
        } else {
            brandColor = .default
        }
    }

    public func set(brandColor: BrandColor) {
        guard self.brandColor != brandColor else {
            return
        }

        self.brandColor = brandColor
    }
}
