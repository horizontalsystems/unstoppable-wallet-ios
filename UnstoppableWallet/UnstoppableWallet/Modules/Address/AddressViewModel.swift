import Combine
import Foundation
import MarketKit

class AddressViewModel: ObservableObject {
    private let wallet: Wallet
    private var cancellables = Set<AnyCancellable>()

    @Published var address: String = ""
    @Published var addressResult: AddressInput.Result = .idle {
        didSet {
            syncAddressState()
        }
    }

    @Published var state: State = .empty {
        didSet {
            // todo
        }
    }

    init(wallet: Wallet, address: String?) {
        self.wallet = wallet

        defer {
            if let address {
                self.address = address
            }
        }
    }

    private func syncAddressState() {
        switch addressResult {
        case .idle:
            state = .empty
        case .loading, .invalid:
            state = .invalid
        case let .valid(success):
            let address = success.address.raw
            state = .valid(address: address)
        }
    }
}

extension AddressViewModel {
    var token: Token {
        wallet.token
    }
}

extension AddressViewModel {
    enum State {
        case empty
        case invalid
        case valid(address: String)

        var address: String? {
            switch self {
            case let .valid(address): return address
            default: return nil
            }
        }
    }
}

// TODO: extract to separate file
struct ResolvedAddress: Hashable {
    let address: String
}
