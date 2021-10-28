import RxSwift
import MarketKit

class CoinTweetsService {
    private let disposeBag = DisposeBag()
    private let twitterProvider: TweetsProvider
    private let marketKit: MarketKit.Kit

    private var coinUid: String
    private var user: TwitterUser? = nil

    private let stateSubject = PublishSubject<DataStatus<[Tweet]>>()
    
    var state: DataStatus<[Tweet]> = .loading {
        didSet {
            stateSubject.onNext(state)
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
        stateSubject.asObservable()
    }

    func fetch() {
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
