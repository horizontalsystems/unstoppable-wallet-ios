import Foundation
import MarketKit
import HsToolKit
import ObjectMapper
import BigInt
import Alamofire
import EvmKit
import TronKit
import SwiftUI

class AllBridgeMultiSwapProvider: IMultiSwapProvider {
    //    private let baseUrl = "https://allbridge.io/"
    private let baseUrl = "https://allbridge.blocksdecoded.com"
    private let blockchainTypes: [String: BlockchainType] = [
        "ARB": .arbitrumOne,
        "AVA": .avalanche,
        "BAS": .base,
        "BSC": .binanceSmartChain,
        "ETH": .ethereum,
        "OPT": .optimism,
        "POL": .polygon,
        "SRB": .stellar,
        "TRX": .tron,
    ]
    
    private let proxies: [String: String] = [
        //        //Ethereum
        //        "0x609c690e8F7D68a59885c9132e812eEbDaAf0c9e": nil,
        //BNB Chain
        "0x3C4FA639c8D7E65c603145adaD8bD12F2358312f": "0xdb7A84411507FA4cFE460ddAE0df8c411AB9DFa2",
        //Tron
        //        "TAuErcuAtU6BPt6YwL51JZ4RpDCPQASCU2": nil,
        //        //Solana
        //        "BrdgN2RPzEMWF96ZbnnJaUtQDQx7VRXYaHHbYCBvceWB": nil,
        //        //Polygon
        //        "0x7775d63836987f444E2F14AA0fA2602204D7D3E0": nil,
        //        //Arbitrum
        //        "0x9Ce3447B58D58e8602B7306316A5fF011B92d189": nil,
        //        //Stellar
        //        "CBQ6GW7QCFFE252QEVENUNG45KYHHBRO4IZIWFJOXEFANHPQUXX5NFWV": nil,
        //        //Avalanche
        //        "0x9068E1C28941D0A680197Cc03be8aFe27ccaeea9": nil,
        //        //Base
        //        "0x001E3f136c2f804854581Da55Ad7660a2b35DEf7": nil,
        //        //OP Mainnet
        //        "0x97E5BF5068eA6a9604Ee25851e6c9780Ff50d5ab": nil,
        //        //Celo
        //        "0x80858f5F8EFD2Ab6485Aba1A0B9557ED46C6ba0e": nil,
        //        //Sui
        //        "0x83d6f864a6b0f16898376b486699aa6321eb6466d1daf6a2e3764a51908fe99d": nil,
    ]
    
    private let feePaymentMethod = FeePaymentMethod.stableCoin
    
    
    //    private let networkManager = Core.shared.networkManager
    private let allowanceHelper = MultiSwapAllowanceHelper()
    private let marketKit = Core.shared.marketKit
    private let networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let tronKitManager = Core.shared.tronAccountManager.tronKitManager
    private let evmFeeEstimator = EvmFeeEstimator()
    
    private let storage: MultiSwapSettingStorage
    
    private var tokenPairs: [Token: AbToken] = [:]
    
    init(storage: MultiSwapSettingStorage) {
        self.storage = storage
        
        syncPools()
    }
    
    var id: String {
        "allbridge"
    }
    
    var name: String {
        "AllBridge"
    }
    
    var icon: String {
        "thorchain_32"
    }
    
    private func syncPools() {
        Task { [weak self, networkManager, baseUrl] in
            do {
                let abTokens: [AbToken] = try await networkManager.fetch(url: "\(baseUrl)/tokens")
                print("!!!!" )
                self?.sync(abTokens: abTokens)
            } catch {
                print("!!! ", error.localizedDescription)
            }
        }
    }
    
