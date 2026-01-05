import Alamofire
import BigInt
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import StellarKit
import SwiftUI
import TronKit

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
        //        Ethereum
        "0x609c690e8F7D68a59885c9132e812eEbDaAf0c9e": "0x6153F92eF47A97046820714233956f0B0F99d886",
//        BNB Chain
        "0x3C4FA639c8D7E65c603145adaD8bD12F2358312f": "0x6153F92eF47A97046820714233956f0B0F99d886",
//        Tron
//        "TAuErcuAtU6BPt6YwL51JZ4RpDCPQASCU2" to null,
//        Solana
//        "BrdgN2RPzEMWF96ZbnnJaUtQDQx7VRXYaHHbYCBvceWB" to null,
//        Polygon
        "0x7775d63836987f444E2F14AA0fA2602204D7D3E0": "0x6153F92eF47A97046820714233956f0B0F99d886",
//        Arbitrum
        "0x9Ce3447B58D58e8602B7306316A5fF011B92d189": "0x6153F92eF47A97046820714233956f0B0F99d886",
//        Stellar
//        "CBQ6GW7QCFFE252QEVENUNG45KYHHBRO4IZIWFJOXEFANHPQUXX5NFWV" to null,
//        Avalanche
        "0x9068E1C28941D0A680197Cc03be8aFe27ccaeea9": "0x6153F92eF47A97046820714233956f0B0F99d886",
//        Base
        "0x001E3f136c2f804854581Da55Ad7660a2b35DEf7": "0x6153F92eF47A97046820714233956f0B0F99d886",
//        OP Mainnet
        "0x97E5BF5068eA6a9604Ee25851e6c9780Ff50d5ab": "0x6153F92eF47A97046820714233956f0B0F99d886",
