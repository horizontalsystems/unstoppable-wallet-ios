import SwiftUI

enum ScanQrModuleNew {
    struct Options: OptionSet {
        let rawValue: Int

        static let paste = Options(rawValue: 1 << 0)
        static let picker = Options(rawValue: 1 << 1)
    }
}
