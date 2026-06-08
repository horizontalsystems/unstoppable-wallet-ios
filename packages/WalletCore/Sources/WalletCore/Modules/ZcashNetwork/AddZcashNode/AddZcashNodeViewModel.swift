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

        if !urlString.isEmpty, !urlString.contains("://") {
            urlString = "https://" + urlString
        }

        guard let parsed = URLComponents(string: urlString),
              let scheme = parsed.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = parsed.host?.lowercased(), !host.isEmpty,
              parsed.user == nil, parsed.password == nil,
              parsed.path.isEmpty || parsed.path == "/",
              parsed.query == nil, parsed.fragment == nil
        else {
            cautionState = .caution(Caution(text: "add_zcash_node.error.invalid_url".localized, type: .error))
            return
        }
        let port = parsed.port ?? 443
        guard (1 ... 65_535).contains(port) else {
            cautionState = .caution(Caution(text: "add_zcash_node.error.invalid_url".localized, type: .error))
            return
        }

        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port

        guard let url = components.url else {
            cautionState = .caution(Caution(text: "add_zcash_node.error.invalid_url".localized, type: .error))
            return
        }

        guard !zcashNodeManager.allNodes(blockchainType: blockchainType).contains(where: { $0.url == url }) else {
            cautionState = .caution(Caution(text: "add_zcash_node.warning.url_exists".localized, type: .warning))
            return
        }

        do {
            try zcashNodeManager.addNew(blockchainType: blockchainType, url: url)
            stat(page: .blockchainSettingsZcashAdd, event: .addZcashNode(chainUid: blockchainType.uid))
            finishSubject.send()
        } catch {
            cautionState = .caution(Caution(text: error.localizedDescription, type: .error))
        }
    }
}
