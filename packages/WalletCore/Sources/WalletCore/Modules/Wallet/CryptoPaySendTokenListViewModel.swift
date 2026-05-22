import Combine
import Foundation
import MarketKit
import WalletCore

class CryptoPaySendTokenListViewModel: ObservableObject {
    private let openCryptoPayManager = Core.shared.openCryptoPayManager

    @Published var state: State = .loading
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    @MainActor
    func load() async {
        state = .loading
        do {
            let payment = try await openCryptoPayManager.startPayment(url: url)
            state = .loaded(payment: payment)
        } catch is CancellationError {
            // no-op
        } catch {
            if Task.isCancelled { return }
            state = .failed(error: error)
        }
    }

    func resolve(wallet: Wallet, payment: OpenCryptoPayPayment) async throws -> SendData {
        try await openCryptoPayManager.resolve(wallet: wallet, against: payment)
    }
}

extension CryptoPaySendTokenListViewModel {
    enum State {
        case loading
        case loaded(payment: OpenCryptoPayPayment)
        case failed(error: Error)
    }
}
