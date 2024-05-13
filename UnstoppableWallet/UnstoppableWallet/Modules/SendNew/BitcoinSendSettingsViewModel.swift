import Combine
import Foundation
import Hodler

class BitcoinSendSettingsViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    let handler: BitcoinPreSendHandler

    @Published var sortMode: TransactionDataSortMode
    @Published var rbfEnabled: Bool
    @Published var lockTimeInterval: HodlerPlugin.LockTimeInterval?
    @Published var resetEnabled = false
    @Published var doneEnabled = true

    @Published var utxos: String = ""

    init(handler: BitcoinPreSendHandler) {
        self.handler = handler

        sortMode = handler.sortMode
        rbfEnabled = handler.rbfEnabled
        lockTimeInterval = handler.lockTimeInterval

        handler.balancePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncUtxos() }
            .store(in: &cancellables)

        syncUtxos()
    }

    private func syncUtxos() {
        let totalUtxos = handler.allUtxos.count
        let usedUtxos = handler.customUtxos?.count ?? totalUtxos

        utxos = [usedUtxos.description, totalUtxos.description].joined(separator: " / ")
    }
}

extension BitcoinSendSettingsViewModel {
    func reset() {}

    func applySettings() {
        handler.sortMode = sortMode
        handler.rbfEnabled = rbfEnabled
        handler.lockTimeInterval = lockTimeInterval
    }
}
