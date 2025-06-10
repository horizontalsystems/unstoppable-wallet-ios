import Combine
import Foundation
import TronKit

class TronWalletTokenViewModel: ObservableObject {
    private let tronKit: TronKit.Kit
    private var cancellables = Set<AnyCancellable>()

    @Published var accountActive: Bool

    init(tronKit: TronKit.Kit) {
        self.tronKit = tronKit
        accountActive = tronKit.accountActive

        tronKit.trxBalancePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)
    }

    private func sync() {
        let newAccountActive = tronKit.accountActive

        if newAccountActive != accountActive {
            accountActive = newAccountActive
        }
    }
}
