import Combine
import Foundation

class BlackFridayPremiumSlideViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let themeManager = Core.shared.themeManager
    @Published private(set) var themeMode: ThemeMode

    init() {
        themeMode = themeManager.themeMode

        themeManager.$themeMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.themeMode = $0 }
            .store(in: &cancellables)
    }
}