//        Celo
//        "0x80858f5F8EFD2Ab6485Aba1A0B9557ED46C6ba0e" to null,
//        Sui
//        "0x83d6f864a6b0f16898376b486699aa6321eb6466d1daf6a2e3764a51908fe99d" to null,
    ]

    private let feePaymentMethod = FeePaymentMethod.stableCoin

    private let allowanceHelper = MultiSwapAllowanceHelper()
    private let marketKit = Core.shared.marketKit
    private let networkManager = Core.shared.networkManager
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let tronKitManager = Core.shared.tronAccountManager.tronKitManager
    private let stellarKitManager = Core.shared.stellarKitManager
    private let localStorage = Core.shared.localStorage
    private let evmFeeEstimator = EvmFeeEstimator()
    private var logger: Logger?

    private var tokenPairs: [Token: AbToken] = [:]
    private var mevProtectionHelper = MevProtectionHelper()

    init() {
        syncPools()
    }

    var id: String { "allbridge" }
    var name: String { "AllBridge" }
    var description: String { "DEX" }
    var icon: String { "swap_provider_allbridge" }

    private func syncPools() {
        Task { [weak self, networkManager, baseUrl] in
            do {
                let abTokens: [AbToken] = try await networkManager.fetch(url: "\(baseUrl)/tokens")
                self?.logger?.log(level: .debug, message: "AllBridge: Handle \(abTokens.count) tokens.")
                self?.sync(abTokens: abTokens)
            } catch {
                self?.logger?.log(level: .debug, message: "AllBridge: Error when fetching tokens \(error)")
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

        logger?.log(level: .debug, message: "AllBridge: Create \(pairs.count) pairs.")
        tokenPairs = pairs
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        tokenPairs[tokenIn] != nil && tokenPairs[tokenOut] != nil
    }

    private func resolveDestination(recipient: String?, token: Token) async throws -> String {
        if let recipient {
            return recipient
        }

        return try await DestinationHelper.resolveDestination(token: token).address
    }

    private func proxyFee(proxyAddress _: String, amountIn: Decimal) -> Decimal {
        // need to fetch it from contract
        let feeBP: Decimal = 100
        return amountIn * feeBP / 10000
    }

    private func gasFee(source: String, destination: String, messenger: String = "ALLBRIDGE") async throws -> GasFee {
        let parameters: Parameters = [
            "sourceToken": source,
            "destinationToken": destination,
            "messenger": messenger,
        ]
        return try await networkManager.fetch(url: "\(baseUrl)/gas/fee", parameters: parameters)
    }

    private func pendingInfo(amount: String, source: String, destination: String) async throws -> PendingInfo {
        let parameters: Parameters = [
            "amount": amount,
            "sourceToken": source,
            "destinationToken": destination,
        ]

        return try await networkManager.fetch(url: "\(baseUrl)/pending/info", parameters: parameters)
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
            let proxyFee = proxyFee(proxyAddress: proxyAddress, amountIn: amountIn)
            resAmountIn -= proxyFee

            if resAmountIn < 0 {
                throw SwapError.lessThanRequireFee
            }
        }

        if feePaymentMethod == .stableCoin {
            let gasFee: GasFee = try await gasFee(source: sourceToken, destination: destinationToken)
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

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        guard let abTokenIn = tokenPairs[tokenIn] else {
            throw SwapError.unsupportedTokenIn
        }

        let crosschain = tokenIn.blockchainType != tokenOut.blockchainType

        let amountOut = try await estimateAmountOut(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
        logger?.log(level: .debug, message: "AllBridge: TokenIn: \(tokenIn.coin.code) | TokenOut: \(tokenOut.coin.code)")
        logger?.log(level: .debug, message: "AllBridge: Quote Crosschain: \(crosschain) | amountOut = \(amountOut.description)")

        let bridgeAddress = abTokenIn.bridgeAddress

        if tokenIn.blockchainType.isEvm {
            let router = proxies[bridgeAddress] ?? bridgeAddress

            let state = await allowanceHelper.allowanceState(spenderAddress: .init(raw: router), token: tokenIn, amount: amountIn)
            logger?.log(level: .debug, message: "AllBridge: Allowance = \(state)")

            return EvmMultiSwapQuote(expectedBuyAmount: amountOut, allowanceState: state)
        } else if tokenIn.blockchainType == .tron {
            let state = await allowanceHelper.allowanceState(spenderAddress: .init(raw: bridgeAddress), token: tokenIn, amount: amountIn)
            logger?.log(level: .debug, message: "AllBridge: Allowance = \(state)")

            return EvmMultiSwapQuote(expectedBuyAmount: amountOut, allowanceState: state)
        } else if tokenIn.blockchainType == .stellar {
            return MultiSwapQuote(expectedBuyAmount: amountOut)
        }

        throw SwapError.unsupportedTokenIn
    }

    private func transactionParameters(tokenIn: Token, tokenOut: Token, recipient: String?, crosschain: Bool, amountIn: Decimal, expectedAmountOutMin: Decimal) async throws -> Parameters {
        guard let abTokenIn = tokenPairs[tokenIn] else {
            throw SwapError.unsupportedTokenIn
        }

        guard let abTokenOut = tokenPairs[tokenOut] else {
            throw SwapError.unsupportedTokenOut
        }

        guard let amount = tokenIn.rawAmount(amountIn) else {
            throw SwapError.invalidAmount
        }

        let sender = try await resolveDestination(recipient: recipient, token: tokenIn)
        let recipient = try await resolveDestination(recipient: recipient, token: tokenOut)

        guard let amountOutMinInt = tokenOut.rawAmount(expectedAmountOutMin) else {
            throw SwapError.invalidAmount
        }

        var parameters: Parameters = [
            "amount": amount.description,
            "sender": sender,
            "recipient": recipient,
            "sourceToken": abTokenIn.tokenAddress,
            "destinationToken": abTokenOut.tokenAddress,
        ]

        if crosschain {
            parameters["messenger"] = "ALLBRIDGE"
            parameters["feePaymentMethod"] = feePaymentMethod.rawValue
        } else {
            parameters["minimumReceiveAmount"] = amountOutMinInt.description
        }

        return parameters
    }

    func fetchTransactionData<T: ImmutableMappable>(tokenIn: Token, tokenOut: Token, recipient: String?, crosschain: Bool, amountIn: Decimal, expectedAmountOutMin: Decimal) async throws -> T {
        let parameters = try await transactionParameters(tokenIn: tokenIn, tokenOut: tokenOut, recipient: recipient, crosschain: crosschain, amountIn: amountIn, expectedAmountOutMin: expectedAmountOutMin)

        let path = crosschain ? "bridge" : "swap"

        return try await networkManager.fetch(url: "\(baseUrl)/raw/\(path)", parameters: parameters)
    }

    func fetchStellarData(tokenIn: Token, tokenOut: Token, recipient: String?, crosschain: Bool, amountIn: Decimal, expectedAmountOutMin: Decimal) async throws -> Data {
        let parameters = try await transactionParameters(tokenIn: tokenIn, tokenOut: tokenOut, recipient: recipient, crosschain: crosschain, amountIn: amountIn, expectedAmountOutMin: expectedAmountOutMin)

        let path = crosschain ? "bridge" : "swap"

        return try await networkManager.fetchData(url: "\(baseUrl)/raw/\(path)", parameters: parameters)
    }

    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> ISwapFinalQuote {
        let crosschain = tokenIn.blockchainType != tokenOut.blockchainType

        let amountOut = try await estimateAmountOut(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)

        if tokenIn.blockchainType.isEvm {
            let evmResponse: EvmSwapResponse = try await fetchTransactionData(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: recipient,
                crosschain: crosschain,
                amountIn: amountIn,
                expectedAmountOutMin: amountOut
            )
            guard let input = evmResponse.data.hs.hexData else {
                throw SwapError.convertionError
            }

            let router = proxies[evmResponse.to] ?? evmResponse.to

            let transactionData = try TransactionData(
                to: .init(hex: router),
                value: evmResponse.value.flatMap { BigUInt($0) } ?? BigUInt(0),
                input: input
            )

            let blockchainType = tokenIn.blockchainType
            let gasPriceData = transactionSettings?.gasPriceData
            var evmFeeData: EvmFeeData?
            var transactionError: Error?

            if let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper, let gasPriceData {
                do {
                    let _evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData)
                    evmFeeData = _evmFeeData

                    logger?.log(level: .debug, message: "AllBridge: EvmFeeData: \(evmFeeData?.gasLimit.description ?? "N/A") \(evmFeeData?.surchargedGasLimit.description ?? "N/A") \(evmFeeData?.l1Fee?.description ?? "N/A")")

                    try BaseEvmMultiSwapProvider.validateBalance(evmKitWrapper: evmKitWrapper, transactionData: transactionData, evmFeeData: _evmFeeData, gasPriceData: gasPriceData)
                } catch {
                    transactionError = error
                }
            }

            return EvmSwapFinalQuote(
                expectedBuyAmount: amountOut,
                transactionData: transactionData,
                transactionError: transactionError,
                slippage: crosschain ? nil : slippage,
                recipient: recipient,
                gasPrice: gasPriceData?.userDefined,
                evmFeeData: evmFeeData,
                nonce: transactionSettings?.nonce
            )
        } else if tokenIn.blockchainType == .tron {
            let createdTransaction: TronKit.CreatedTransactionResponse = try await fetchTransactionData(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: recipient,
                crosschain: crosschain,
                amountIn: amountIn,
                expectedAmountOutMin: amountOut
            )

            var totalFees: Int?
            var fees: [Fee] = []
            var transactionError: Error?

            if let tronKitWrapper = tronKitManager.tronKitWrapper {
                do {
                    let tronKit = tronKitWrapper.tronKit
                    let trxBalance = tronKit.trxBalance

                    let _fees = try await tronKit.estimateFee(createdTransaction: createdTransaction)
                    let _totalFees = _fees.calculateTotalFees()

                    var totalAmount = 0
                    if tokenIn.type.isNative, let sendAmount = tokenIn.rawAmount(amountIn), let sendAmountInt = Int(sendAmount.description) {
                        totalAmount += sendAmountInt
                        logger?.log(level: .debug, message: "Append to total amount TXR amountIn: \(sendAmountInt)")
                    }

                    totalAmount += _totalFees
                    fees = _fees
                    totalFees = _totalFees

                    if trxBalance < totalAmount {
                        throw TronSendHandler.TransactionError.insufficientBalance(balance: trxBalance)
                    }

                    logger?.log(level: .debug, message: "AllBridge: TronFeeData: \(totalFees?.description ?? "N/A") | totalAmount: \(totalAmount.description)")
                    logger?.log(level: .debug, message: "AllBridge: TronBalance = \(trxBalance.description) >= tx:\(totalAmount.description)")
                } catch {
                    logger?.log(level: .error, message: "AllBridge: error = \(error)")
                    transactionError = error
                }
            }

            return TronSwapFinalQuote(
                amountIn: amountIn,
                expectedAmountOut: amountOut,
                recipient: recipient,
                crosschain: crosschain,
                slippage: slippage,
                createdTransaction: createdTransaction,
                fees: fees,
                transactionError: transactionError
            )
        } else if tokenIn.blockchainType == .stellar {
            let transactionEnvelopeData: Data = try await fetchStellarData(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: recipient,
                crosschain: crosschain,
                amountIn: amountIn,
                expectedAmountOutMin: amountOut
            )

            let transactionEnvelope = String(data: transactionEnvelopeData, encoding: .utf8) ?? transactionEnvelopeData.base64EncodedString()

            var fee: Decimal?
            var transactionError: Error?

            do {
                if let stellarKit = stellarKitManager.stellarKit,
                   let baseToken = try marketKit.token(query: .init(blockchainType: .stellar, tokenType: .native))
                {
                    let stellarBalance = stellarKitManager.stellarKit?.account?.assetBalanceMap[.native]?.balance ?? 0

                    let estimatedInt = try stellarKit.estimateFee(transactionEnvelope: transactionEnvelope)
                    let estimated = Decimal(estimatedInt) / pow(10, baseToken.decimals)

                    fee = estimated
                    if stellarBalance < estimated {
                        throw StellarSendHandler.TransactionError.insufficientStellarBalance(balance: stellarBalance)
                    }

                    logger?.log(level: .debug, message: "AllBridge: StellarFee: \(estimated.description) | stellarBalance: \(stellarBalance.description)")
                }
            } catch {
                logger?.log(level: .error, message: "AllBridge: error = \(error)")
                transactionError = error
            }

            return StellarSwapFinalQuote(
                amountIn: amountIn,
                expectedAmountOut: amountOut,
                recipient: recipient,
                crosschain: crosschain,
                slippage: slippage,
                transactionEnvelope: transactionEnvelope,
                fee: fee,
                transactionError: transactionError
            )
        }

        throw SwapError.convertionError
    }

    func otherSections(tokenIn: Token, tokenOut _: Token, amountIn _: Decimal, transactionSettings _: TransactionSettings?) -> [SendDataSection] {
        [mevProtectionHelper.section(tokenIn: tokenIn)].compactMap { $0 }
    }

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    func swap(tokenIn: Token, tokenOut _: Token, amountIn _: Decimal, quote: ISwapFinalQuote) async throws {
        if let quote = quote as? EvmSwapFinalQuote {
            guard let transactionData = quote.transactionData else {
                throw SwapError.noTransactionData
            }

            guard let gasLimit = quote.evmFeeData?.surchargedGasLimit else {
                throw SwapError.noGasLimit
            }

            guard let gasPrice = quote.gasPrice else {
                throw SwapError.noGasPrice
            }

            guard let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
                throw SwapError.noEvmKitWrapper
            }

            do {
                _ = try await evmKitWrapper.send(
                    transactionData: transactionData,
                    gasPrice: gasPrice,
                    gasLimit: gasLimit,
                    privateSend: mevProtectionHelper.isActive,
                    nonce: quote.nonce
                )
            } catch {
                logger?.log(level: .error, message: "AllBridge SendEVM Error: \(error)")
                throw error
            }
        } else if let quote = quote as? TronSwapFinalQuote {
            guard let tronKitWrapper = tronKitManager.tronKitWrapper else {
                throw SwapError.noEvmKitWrapper
            }

            do {
                _ = try await tronKitWrapper.send(createdTranaction: quote.createdTransaction)
            } catch {
                logger?.log(level: .error, message: "AllBridge SendTron Error: \(error)")

                throw error
            }
        } else if let quote = quote as? StellarSwapFinalQuote {
            guard let account = Core.shared.accountManager.activeAccount, let keyPair = try? StellarKitManager.keyPair(accountType: account.type) else {
                throw SwapError.noStellarKit
            }

            do {
                _ = try await StellarKit.Kit.send(transactionEnvelope: quote.transactionEnvelope, keyPair: keyPair, testNet: false)
            } catch {
                logger?.log(level: .error, message: "AllBridge SendStellar Error: \(error)")

                throw error
            }
        }
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
        case noTransactionData
        case noGasPrice
        case noGasLimit
        case noEvmKitWrapper
        case noStellarKit
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
            chainSymbol = try map.value("chainSymbol")
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

    struct StellarSwapResponse: ImmutableMappable {
        let transactionEnvelope: String

        init(map: Map) throws {
            transactionEnvelope = try map.value("from")
        }
    }
}
