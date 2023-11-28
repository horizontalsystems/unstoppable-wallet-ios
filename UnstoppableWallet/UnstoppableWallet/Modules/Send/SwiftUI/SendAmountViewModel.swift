import Combine
import Foundation
import MarketKit

class SendAmountViewModel: ObservableObject {
    let token: Token

    @Published var inputType: InputType = .coin
    @Published var text: String = "" {
        didSet {}
    }

    @Published var coinAmount: Decimal = 0
    @Published var currencyAmount: Decimal = 0

    let currency: Currency

    init(token: Token, currencyManager: CurrencyManager) {
        self.token = token
        currency = currencyManager.baseCurrency
    }

    func toggleInputType() {
        switch inputType {
        case .coin: inputType = .currency
        case .currency: inputType = .coin
        }
    }
}

extension SendAmountViewModel {
    enum InputType {
        case coin
        case currency
    }
}
