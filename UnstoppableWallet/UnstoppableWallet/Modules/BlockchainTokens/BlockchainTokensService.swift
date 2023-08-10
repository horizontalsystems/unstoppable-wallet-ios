import RxSwift
import RxRelay
import MarketKit

class BlockchainTokensService {
    private let approveTokensRelay = PublishRelay<(Blockchain, [Token])>()
    private let rejectApproveTokensRelay = PublishRelay<Blockchain>()

    private let requestRelay = PublishRelay<Request>()

    private var currentRequest: Request?
}

extension BlockchainTokensService {

    var approveTokensObservable: Observable<(Blockchain, [Token])> {
        approveTokensRelay.asObservable()
    }

    var rejectApproveTokensObservable: Observable<Blockchain> {
        rejectApproveTokensRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveTokens(blockchain: Blockchain, tokens: [Token], enabledTokens: [Token], allowEmpty: Bool = false) {
        let request = Request(blockchain: blockchain, tokens: tokens.sorted(), enabledTokens: enabledTokens, allowEmpty: allowEmpty)

        currentRequest = request
        requestRelay.accept(request)
    }

    func select(indexes: [Int]) {
        guard let request = currentRequest else {
            return
        }

        approveTokensRelay.accept((request.blockchain, indexes.map { request.tokens[$0] }))
    }

    func cancel() {
        guard let request = currentRequest else {
            return
        }

        rejectApproveTokensRelay.accept(request.blockchain)
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
