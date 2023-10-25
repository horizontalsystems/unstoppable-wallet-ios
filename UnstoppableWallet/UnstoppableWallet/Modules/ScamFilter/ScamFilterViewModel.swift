import SwiftUI

class ScamFilterViewModel: ObservableObject {
    private let scamFilterManager: ScamFilterManager

    @Published var enabled: Bool {
        didSet {
            scamFilterManager.scamFilterEnabled = enabled
        }
    }

    init(scamFilterManager: ScamFilterManager) {
        self.scamFilterManager = scamFilterManager

        enabled = scamFilterManager.scamFilterEnabled
    }
}
