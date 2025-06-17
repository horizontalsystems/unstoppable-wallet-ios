import Combine
import Foundation

class AppViewModel: ObservableObject {
    private let passcodeLockManager = Core.shared.passcodeLockManager
    private let localStorage = Core.shared.localStorage
    private let lockManager = Core.shared.lockManager
    private let themeManager = Core.shared.themeManager
    private let appManager = Core.shared.appManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var passcodeLockState: PasscodeLockState
    @Published private(set) var introVisible: Bool
    @Published private(set) var locked: Bool
    @Published private(set) var themeMode: ThemeMode
    @Published private(set) var coverVisible = false

    init() {
        passcodeLockState = passcodeLockManager.state
        introVisible = !localStorage.mainShownOnce
        locked = lockManager.isLocked
        themeMode = themeManager.themeMode

        passcodeLockManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.passcodeLockState = $0 }
            .store(in: &cancellables)

        lockManager.$isLocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.locked = $0 }
            .store(in: &cancellables)

        themeManager.$themeMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.themeMode = $0 }
            .store(in: &cancellables)

        appManager.didBecomeActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.coverVisible = false }
            .store(in: &cancellables)

        appManager.willResignActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.coverVisible = true }
            .store(in: &cancellables)
    }
}

extension AppViewModel {
    func handleIntroFinish() {
        localStorage.mainShownOnce = true
        introVisible = false
    }
}
