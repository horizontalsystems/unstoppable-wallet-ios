import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinTweetsViewModel {
    private let service: CoinTweetsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

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
            errorRelay.accept(nil)
        case .completed(let tweets):
            viewItemsRelay.accept(tweets.map { viewItem(tweet: $0) })
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func viewItem(tweet: Tweet) -> ViewItem {
        ViewItem(
                id: tweet.id,
                title: tweet.user.name,
                subTitle: "@\(tweet.user.username)",
                titleImageUrl: tweet.user.profileImageUrl,
                text: tweet.text,
                attachment: tweet.attachments.first,
                date: DateHelper.instance.formatFullTime(from: tweet.date),
                userUrl: "https://twitter.com/\(tweet.user.username)",
                url: "https://twitter.com/\(tweet.user.username)/status/\(tweet.id)",
                referencedTweet: tweet.referencedTweet.map { referencedTweet in
                    ReferencedTweet(
                            title: "coin_page.tweets.reference_type.\(referencedTweet.referenceType.rawValue)".localized(referencedTweet.tweet.user.username),
                            text: referencedTweet.tweet.text,
                            url: "https://twitter.com/\(referencedTweet.tweet.user.username)/status/\(referencedTweet.tweet.id)"
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

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
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
        let titleImageUrl: String
        let text: String
        let attachment: Tweet.Attachment?
        let date: String
        let userUrl: String
        let url: String
        let referencedTweet: ReferencedTweet?
    }

    struct ReferencedTweet {
        let title: String
        let text: String
        let url: String
    }

}
