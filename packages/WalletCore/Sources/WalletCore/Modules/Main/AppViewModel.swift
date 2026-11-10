import Combine
import Foundation

class AppViewModel: ObservableObject {
    private let passcodeLockManager = Core.shared.passcodeLockManager
    private let localStorage = Core.shared.localStorage
    private let themeManager = Core.shared.themeManager
    private let brandColorManager = Core.shared.brandColorManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var passcodeLockState: PasscodeLockState
    @Published private(set) var introVisible: Bool
    @Published private(set) var themeMode: ThemeMode
    @Published private(set) var brandColor: BrandColor

    init() {
        passcodeLockState = passcodeLockManager.state
        introVisible = !localStorage.mainShownOnce
        themeMode = themeManager.themeMode
        brandColor = brandColorManager.brandColor

        passcodeLockManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.passcodeLockState = $0 }
            .store(in: &cancellables)

        themeManager.$themeMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.themeMode = $0 }
            .store(in: &cancellables)

        brandColorManager.$brandColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.brandColor = $0 }
            .store(in: &cancellables)
    }
}

extension AppViewModel {
    func handleIntroFinish() {
        localStorage.mainShownOnce = true
        introVisible = false
    }
}
