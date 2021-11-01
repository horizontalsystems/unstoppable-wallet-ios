import RxSwift
import RxRelay
import MarketKit

class CoinTweetsService {
    private let disposeBag = DisposeBag()
    private let twitterProvider: TweetsProvider
    private let marketKit: MarketKit.Kit
    private let coinUid: String

    private var user: TwitterUser? = nil
    private let stateRelay = PublishRelay<DataStatus<[Tweet]>>()

    private(set) var state: DataStatus<[Tweet]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }
    
    init(coinUid: String, twitterProvider: TweetsProvider, marketKit: MarketKit.Kit) {
        self.coinUid = coinUid
        self.twitterProvider = twitterProvider
        self.marketKit = marketKit
    }

    private func handle(tweets: [Tweet]) {
        state = .completed(tweets)
    }

}

extension CoinTweetsService {

    var stateObservable: Observable<DataStatus<[Tweet]>> {
        stateRelay.asObservable()
    }

    var username: String? {
        user?.username
    }

    func fetch() {
        state = .loading

        let single: Single<TwitterUser?>

        if let user = user {
            single = Single.just(user)
        } else {
            // TODO: Here there must be another endpoint to get twitter username
            single = marketKit
                    .marketInfoOverviewSingle(coinUid: coinUid, currencyCode: "USD", languageCode: "en")
                    .flatMap { [weak self] info in
                        guard let service = self, let username = info.links[.twitter] else {
                            return Single.just(nil)
                        }

                        return service.twitterProvider.userRequestSingle(username: username)
                    }
        }

        single
                .flatMap { [weak self] (user: TwitterUser?) -> Single<TweetsProvider.TweetsPage> in
                    guard let user = user, let service = self else {
                        return Single.error(CoinTweetsModule.LoadError.tweeterUserNotFound)
                    }

                    service.user = user

                    return service.twitterProvider.tweetsSingle(user: user)
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(
                        onSuccess: { [weak self] tweetsPage in
                            self?.handle(tweets: tweetsPage.tweets)
                        },
                        onError: { [weak self] error in
                            self?.state = .failed(error)
                        }
                )
                .disposed(by: disposeBag)
    }

}
