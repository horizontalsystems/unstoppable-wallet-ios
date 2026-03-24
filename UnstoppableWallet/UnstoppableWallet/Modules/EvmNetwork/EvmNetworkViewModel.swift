import EvmKit
import Foundation
import MarketKit
import RxSwift

class EvmNetworkViewModel: ObservableObject {
    let blockchain: Blockchain
    private let evmSyncSourceManager = Core.shared.evmSyncSourceManager
    private let disposeBag = DisposeBag()

    let defaultSources: [EvmSyncSource]
    @Published var customSources: [EvmSyncSource] = []

    @Published var currentSource: EvmSyncSource {
        didSet {
            saveEnabled = selectedSource != currentSource
        }
    }

    @Published var selectedSource: EvmSyncSource {
        didSet {
            saveEnabled = selectedSource != currentSource
        }
    }

    @Published var saveEnabled = false

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        defaultSources = evmSyncSourceManager.defaultSyncSources(blockchainType: blockchain.type)

        let currentSource = evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
        self.currentSource = currentSource
        selectedSource = currentSource

        subscribe(disposeBag, evmSyncSourceManager.syncSourcesUpdatedObservable) { [weak self] _ in
            DispatchQueue.main.async { self?.syncCustomSources() }
        }

        syncCustomSources()
    }

    private func syncCustomSources() {
        customSources = evmSyncSourceManager.customSyncSources(blockchainType: blockchain.type)
    }
}

extension EvmNetworkViewModel {
    func remove(syncSource: EvmSyncSource) {
        evmSyncSourceManager.delete(syncSource: syncSource, blockchainType: blockchain.type)
        stat(page: .blockchainSettingsEvm, event: .deleteCustomEvmSource(chainUid: blockchain.uid))

        if selectedSource == syncSource {
            selectedSource = defaultSources[0]
        }

        currentSource = evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
    }

    func save() {
        evmSyncSourceManager.saveCurrent(syncSource: selectedSource, blockchainType: blockchain.type)

        let statName = defaultSources.contains(selectedSource) ? selectedSource.name : "custom"
        stat(page: .blockchainSettingsEvm, event: .switchEvmSource(chainUid: blockchain.uid, name: statName))
    }
}
