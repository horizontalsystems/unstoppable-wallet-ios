import Combine
import MarketKit

class BlockchainTokensService {
    private let approveTokensSubject = PassthroughSubject<(Blockchain, [Token]), Never>()
    private let rejectApproveTokensSubject = PassthroughSubject<Blockchain, Never>()

    private let requestSubject = PassthroughSubject<Request, Never>()

    private var currentRequest: Request?
}

extension BlockchainTokensService {
    var approveTokensPublisher: AnyPublisher<(Blockchain, [Token]), Never> {
        approveTokensSubject.eraseToAnyPublisher()
    }

    var rejectApproveTokensPublisher: AnyPublisher<Blockchain, Never> {
        rejectApproveTokensSubject.eraseToAnyPublisher()
    }

    var requestPublisher: AnyPublisher<Request, Never> {
        requestSubject.eraseToAnyPublisher()
    }

    func approveTokens(blockchain: Blockchain, tokens: [Token], enabledTokens: [Token], allowEmpty: Bool = false) {
        let request = Request(blockchain: blockchain, tokens: tokens.ordered(), enabledTokens: enabledTokens, allowEmpty: allowEmpty)

        currentRequest = request
        requestSubject.send(request)
    }

    func select(indexes: [Int]) {
        guard let request = currentRequest else {
            return
        }

        approveTokensSubject.send((request.blockchain, indexes.map { request.tokens[$0] }))
    }

    func cancel() {
        guard let request = currentRequest else {
            return
        }

        rejectApproveTokensSubject.send(request.blockchain)
    }
}

extension BlockchainTokensService {
    struct Request {
        let blockchain: Blockchain
        let tokens: [Token]
        let enabledTokens: [Token]
        let allowEmpty: Bool
    }
}