    private func sync(abTokens: [AbToken]) {
        var pairs = [Token: AbToken]()
        
        for abToken in abTokens {
            guard let blockchainType = blockchainTypes[abToken.chainSymbol] else {
                continue
            }
            
            var tokenType: TokenType?
            
            if blockchainType.isEvm || blockchainType == .tron {
                tokenType = .eip20(address: abToken.tokenAddress)
            }
            
            if blockchainType == .stellar, let originTokenAddress = abToken.originTokenAddress {
                let parts = originTokenAddress.split(separator: ":")
                if parts.count == 2 {
                    tokenType = .stellar(code: String(parts[0]), issuer: String(parts[1]))
                }
            }
            
            if let tokenType, let token = try? marketKit.token(query: .init(blockchainType: blockchainType, tokenType: tokenType)) {
                pairs[token] = abToken
            }
        }
        
        tokenPairs = pairs
    }
    
    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        tokenPairs[tokenIn] != nil && tokenPairs[tokenOut] != nil
    }
    
    private var slippage: Decimal {
        storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default
    }
    
    private func resolveDestination(token: Token) throws -> String {
        if let recipient = storage.recipient(blockchainType: token.blockchainType) {
            return recipient.raw
        }
        
        return try DestinationHelper.resolveDestination(token: token)
    }
    
    private func proxyFee(proxyAddress: String, amountIn: Decimal) -> Decimal {
        // need to fetch it from contract
        let feeBP: Decimal = 100
        return amountIn * feeBP / 10_000
    }
    
    private func gasFee(source: String, destination: String, messenger: String = "ALLBRIDGE") async throws -> GasFee {
        var parameters: Parameters = [
            "sourceToken": source,
            "destinationToken": destination,
            "messenger": messenger,
        ]
        return try await networkManager.fetch(url: "\(baseUrl)/gas/fee", parameters: parameters)
    }
    
    private func pendingInfo(amount: String, source: String, destination: String) async throws -> PendingInfo {
        var parameters: Parameters = [
            "amount": amount,
            "sourceToken": source,
            "destinationToken": destination,
        ]
        
        do {
            let a: PendingInfo = try await networkManager.fetch(url: "\(baseUrl)/pending/info", parameters: parameters)
            return a
        } catch {
            print("Err: \(error)")
            throw error
        }
    }
    
    private func estimateAmountOut(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> Decimal {
        guard let abTokenIn = tokenPairs[tokenIn] else {
            throw SwapError.unsupportedTokenIn
        }
        
        guard let abTokenOut = tokenPairs[tokenOut] else {
            throw SwapError.unsupportedTokenOut
        }
        
        let sourceToken = abTokenIn.tokenAddress
        let destinationToken = abTokenOut.tokenAddress
        
        var resAmountIn = amountIn
        let bridgeAddress = abTokenIn.bridgeAddress
        
        if let proxyAddress = proxies[bridgeAddress] {
            let proxyFee = self.proxyFee(proxyAddress: proxyAddress, amountIn: amountIn)
            resAmountIn -= proxyFee
            
            if resAmountIn < 0 {
                throw SwapError.lessThanRequireFee
            }
        }
        
        if (feePaymentMethod == .stableCoin) {
            let gasFee: GasFee = try await self.gasFee(source: sourceToken, destination: destinationToken)
            let allBridgeFee = gasFee.stablecoin.float
            
            resAmountIn -= allBridgeFee
            if resAmountIn < 0 {
                throw SwapError.lessThanRequireFee
            }
        }
        
        let amountString = tokenIn.rawAmountString(resAmountIn)
        let info = try await pendingInfo(amount: amountString, source: sourceToken, destination: destinationToken)
        
        return info.estimatedAmount.min.float
    }
    
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        guard let abTokenIn = tokenPairs[tokenIn] else {
            throw SwapError.unsupportedTokenIn
        }
        
        let crosschain = tokenIn.blockchainType != tokenOut.blockchainType
        
        let amountOut = try await estimateAmountOut(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
        let bridgeAddress = abTokenIn.bridgeAddress
        
        if tokenIn.blockchainType.isEvm {
            let router = proxies[bridgeAddress] ?? bridgeAddress
            
            let state = await allowanceHelper.allowanceState(spenderAddress: .init(raw: router), token: tokenIn, amount: amountIn)
            print(" state ", state)

            return AllBridgeMultiSwapEvmQuote(
                expectedAmountOut: amountOut,
                crosschain: crosschain,
                recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
                slippage: slippage,
                allowanceState: state
            )
        } else if tokenIn.blockchainType == .tron {
            return await AllBridgeMultiSwapEvmQuote(
                expectedAmountOut: amountOut,
                crosschain: crosschain,
                recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
                slippage: slippage,
                allowanceState: allowanceHelper.allowanceState(spenderAddress: .init(raw: bridgeAddress), token: tokenIn, amount: amountIn)
            )
        }
        
        return AllBridgeMultiSwapBtcQuote(
            expectedAmountOut: amountOut,
            crosschain: crosschain,
            recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
            slippage: slippage
        )
    }
    
    
    func transactionData<T: ImmutableMappable>(tokenIn: Token, tokenOut: Token, crosschain: Bool, amountIn: Decimal, expectedAmountOutMin: Decimal) async throws -> T {
        guard let abTokenIn = tokenPairs[tokenIn] else {
            throw SwapError.unsupportedTokenIn
        }
        
        guard let amount = tokenIn.rawAmount(amountIn) else {
            throw SwapError.invalidAmount
        }
        
        let sender = try resolveDestination(token: tokenIn)
        let recipient = try resolveDestination(token: tokenOut)
        
        guard let amountOutMinInt = tokenOut.rawAmount(expectedAmountOutMin) else {
            throw SwapError.invalidAmount
        }
        
        var parameters: Parameters = [
            "amount": amount.description,
            "sender": sender,
            "recipient": recipient,
            "sourceToken": abTokenIn.tokenAddress,
            "destinationToken": abTokenIn.tokenAddress,
        ]
        
        let path: String
        if crosschain {
            path = "bridge"
            parameters["messenger"] = "ALLBRIDGE"
            parameters["feePaymentMethod"] = feePaymentMethod.rawValue
        } else {
            path = "swap"
            parameters["minimumReceiveAmount"] = amountOutMinInt.description
        }
        
        return try await networkManager.fetch(url: "\(baseUrl)/raw/\(path)", parameters: parameters)
    }
    
    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        guard let abTokenIn = tokenPairs[tokenIn] else {
            throw SwapError.unsupportedTokenIn
        }
        
        let crosschain = tokenIn.blockchainType != tokenOut.blockchainType
        
        let amountOut = try await estimateAmountOut(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
        let bridgeAddress = abTokenIn.bridgeAddress
        
        if tokenIn.blockchainType.isEvm {
            let evmResponse: EvmSwapResponse = try await transactionData(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                crosschain: crosschain,
                amountIn: amountIn,
                expectedAmountOutMin: amountOut
            )
            guard let input = evmResponse.data.hs.hexData else {
                throw SwapError.convertionError
            }
            
            let router = proxies[evmResponse.to] ?? evmResponse.to
            
            let transactionData = TransactionData(
                to: try .init(hex: router),
                value: evmResponse.value.flatMap { BigUInt($0) } ?? BigUInt(0),
                input: input
            )
            
            let blockchainType = tokenIn.blockchainType
            let gasPriceData = transactionSettings?.gasPriceData
            var evmFeeData: EvmFeeData?
            var transactionError: Error?
            
            if let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper, let gasPriceData {
                do {
                    evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData)
                } catch {
                    transactionError = error
                }
            }
            
            return AllBridgeMultiSwapEvmConfirmationQuote(
                amountIn: amountIn,
                expectedAmountOut: amountOut,
                recipient: storage.recipient(blockchainType: blockchainType),
                crosschain: crosschain,
                slippage: slippage,
                transactionData: transactionData,
                transactionError: transactionError,
                gasPrice: gasPriceData?.userDefined,
                evmFeeData: evmFeeData,
                nonce: transactionSettings?.nonce
            )
        } else if tokenIn.blockchainType == .tron {
            let tronResponse: TronKit.CreatedTransactionResponse = try await transactionData(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                crosschain: crosschain,
                amountIn: amountIn,
                expectedAmountOutMin: amountOut
            )

            print("Response: \(tronResponse)")
//            if let tronKitWrapper = tronKitManager.tronKitWrapper {
//                tronKitWrapper.tronKit.estimateFee(contract: <#T##Contract#>)
//            }
            throw SwapError.convertionError
        }
        
        throw SwapError.convertionError
    }
    
    func otherSections(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: TransactionSettings?) -> [SendDataSection] {
        []
    }
    
    func settingsView(tokenIn: Token, tokenOut: Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let crosschain = tokenIn.blockchainType != tokenOut.blockchainType
        if !crosschain {
            let view = ThemeNavigationStack {
                RecipientAndSlippageMultiSwapSettingsView(tokenIn: tokenOut, storage: storage, onChangeSettings: onChangeSettings)
            }
            return AnyView(view)
        }

        let view = ThemeNavigationStack {
            RecipientMultiSwapSettingsView(tokenIn: tokenOut, storage: storage, onChangeSettings: onChangeSettings)
        }
        return AnyView(view)
    }
    
    func settingView(settingId: String) -> AnyView {
        fatalError("settingView(settingId:) has not been implemented")
    }
    
    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    func swap(tokenIn: Token, tokenOut: Token, amountIn: Decimal, quote: IMultiSwapConfirmationQuote) async throws {
        print("Swap!")
    }
}

