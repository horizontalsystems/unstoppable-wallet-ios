import Combine
import Foundation
import MarketKit

final class AddZanoNodeViewModel: ObservableObject {
    private let blockchainType: BlockchainType
    private let zanoNodeManager: ZanoNodeManager

    @Published var url: String = "" {
        didSet {
            if oldValue != url {
                cautionState = .none
            }
        }
    }

    @Published var cautionState: CautionState = .none

    private let finishSubject = PassthroughSubject<Void, Never>()

    init(blockchainType: BlockchainType, zanoNodeManager: ZanoNodeManager = Core.shared.zanoNodeManager) {
        self.blockchainType = blockchainType
        self.zanoNodeManager = zanoNodeManager
    }

    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    func onTapAdd() {
        let parsedUrl: URL

        do {
            parsedUrl = try ZanoNodeUrlValidator.validate(urlString: url)
        } catch {
            cautionState = .caution(Caution(text: "add_zano_node.error.invalid_url".localized, type: .error))
            return
        }

        guard !zanoNodeManager.allNodes(blockchainType: blockchainType).contains(where: { $0.url == parsedUrl }) else {
            cautionState = .caution(Caution(text: "add_zano_node.warning.url_exists".localized, type: .warning))
            return
        }

        zanoNodeManager.addNew(blockchainType: blockchainType, url: parsedUrl)

        stat(page: .blockchainSettingsZanoAdd, event: .addZanoNode(chainUid: blockchainType.uid))
        finishSubject.send()
    }
}
