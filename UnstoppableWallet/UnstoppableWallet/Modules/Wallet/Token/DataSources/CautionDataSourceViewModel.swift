import Combine
import HsExtensions
import TronKit

protocol ICautionDataSourceViewModel {
    var caution: TitledCaution? { get }
    var cautionPublisher: AnyPublisher<TitledCaution?, Never> { get }
}

class TronAccountInactiveViewModel {
    private let cautionSubject = PassthroughSubject<TitledCaution?, Never>()
    private(set) var caution: TitledCaution? {
        didSet {
            cautionSubject.send(caution)
        }
    }

    init(adapter: BaseTronAdapter) {
        caution = (adapter.receiveAddress as? ActivatedDepositAddress)?.isActive == true
            ? nil
            : TitledCaution(title: "balance.token.account.inactive.title".localized, text: "balance.token.account.inactive.description".localized, type: .warning)
    }
}

extension TronAccountInactiveViewModel: ICautionDataSourceViewModel {
    var cautionPublisher: AnyPublisher<TitledCaution?, Never> {
        cautionSubject.eraseToAnyPublisher()
    }
}