extension AllBridgeMultiSwapProvider {
    enum FeePaymentMethod: String {
        case native = "WITH_NATIVE_CURRENCY"
        case stableCoin = "WITH_STABLECOIN"
    }
    
    enum SwapError: Error {
        case unsupportedTokenIn
        case unsupportedTokenOut
        case lessThanRequireFee
        case convertionError
        case invalidAmount
//        case noRouterAddress
//        case invalidTokenInType
//        case noDestinationAddress
//        case noGasPrice
//        case noGasLimit
//        case noEvmKitWrapper
//        case noBitcoinAdapter
//        case noSendParameters
    }

    struct AbToken: ImmutableMappable {
        let symbol: String
        let name: String
        let decimals: Int
        let tokenAddress: String
        let originTokenAddress: String?
        let chainSymbol: String
        let bridgeAddress: String

        init(map: Map) throws {
            symbol = try map.value("symbol")
            name = try map.value("name")
            decimals = try map.value("decimals")
            tokenAddress = try map.value("tokenAddress")
            originTokenAddress = try? map.value("originTokenAddress")
//            confirmations = try? map.value("confirmations")
            chainSymbol = try map.value("chainSymbol")
//            chainId = try? map.value("chainId")
//            chainType = try map.value("chainType")
//            chainName = try map.value("chainName")
            bridgeAddress = try map.value("bridgeAddress")
        }
    }

