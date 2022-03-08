import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinTweetsViewModel {
    private let service: CoinTweetsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let infoRelay = BehaviorRelay<String?>(value: nil)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: CoinTweetsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<[Tweet]>) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            infoRelay.accept(nil)
            syncErrorRelay.accept(false)
        case .completed(let tweets):
            viewItemsRelay.accept(tweets.map { viewItem(tweet: $0) })
            loadingRelay.accept(false)
            infoRelay.accept(tweets.isEmpty ? "coin_page.tweets.no_tweets_yet".localized : nil)
            syncErrorRelay.accept(false)
        case .failed(let error):
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)

            if case CoinTweetsService.LoadError.tweeterUserNotFound = error {
                infoRelay.accept("coin_page.tweets.not_available".localized)
                syncErrorRelay.accept(false)
            } else {
                infoRelay.accept(nil)
                syncErrorRelay.accept(true)
            }
        }
    }

    private func viewItem(tweet: Tweet) -> ViewItem {
        ViewItem(
                id: tweet.id,
                title: tweet.user.name,
                subTitle: "@\(tweet.user.username)",
                username: tweet.user.username,
                titleImageUrl: tweet.user.profileImageUrl,
                text: tweet.text,
                attachment: tweet.attachments.first,
                date: DateHelper.instance.formatFullTime(from: tweet.date),
                referencedTweet: tweet.referencedTweet.map { referencedTweet in
                    ReferencedTweet(
                            title: "coin_page.tweets.reference_type.\(referencedTweet.referenceType.rawValue)".localized(referencedTweet.tweet.user.username),
                            text: referencedTweet.tweet.text
                    )
                }
        )
    }

}

extension CoinTweetsViewModel {

    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var infoDriver: Driver<String?> {
        infoRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    var username: String? {
        service.username
    }

    func refresh() {
        service.fetch()
    }

    func viewDidLoad() {
        service.fetch()
    }

}

extension CoinTweetsViewModel {

    struct ViewItem {
        let id: String
        let title: String
        let subTitle: String
        let username: String
        let titleImageUrl: String
        let text: String
        let attachment: Tweet.Attachment?
        let date: String
        let referencedTweet: ReferencedTweet?
    }

    struct ReferencedTweet {
        let title: String
        let text: String
    }

}
