import Combine
import StoreKit

class SupportViewModel: ObservableObject {
    let purchaseManager = Core.shared.purchaseManager
    let marketKit = Core.shared.marketKit

    private var cancellables = Set<AnyCancellable>()
    @Published var buttonState: ButtonState = .idle

    private let onReceiveGroup: (String) -> Void
    @Published var isPresented: Bool = true

    init(onReceiveGroup: @escaping (String) -> Void) {
        self.onReceiveGroup = onReceiveGroup
    }

    @MainActor private func update(state: ButtonState) async {
        await MainActor.run { [weak self] in
            self?.buttonState = state
        }
    }

    @MainActor
    private func receive(link: String) {
        onReceiveGroup(link)
        isPresented = false
    }
}

extension SupportViewModel {
    enum ButtonState {
        case idle
        case loading
    }
}

extension SupportViewModel {
    func onFetchChat() {
        buttonState = .loading
        Task { [weak self] in
            guard let jws = await self?.purchaseManager.getJws() else {
                await self?.update(state: .idle)
                return
            }

            guard let telegramLink = try await self?.marketKit.requestPersonalSupport(jws: jws) else {
                await self?.update(state: .idle)
                return
            }

            await self?.update(state: .idle)
            await self?.receive(link: telegramLink)
        }
    }
}
