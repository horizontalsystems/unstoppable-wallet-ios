import Combine
import Foundation

class AppViewModel: ObservableObject {
    private let passcodeLockManager = Core.shared.passcodeLockManager
    private let localStorage = Core.shared.localStorage
    private let themeManager = Core.shared.themeManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var passcodeLockState: PasscodeLockState
    @Published private(set) var introVisible: Bool
    @Published private(set) var themeMode: ThemeMode

    init() {
        passcodeLockState = passcodeLockManager.state
        introVisible = !localStorage.mainShownOnce
        themeMode = themeManager.themeMode

        passcodeLockManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.passcodeLockState = $0 }
            .store(in: &cancellables)

        themeManager.$themeMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.themeMode = $0 }
            .store(in: &cancellables)
    }
}

extension AppViewModel {
    func handleIntroFinish() {
        localStorage.mainShownOnce = true
        introVisible = false
    }
}
