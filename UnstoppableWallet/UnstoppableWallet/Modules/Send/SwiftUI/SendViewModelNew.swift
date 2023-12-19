import Combine
import Foundation
import MarketKit

class SendViewModelNew: ObservableObject {
    let token: Token

    @Published var availableBalance: Decimal = 123

    init(token: Token) {
        self.token = token
    }
}
