import Combine
import Foundation
import MarketKit

class CheckAddressViewModel: ObservableObject {
    private static let coinUids = ["tether", "usd-coin", "paypal-usd"]

    private let marketKit = Core.shared.marketKit
    private let chainalysisValidator = ChainalysisAddressValidator()
    private let hashDitValidator = HashDitAddressValidator()
    private let eip20Validator = Eip20AddressValidator()
    private var cancellables = Set<AnyCancellable>()

    let hashDitBlockchains: [Blockchain]
    let contractFullCoins: [FullCoin]
    let issueTypes: [IssueType]

    @Published var address: String = ""
    @Published var addressResult: AddressInput.Result = .idle {
        didSet {
            syncAddressState()
        }
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var checkStates = [IssueType: CheckState]()

    init() {
        do {
            let blockchains = try marketKit.blockchains(uids: HashDitAddressValidator.supportedBlockchainTypes.map(\.uid))
            hashDitBlockchains = HashDitAddressValidator.supportedBlockchainTypes.compactMap { type in blockchains.first { $0.type == type } }
        } catch {
            hashDitBlockchains = []
        }

        do {
            let fullCoins = try marketKit.fullCoins(coinUids: Self.coinUids)
            contractFullCoins = Self.coinUids.compactMap { uid in
                guard let fullCoin = fullCoins.first(where: { $0.coin.uid == uid }) else {
                    return nil
                }

                return FullCoin(coin: fullCoin.coin, tokens: fullCoin.tokens.filter { Eip20AddressValidator.supports(token: $0) }.sorted())
            }
        } catch {
            contractFullCoins = []
        }

        issueTypes = [.chainalysis] + hashDitBlockchains.map { .hashdit(blockchainType: $0.type) } + contractFullCoins.flatMap(\.tokens).map { .contract(token: $0) }
    }

    private func syncAddressState() {
        switch addressResult {
        case .idle:
            state = .idle

            for type in issueTypes {
                checkStates[type] = .idle
            }
        case .loading:
            state = .idle

            for type in issueTypes {
                checkStates[type] = .idle
            }
        case .invalid:
            state = .invalid(nil)

            for type in issueTypes {
                checkStates[type] = .idle
            }
        case let .valid(success):
            state = .valid
            check(address: success.address)
        }
    }

    private func check(address: Address) {
        for type in issueTypes {
            var canCheck = false

            switch type {
            case .chainalysis:
                canCheck = true
            case .hashdit, .contract:
                if let addressBlockchainType = address.blockchainType, EvmBlockchainManager.blockchainTypes.contains(addressBlockchainType) {
                    canCheck = true
                }
            }

            guard canCheck else {
                checkStates[type] = .notAvailable
                continue
            }

            checkStates[type] = .checking

            Task { [weak self, chainalysisValidator, hashDitValidator, eip20Validator] in
                do {
                    let isClear: Bool

                    switch type {
                    case .chainalysis:
                        isClear = try await chainalysisValidator.isClear(address: address)
                    case let .hashdit(blockchainType):
                        isClear = try await hashDitValidator.isClear(address: address, blockchainType: blockchainType)
                    case let .contract(token):
                        isClear = try await eip20Validator.isClear(address: address, token: token)
                    }

                    await MainActor.run { [weak self] in
                        self?.checkStates[type] = isClear ? .clear : .detected
                    }
                } catch {
                    await MainActor.run { [weak self] in
                        self?.checkStates[type] = .notAvailable
                    }
                }
            }
        }
    }
}

extension CheckAddressViewModel {
    enum State {
        case idle
        case invalid(CautionNew?)
        case valid
    }

    enum IssueType: Hashable {
        case chainalysis
        case hashdit(blockchainType: BlockchainType)
        case contract(token: Token)
    }

    enum CheckState {
        case idle
        case checking
        case clear
        case detected
        case notAvailable
    }
}
