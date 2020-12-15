import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MarketTopViewModel {
    private let disposeBag = DisposeBag()
    private let service: MarketTopService

    init(service: MarketTopService) {
        self.service = service
    }

}

extension MarketTopViewModel {
}
