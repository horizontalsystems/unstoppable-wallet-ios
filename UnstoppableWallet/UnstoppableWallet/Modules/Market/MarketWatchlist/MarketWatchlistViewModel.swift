import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MarketWatchlistViewModel {
    private let disposeBag = DisposeBag()
    private let service: MarketWatchlistService

    init(service: MarketWatchlistService) {
        self.service = service
    }

}

extension MarketWatchlistViewModel {
}
