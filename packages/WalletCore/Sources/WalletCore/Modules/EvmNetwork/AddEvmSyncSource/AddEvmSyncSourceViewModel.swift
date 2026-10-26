import Combine
import Foundation
import MarketKit

final class AddEvmSyncSourceViewModel: ObservableObject {
    private let blockchainType: BlockchainType
    private let evmSyncSourceManager: EvmSyncSourceManager

    @Published var url: String = "" {
        didSet {
            if oldValue != url {
                urlCautionState = .none
            }
        }
    }

    @Published var basicAuth: String = ""
    @Published var urlCautionState: CautionState = .none

    private let finishSubject = PassthroughSubject<Void, Never>()

    init(blockchainType: BlockchainType, evmSyncSourceManager: EvmSyncSourceManager = Core.shared.evmSyncSourceManager) {
        self.blockchainType = blockchainType
        self.evmSyncSourceManager = evmSyncSourceManager
    }

    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    func onTapAdd() {
        let parsedUrl: URL

        do {
            parsedUrl = try EvmSyncSourceUrlValidator.validate(urlString: url, blockchainType: blockchainType)
        } catch {
            urlCautionState = .caution(Caution(text: "add_evm_sync_source.error.invalid_url".localized, type: .error))
            return
        }

        guard !evmSyncSourceManager.allSyncSources(blockchainType: blockchainType).contains(where: { $0.rpcSource.url == parsedUrl }) else {
            urlCautionState = .caution(Caution(text: "add_evm_sync_source.warning.url_exists".localized, type: .warning))
            return
        }

        let auth = basicAuth.trimmingCharacters(in: .whitespacesAndNewlines)
        evmSyncSourceManager.saveSyncSource(blockchainType: blockchainType, url: parsedUrl, auth: auth.isEmpty ? nil : auth)

        stat(page: .blockchainSettingsEvmAdd, event: .addEvmSource(chainUid: blockchainType.uid))
        finishSubject.send()
    }
}
