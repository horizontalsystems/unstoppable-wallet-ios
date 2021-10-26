import RxSwift

class CoinTweetsService {
    private let disposeBag = DisposeBag()
    private let provider: TweetsProvider
    private var username: String? = nil

    private var user: TwitterUser? = nil
    private var tweets = [Tweet]()
    private let stateSubject = PublishSubject<DataStatus<[Tweet]>>()
    
    var state: DataStatus<[Tweet]> = .loading {
        didSet {
            stateSubject.onNext(state)
        }
    }
    
    init(provider: TweetsProvider, usernameService: TwitterUsernameService) {
        self.provider = provider

        subscribe(disposeBag, usernameService.usernameObservable) { [weak self] username in self?.username = username }
    }

    private func handle(tweets: [Tweet]) {
        self.tweets = tweets.sorted(by: { tweet, tweet2 in tweet.date > tweet2.date })

        state = .completed(tweets)
    }

}

extension CoinTweetsService {

    var stateObservable: Observable<DataStatus<[Tweet]>> {
        stateSubject.asObservable()
    }

    func fetch() {
        guard let username = username else {
            state = .failed(CoinTweetsModule.LoadError.tweeterUserNotFound)
            return
        }

        let single: Single<TwitterUser?>

        if let user = user {
            single = Single.just(user)
        } else {
            single = provider.userRequestSingle(username: username)
        }

        single
                .flatMap { [weak self] (user: TwitterUser?) -> Single<TweetsProvider.TweetsPage> in
                    guard let user = user, let service = self else {
                        return Single.error(CoinTweetsModule.LoadError.tweeterUserNotFound)
                    }

                    service.user = user

                    return service.provider.tweetsSingle(user: user)
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
