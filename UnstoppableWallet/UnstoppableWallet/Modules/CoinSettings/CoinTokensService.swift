import RxSwift
import RxRelay
import MarketKit

class CoinTokensService {
    private let approveTokensRelay = PublishRelay<CoinWithTokens>()
    private let rejectApproveTokensRelay = PublishRelay<Coin>()

    private let requestRelay = PublishRelay<Request>()
}

extension CoinTokensService {

    var approveTokensObservable: Observable<CoinWithTokens> {
        approveTokensRelay.asObservable()
    }

    var rejectApproveTokensObservable: Observable<Coin> {
        rejectApproveTokensRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveTokens(coin: Coin, eligibleTokens: [Token], currentTokens: [Token] = [], allowEmpty: Bool = false) {
        let request = Request(coin: coin, eligibleTokens: eligibleTokens.sorted(), currentTokens: currentTokens, allowEmpty: allowEmpty)
        requestRelay.accept(request)
    }

    func select(tokens: [Token], coin: Coin) {
        let coinWithTokens = CoinWithTokens(coin: coin, tokens: tokens)
        approveTokensRelay.accept(coinWithTokens)
    }

    func cancel(coin: Coin) {
        rejectApproveTokensRelay.accept(coin)
    }

}

extension CoinTokensService {

    struct CoinWithTokens {
        let coin: Coin
        let tokens: [Token]

        init(coin: Coin, tokens: [Token] = []) {
            self.coin = coin
            self.tokens = tokens
        }
    }

    struct Request {
        let coin: Coin
        let eligibleTokens: [Token]
        let currentTokens: [Token]
        let allowEmpty: Bool
    }

}
