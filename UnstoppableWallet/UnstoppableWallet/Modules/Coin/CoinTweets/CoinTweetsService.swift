import RxSwift
import RxRelay
import MarketKit
import HsExtensions

class CoinTweetsService {
    private var tasks = Set<AnyTask>()
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
        if case .failed = state {
            state = .loading
        }

        tasks = Set()

        Task { [weak self, marketKit, coinUid, twitterProvider] in
            do {
                var twitterUser: TwitterUser?

                if let user = self?.user {
                    twitterUser = user
                } else {
                    let username = try await marketKit.twitterUsername(coinUid: coinUid)
                    if let username, !username.isEmpty {
                        twitterUser = try await twitterProvider.userRequest(username: username)
                    }
                }

                guard let twitterUser else {
                    throw LoadError.tweeterUserNotFound
                }

                self?.user = twitterUser

                let tweetsPage = try await twitterProvider.tweets(user: twitterUser)
                self?.handle(tweets: tweetsPage.tweets)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

}

extension CoinTweetsService {

    enum LoadError: Error {
        case tweeterUserNotFound
    }

}
