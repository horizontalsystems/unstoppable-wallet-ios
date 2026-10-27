import SwiftUI

public enum ScanQrModule {
    public struct Options: OptionSet {
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public let rawValue: Int

        public static let paste = Options(rawValue: 1 << 0)
        public static let picker = Options(rawValue: 1 << 1)
    }
}
