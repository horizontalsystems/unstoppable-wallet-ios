import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MarketTop100ViewModel {
    private let disposeBag = DisposeBag()
    private let service: MarketTop100Service

    init(service: MarketTop100Service) {
        self.service = service
    }

}

extension MarketTop100ViewModel {
}
