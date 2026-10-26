import Combine
import Foundation
import MarketKit

final class AddMoneroNodeViewModel: ObservableObject {
    private let blockchainType: BlockchainType
    private let moneroNodeManager: MoneroNodeManager

    @Published var url: String = "" {
        didSet {
            if oldValue != url {
                urlCautionState = .none
            }
        }
    }

    @Published var login: String = ""
    @Published var password: String = ""
    @Published var urlCautionState: CautionState = .none

    private let finishSubject = PassthroughSubject<Void, Never>()

    init(blockchainType: BlockchainType, moneroNodeManager: MoneroNodeManager = Core.shared.moneroNodeManager) {
        self.blockchainType = blockchainType
        self.moneroNodeManager = moneroNodeManager
    }

    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    func onTapAdd() {
        let parsedUrl: URL

        do {
            parsedUrl = try MoneroNodeUrlValidator.validate(urlString: url)
        } catch MoneroNodeUrlValidator.ValidationError.portRequired {
            urlCautionState = .caution(Caution(text: "add_monero_node.error.port_required".localized, type: .error))
            return
        } catch {
            urlCautionState = .caution(Caution(text: "add_monero_node.error.invalid_url".localized, type: .error))
            return
        }

        guard let newCanonical = MoneroNodeUrlValidator.canonical(url: parsedUrl) else {
            urlCautionState = .caution(Caution(text: "add_monero_node.error.invalid_url".localized, type: .error))
            return
        }

        guard !moneroNodeManager.allNodes(blockchainType: blockchainType).contains(where: { MoneroNodeUrlValidator.canonical(url: $0.node.url) == newCanonical }) else {
            urlCautionState = .caution(Caution(text: "add_monero_node.warning.url_exists".localized, type: .warning))
            return
        }

        let trimmedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        moneroNodeManager.addNew(
            blockchainType: blockchainType,
            url: parsedUrl,
            isTrusted: true,
            login: trimmedLogin.isEmpty ? nil : trimmedLogin,
            password: trimmedPassword.isEmpty ? nil : trimmedPassword
        )

        stat(page: .blockchainSettingsMoneroAdd, event: .addMoneroNode(chainUid: blockchainType.uid))
        finishSubject.send()
    }
}
