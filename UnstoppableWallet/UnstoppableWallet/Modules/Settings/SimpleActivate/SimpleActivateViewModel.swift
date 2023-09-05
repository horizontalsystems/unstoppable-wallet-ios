import SwiftUI

class SimpleActivateViewModel: ObservableObject {
    private let localStorage: LocalStorage

    @Published var activated: Bool {
        didSet {
            localStorage.lockTimeEnabled = activated
        }
    }

    init(localStorage: LocalStorage) {
        self.localStorage = localStorage
        activated = localStorage.lockTimeEnabled
    }

}
