import Combine
import Foundation
import Hodler

class BitcoinSendSettingsViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    let handler: BitcoinPreSendHandler

    @Published var sortMode: TransactionDataSortMode {
        didSet {
            handler.sortMode = sortMode
        }
    }

    @Published var rbfEnabled: Bool {
        didSet {
            handler.rbfEnabled = rbfEnabled
        }
    }

    @Published var lockTimeInterval: HodlerPlugin.LockTimeInterval? {
        didSet {
            handler.lockTimeInterval = lockTimeInterval
        }
    }

    @Published var resetEnabled: Bool {
        didSet {
            print("resetEnabled: \(resetEnabled)")
        }
    }

    @Published var utxos: String = ""

    init(handler: BitcoinPreSendHandler) {
        self.handler = handler

        sortMode = handler.sortMode
        rbfEnabled = handler.rbfEnabled
        lockTimeInterval = handler.lockTimeInterval

        resetEnabled = handler.settingsModified

        handler.settingsModifiedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.resetEnabled = $0 }
            .store(in: &cancellables)

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
    func reset() {
        handler.reset()
    }
}