    struct Amount: ImmutableMappable {
        let int: Decimal
        let float: Decimal
        
        init(map: Map) throws {
            int = try map.value("int", using: Transform.stringToDecimalTransform)
            float = try map.value("float", using: Transform.stringToDecimalTransform)
        }
    }
    
    struct GasFee: ImmutableMappable {
        let stablecoin: Amount
        let native: Amount
        
        init(map: Map) throws {
            stablecoin = try map.value("stablecoin")
            native = try map.value("native")
        }
    }
    
    struct EstimatedAmount: ImmutableMappable {
        let max: Amount
        let min: Amount
        
        init(map: Map) throws {
            max = try map.value("max")
            min = try map.value("min")
        }
    }
    
    struct PendingInfo: ImmutableMappable {
        let pendingTxs: Int
        let estimatedAmount: EstimatedAmount
        
        init(map: Map) throws {
            pendingTxs = try map.value("pendingTxs")
            estimatedAmount = try map.value("estimatedAmount")
        }
    }

    struct EvmSwapResponse: ImmutableMappable {
        let from: String
        let to: String
        let value: String?
        let data: String

        init(map: Map) throws {
            from = try map.value("from")
            to = try map.value("to")
            value = try? map.value("value")
            data = try map.value("data")
        }
    }    
}
