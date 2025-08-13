import EvmKit
import Foundation
import MarketKit
import SwiftUI

class BaseEvmMultiSwapProvider: IMultiSwapProvider {
    private let adapterManager = Core.shared.adapterManager
    private let localStorage = Core.shared.localStorage
    let evmBlockchainManager = Core.shared.evmBlockchainManager
    let storage: MultiSwapSettingStorage
    private let allowanceHelper = MultiSwapAllowanceHelper()

    @Published private var useMevProtection: Bool = false

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage
    }

    var id: String {
        fatalError("Must be implemented in subclass")
    }

    var name: String {
        fatalError("Must be implemented in subclass")
    }

    var icon: String {
        fatalError("Must be implemented in subclass")
    }

    func supports(tokenIn _: Token, tokenOut _: Token) -> Bool {
        fatalError("Must be implemented in subclass")
    }

    func quote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal) async throws -> IMultiSwapQuote {
        fatalError("Must be implemented in subclass")
    }

    func confirmationQuote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, transactionSettings _: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        fatalError("Must be implemented in subclass")
    }

    func otherSections(tokenIn: Token, tokenOut _: Token, amountIn _: Decimal, transactionSettings _: TransactionSettings?) -> [SendDataSection] {
        let allowMevProtection = MerkleTransactionAdapter.allowProtection(chain: evmBlockchainManager.chain(blockchainType: tokenIn.blockchainType))

        guard allowMevProtection else {
            useMevProtection = false
            return []
        }

        useMevProtection = localStorage.useMevProtection

        let binding = Binding<Bool>(
            get: { [weak self] in
                if Core.shared.purchaseManager.activated(.vipSupport) {
                    self?.useMevProtection ?? false
                } else {
                    false
                }
            },
            set: { [weak self] newValue in
                let successBlock = { [weak self] in
                    self?.useMevProtection = newValue
                    self?.localStorage.useMevProtection = newValue
                }

                Coordinator.shared.performAfterPurchase(premiumFeature: .vipSupport, page: .swap, trigger: .mevProtection) {
                    successBlock()
                }
            }
        )

        return [.init([
            .mevProtection(isOn: binding),
        ], isList: false)]
    }

    func settingsView(tokenIn _: Token, tokenOut _: Token, onChangeSettings _: @escaping () -> Void) -> AnyView {
        fatalError("settingsView(tokenIn:tokenOut:onChangeSettings:) has not been implemented")
    }

    func settingView(settingId _: String) -> AnyView {
        fatalError("settingView(settingId:) has not been implemented")
    }

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    func swap(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, quote _: IMultiSwapConfirmationQuote) async throws {
        fatalError("Must be implemented in subclass")
    }

    func send(blockchainType: BlockchainType, transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) async throws {
        guard let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper else {
            throw SwapError.noEvmKitWrapper
        }

        _ = try await evmKitWrapper.send(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            privateSend: useMevProtection,
            nonce: nonce
        )
    }

    func spenderAddress(chain _: Chain) throws -> EvmKit.Address {
        fatalError("Must be implemented in subclass")
    }

    func allowanceState(token: Token, amount: Decimal) async -> MultiSwapAllowanceHelper.AllowanceState {
        do {
            let chain = evmBlockchainManager.chain(blockchainType: token.blockchainType)
            let spenderAddress = try spenderAddress(chain: chain)

            return await allowanceHelper.allowanceState(spenderAddress: .init(raw: spenderAddress.eip55), token: token, amount: amount)
        } catch {
            return .unknown
        }
    }
}

extension BaseEvmMultiSwapProvider {
    enum SwapError: Error {
        case noEvmKitWrapper
    }
}
