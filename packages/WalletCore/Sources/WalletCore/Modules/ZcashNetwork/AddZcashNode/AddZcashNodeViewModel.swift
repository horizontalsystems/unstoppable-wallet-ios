import Combine
import Foundation
import MarketKit

class AddZcashNodeViewModel: ObservableObject {
    private let blockchainType: BlockchainType
    private let zcashNodeManager = Core.shared.zcashNodeManager

    @Published var address: String = "" {
        didSet {
            if oldValue != address {
                cautionState = .none
            }
        }
    }

    @Published var cautionState: CautionState = .none

    private let finishSubject = PassthroughSubject<Void, Never>()

    init(blockchainType: BlockchainType) {
        self.blockchainType = blockchainType
    }

    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    func onTapAdd() {
        var urlString = address.trimmingCharacters(in: .whitespacesAndNewlines)

        // Bare host[:port] is assumed to be a TLS lightwalletd; a pasted https://… URL is parsed as-is.
        if !urlString.isEmpty, !urlString.contains("://") {
            urlString = "https://" + urlString
        }

        // Canonicalize to scheme://host:port (lowercased, explicit port) so node identity, dedup, and the
        // AdapterManager revert lookup all compare byte-stably regardless of how the user typed the address.
        guard let parsed = URL(string: urlString), let scheme = parsed.scheme, let host = parsed.host, !host.isEmpty,
              let url = URL(string: "\(scheme.lowercased())://\(host.lowercased()):\(parsed.port ?? 443)")
        else {
            cautionState = .caution(Caution(text: "add_zcash_node.error.invalid_url".localized, type: .error))
            return
        }

        guard !zcashNodeManager.allNodes(blockchainType: blockchainType).contains(where: { $0.url == url }) else {
            cautionState = .caution(Caution(text: "add_zcash_node.warning.url_exists".localized, type: .warning))
            return
        }

        stat(page: .blockchainSettingsZcashAdd, event: .addZcashNode(chainUid: blockchainType.uid))
        zcashNodeManager.addNew(blockchainType: blockchainType, url: url)
        finishSubject.send()
    }
}
