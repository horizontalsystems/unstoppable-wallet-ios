
import BigInt
import Foundation
import HsToolKit

/// Client side calculations, node discovery and network requests used to interact with Thorchain (specifically: Midgard service) in a read-only manner.
/// Real blockchain transactions must be performed elsewhere by the user with the information returned by this service.
/// Initialise with live (or testnet), then call performSwap() to receive latest addresses and all transaction details.
/// Alternatively, query the API static functions such as Thorchain.getSwapSlip() and Thorchain.getSwapMemo() for offline Thorchain support.
/// Use Thorchain on Main Thread only. All functions are non-blocking with asynchronous callbacks that are called back on main thread.
public class Thorchain {
    /// Which Thorchain network to connect to
    public enum Chain {
        case mainnet, testnet

        /// Midgard hostnames. Used for all Midgard requests except inbound_addresses which uses various random nodes, plus this.
        var midgardURL: URL {
            switch self {
            case .mainnet:
                return URL(string: "https://thornode.ninerealms.com")!
            case .testnet:
                return URL(string: "https://testnet.midgard.thorchain.info")!
            }
        }

        var urls: [URL] {
            switch self {
            case .mainnet:
                return [
                    URL(string: "https://thornode.ninerealms.com")!,
                    URL(string: "https://thornode.thorchain.liquify.com")!,
                ]
            case .testnet:
                return [
                    URL(string: "https://testnet.thornode.thorchain.info")!,
                ]
            }
        }
    }

    /// Defines services and ports
    public enum Service {
        case asgard, midgard
        public var port: Int {
            switch self {
            case .asgard:
                return 1317
            case .midgard:
                return 8080
            }
        }
    }

    /// Indicates which chain is being used by this Thorchain instance. Set on init.
    public private(set) var chain = Chain.mainnet

    let networkManager: NetworkManager

    /// Non-public storage of inbound addresses. User should query latestInboundAddresses instead.
    var latestAddressesStored: (inboundAddresses: [Midgard.InboundAddress], fetchedTime: Date)?

    /// Latest list of inbound addresses from `/thorchain/inbound_addresses`
    /// If it has been greater than 15 minutes since fetching, this returns nil (you should fetch again)
    public var latestInboundAddresses: [Midgard.InboundAddress]? {
        if let date = latestAddressesStored?.fetchedTime, date.timeIntervalSinceNow >= -15 * 60,
           let vaults = latestAddressesStored?.inboundAddresses
        {
            return vaults
        }
        return nil // No Vault loaded or time greater than 15 mins ago
    }

    /// Latest list of pools fetched from `/pools`
    public var latestMidgardPools: [Midgard.Pool]?

    /// Shared ephemeral session to use for all network requests. Delegate callbacks on Main Thread. Zero caching.
    let urlSession: URLSession

    /// Shared JSON decoder
    let jsonDecoder = JSONDecoder()

    /// 3rd party trusted Midgard URLs passed by user. If specified, these will be added to the list of hosts to query which increases trust.
    /// Specify as URL host[:port], e.g. "https://testnet.thornode.thorchain.info". The Thorchain framework will append standard paths "/..." to the hostname/IP.
    /// You would typically only use this if you run your own node for additional security/verification.
    let additionalTrustedMidgardURLs: [URL]

    /// Instantiate Thorchain object used to query Thorchain state machine and create memo's for transactions.
    /// - Parameters:
    ///   - networkManager: manager for https requests
    ///   - chain: Specify chain to use. Default mainnet.
    ///   - additionalTrustedMidgardURLs: (optional) If you run your own node(s), specify here for additional verification. Specify as URL host[:port], e.g. "https://testnet.midgard.thorchain.info". The Thorchain framework will append standard paths e.g. `/thorchain/inbound_addresses` to query the service.
    public init(networkManager: NetworkManager, withChain chain: Chain = .mainnet, additionalTrustedMidgardURLs: [URL] = []) {
        self.networkManager = networkManager
        self.chain = chain
        self.additionalTrustedMidgardURLs = additionalTrustedMidgardURLs
        let urlConfiguration = URLSessionConfiguration.ephemeral
        urlConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        urlConfiguration.timeoutIntervalForRequest = 10
        urlConfiguration.timeoutIntervalForResource = 10
        let networkDelegateQueue = OperationQueue()
        networkDelegateQueue.underlyingQueue = DispatchQueue.main
        urlSession = URLSession(configuration: urlConfiguration, delegate: nil, delegateQueue: networkDelegateQueue)
        mainThreadCheck()
    }

    // Check for Router. If one specified, we MUST use this (via .deposit() function) in lieu of the ChainAddress specified.
    // e.g. https://ropsten.etherscan.io/address/0xe0a63488e677151844e70623533c22007dc57c9e#code -- Testnet
    // https://etherscan.io/address/0x42a5ed456650a09dc10ebc6361a7480fdd61f27b#code -- Mainnet
    private func routedSwapDetails(address: Midgard.InboundAddress, asset: Asset, amount: AssetAmount, memo: String) throws -> TxParams? {
        // Check for Router.
        guard let router = address.router, router != "" else {
            return nil
        }

        if asset.chain != "ETH" {
            throw SwapError.routerNotSupported
        }

        // Split "TOKEN-0xcontract" into "TOKEN" and "0xcontract"
        let fromAssetSymbolSplit = asset.symbol.split(separator: "-")
        let zeroAddress = "0x0000000000000000000000000000000000000000"
        let assetAddress = fromAssetSymbolSplit.count == 2 ? fromAssetSymbolSplit.last!.lowercased() : zeroAddress // Use "0xcontract". "ETH" uses "0x0".

        guard (assetAddress == zeroAddress && asset.memoString == "ETH.ETH") || // Should be 0x0 for ETH
            (asset.chain == "ETH" && asset.symbol != "ETH" && assetAddress.count == 42 && assetAddress.hasPrefix("0x"))
        else { // or a valid ERC20 address
            throw SwapError.notValidRouterAddress
        }

        // Package up into struct with all info required to call the deposit() function
        let transactionDetails = TxParams.RoutedTransaction(
            router: router,
            payableVaultAddress: address.address,
            assetAddress: String(assetAddress),
            amount: amount,
            memo: memo
        )

        return .routedSwap(transactionDetails)
    }

    /// Calls Midgard API's, uses internal calculations and memo functions to calculate all the required parameters for you to perform an Asset swap using Thorchain.
    /// - Parameters:
    ///   - fromAsset: Asset you are converting FROM. For example .BNB or .BTC.  If this is .RUNE, you must include a toAsset.
    ///   - toAsset: (optional) Asset you are converting TO. If nil or unspecified, this is a "single swap" which converts to RUNE. To perform a "double swap" (fromAsset > RUNE, RUNE > toAsset) specify here. e.g. .ETH
    ///   - destinationAddress: Destination address. This is where the Thorchain nodes will send your output funds. Ensure this is correct and in the format for your toAsset.
    ///   - fromAssetAmount: Amount of your fromAsset you wish to swap. Specified in BaseAmount which is the large unit (e.g. 100000000 for 1.0 BTC). Alternatively use AssetAmount(x, decimal: 8).baseAmount for x units, e.g. 1.0 BTC.
    ///   - limitProtection: Specify true to add limit to end of transaction memo's. Default true.
    ///   - completionHandler: Completion handler is called on main thread with an optional TxParams value specifying details of the transaction. You should *not* cache this object for more than 15 minutes. Typically this object is returned to display calculations to the user, who then manually authorises the swap very soon after (if more than 15 minutes, get a fresh TxParams). Use the address and memo in the TxParams to send funds to the appropriate vault or router. For additional validation, you can check that the TxParams address has a large amount of funds in it, indicating it is a valid active vault.
    public func performSwap(fromAsset: Asset,
                            toAsset: Asset,
                            destinationAddress: String,
                            fromAssetAmount: AssetAmount,
                            limitProtection: Bool = true) async throws -> (TxParams, SwapCalculations)
    {
        guard fromAsset != toAsset else {
            throw SwapError.sameAssets
        }

        var inboundAddresses = try await getInboundAddresses()
        guard !inboundAddresses.isEmpty else {
            throw SwapError.inboundAddressesNotFound
        }

        // Artificially add THOR.RUNE into InboundAddresses because this is always supported via Deposit() into the network. Logic on dealing with this added later.
        inboundAddresses.append(.runeNative)

        // Get the best Asgard Vault asset address at the last possible time before doing the transaction. An address is good for 15 minutes, but do not cache at all.
        // If a recipient address is cached and funds sent to an old (retired) asgard vault, the funds are lost.
        // If funds are sent to an active vault but your transaction fees are too low and it takes several hours or more, your funds may be lost.
        guard let inboundAddress = inboundAddresses.first(where: { $0.chain.uppercased() == fromAsset.chain.uppercased() }) else {
            throw SwapError.cantFoundFromAsset
        }

        let pools = try await getMidgardPools()

        if toAsset == .RuneNative || fromAsset == .RuneNative {
            // Single Swap to/from THOR.RUNE in a single pool.

            // Choose which way to go
            let toRune = (toAsset == .RuneNative)
            let nonRuneAsset: Asset = toRune ? fromAsset : toAsset

            let pool = try pools.get(nonRuneAsset.memoString)

            // Check Midgard pool status is Available
            guard pool.isActive else {
                throw SwapError.poolNotActive(asset: pool.asset)
            }

            // Extract RUNE and nonRuneAsset (e.g. BNB) balances from the pool.
            let poolRuneBalance = BaseAmount(BigInt(stringLiteral: pool.balance_rune))
            let poolAssetBalance = BaseAmount(BigInt(stringLiteral: pool.balance_asset))
            let poolAssets = Thorchain.PoolData(assetBalance: poolAssetBalance, runeBalance: poolRuneBalance)

            // Calculate some items for the user to review (slippage, output, fee)
            // toRune:  set to 'true' if user is converting asset to RUNE.  false if RUNE to asset.
            let slip: Decimal = Thorchain.getSwapSlip(inputAmount: fromAssetAmount.baseAmount, pool: poolAssets, toRune: toRune) // percentage 0.0 - 1.0 (100%)
            let output: BaseAmount = Thorchain.getSwapOutput(inputAmount: fromAssetAmount.baseAmount, pool: poolAssets, toRune: toRune) // rune (if true), asset (if false). Inclusive of liquidity fees. What you'll *actually* get.
            let fee: BaseAmount = Thorchain.getSwapFee(inputAmount: fromAssetAmount.baseAmount, pool: poolAssets, toRune: toRune) // fee in whatever unit the output asset is.

            // Package together in struct ready to send to user.
            let swapCalculations = SwapCalculations(slip: slip,
                                                    output: output,
                                                    fee: fee,
                                                    assetDepthFirstSwap: poolAssets,
                                                    assetDepthSecondSwap: nil)

            let memoLimit: BaseAmount? = limitProtection ? BaseAmount(output.amount / 10 * 9) : nil // * 0.9 protection limit
            let swapMemo = Thorchain.getSwapMemo(asset: toAsset, destinationAddress: destinationAddress, limit: memoLimit)

            if let txParams = try routedSwapDetails(
                    address: inboundAddress,
                    asset: fromAsset,
                    amount: fromAssetAmount,
                    memo: swapMemo) {

                return (txParams, swapCalculations) // Success
            }

            if fromAsset == .RuneNative {
                // RUNE >> Asset
                let nativeDeposit = TxParams.RuneDepositTransaction(memo: swapMemo, amount: fromAssetAmount)
                let txParams = Thorchain.TxParams.runeNativeDeposit(nativeDeposit)
                return (txParams, swapCalculations)
            } else {
                // Asset >> RUNE
                let transactionDetails = TxParams.RegularTransaction(recipient: inboundAddress.address, amount: fromAssetAmount, memo: swapMemo)
                let txParams = Thorchain.TxParams.regularSwap(transactionDetails)
                return (txParams, swapCalculations)
            }
        }

        // Double Swap [fromAsset] >> [toAsset]

        // Extract the relevant balance from pools
        let fromPool = try pools.get(fromAsset.memoString)
        let toPool = try pools.get(toAsset.memoString)

        // Check Midgard pool status is Available for both pools
        guard fromPool.isActive, toPool.isActive else {
            throw SwapError.poolNotActive(asset: fromPool.isActive ? toPool.asset : fromPool.asset)
        }

        // Extract asset balances from the pools.
        let fromPoolAssetBalance = BaseAmount(BigInt(stringLiteral: fromPool.balance_asset))
        let fromPoolRuneBalance = BaseAmount(BigInt(stringLiteral: fromPool.balance_rune))
        let fromPoolData = Thorchain.PoolData(assetBalance: fromPoolAssetBalance, runeBalance: fromPoolRuneBalance)

        let toPoolAssetBalance = BaseAmount(BigInt(stringLiteral: toPool.balance_asset))
        let toPoolRuneBalance = BaseAmount(BigInt(stringLiteral: toPool.balance_rune))
        let toPoolData = Thorchain.PoolData(assetBalance: toPoolAssetBalance, runeBalance: toPoolRuneBalance)

        // Calculate some items for the user to review (slippage, output, fee)
        let slip: Decimal = Thorchain.getDoubleSwapSlip(inputAmount: fromAssetAmount.baseAmount, pool1: fromPoolData, pool2: toPoolData)
        let output: BaseAmount = Thorchain.getDoubleSwapOutput(inputAmount: fromAssetAmount.baseAmount, pool1: fromPoolData, pool2: toPoolData)
        let fee: BaseAmount = Thorchain.getDoubleSwapFee(inputAmount: fromAssetAmount.baseAmount, pool1: fromPoolData, pool2: toPoolData)

        // Package together in struct ready to send to user.
        let swapCalculations = SwapCalculations(slip: slip,
                                                output: output,
                                                fee: fee,
                                                assetDepthFirstSwap: fromPoolData,
                                                assetDepthSecondSwap: toPoolData)

        let memoLimit: BaseAmount? = limitProtection ? BaseAmount(output.amount / 10 * 9) : nil // * 0.9 protection limit
        let swapMemo = Thorchain.getSwapMemo(asset: toAsset, destinationAddress: destinationAddress, limit: memoLimit)

        debugLog("Thorchain: Successfully calculated Swap parameters\n")
        debugLog("Swapping \(fromAssetAmount.amount.truncate(8)) \(fromAsset.ticker) to \(toAsset.ticker)")
        debugLog("Slip: \((slip * 100).truncate(4)) %")
        debugLog("Output (amount of asset received): \(output.assetAmount.amount.truncate(8)) \(toAsset.ticker)")
        debugLog("Fee: \(fee.assetAmount.amount.truncate(4)) \(toAsset.ticker)\n")

        // Check for Router.
        if let txParams = try routedSwapDetails(
                address: inboundAddress,
                asset: fromAsset,
                amount: fromAssetAmount,
                memo: swapMemo) {

            return (txParams, swapCalculations) // Success
        }

        let transactionDetails = TxParams.RegularTransaction(recipient: inboundAddress.address, amount: fromAssetAmount, memo: swapMemo)
        let txParams = Thorchain.TxParams.regularSwap(transactionDetails)
        return (txParams, swapCalculations)
    }

    /// Simple debug log - outputs text when in DEBUG builds
    /// - Parameter message: Input string directly "My Message". Are only evaluated if in debug build (for performance).
    func debugLog(_ message: @autoclosure () -> String) {
        #if DEBUG
            print(message())
        #endif
    }

    /// Internal check to warn consumers of this API that we must be on Main Thread.
    private func mainThreadCheck() {
        #if DEBUG
            if !Thread.current.isMainThread {
                print("Thorchain Caution: Please use on Main Thread. All functions are non-blocking with callbacks on main thread")
            }
        #endif
    }
}

public extension Thorchain {
    /// Final parameters for a Thorchain transaction. Do not cache because this address is only valid for ~15 minutes.
    /// Warning: Sending crypto to an old recipient from a retired (non-monitored) vault will result in loss of funds.
    /// Always use up to date TxParams
    enum TxParams {
        case regularSwap(RegularTransaction)
        case routedSwap(RoutedTransaction)
        case runeNativeDeposit(RuneDepositTransaction)

        public struct RegularTransaction {
            /// Transaction details. Represents all the information a client needs to perform their transaction into the Thorchain network.
            /// - Parameters:
            ///   - recipient: Address of recipient of transaction. Where to send funds to. Note: Due to frequent vault churns, this is only valid for 15minutes from creation of object. Returns 'nil' for recipient if queried greater than 15mins after creation from the Midgard API request.
            ///   - amount: Base Amount (eg 100000000 for 1.0 BTC)
            ///   - memo: Memo string to attach to the transaction. If an invalid memo string is sent, Thorchain will return the funds (minus a fee).
            public init(recipient: String, amount: AssetAmount, memo: String) {
                _recipient = recipient
                self.amount = amount
                self.memo = memo
            }

            private let _recipient: String
            /// Recipient address. Since this is only valid for 15 minutes, it is only returns the address if the time since creation of the txParams is less than 15 minutes old.
            /// If greater than 15 minutes old, returns nil. You should re-query getInboundAddresses() to get a new address.
            /// Before sending funds to this address, you should verify that this address has a large amount of funds in it, indicating it is a current active Asgard vault.
            public var recipient: String? { txCreationDate.timeIntervalSinceNow > -15 * 60 ? _recipient : nil }
            public let amount: AssetAmount
            public let memo: String
            private let txCreationDate = Date()
        }

        /// Transaction type that uses a Smart Contract deposit(address payable vault, address asset, uint amount, string memory memo)
        /// For example ETH Router: https://ropsten.etherscan.io/address/0xe0a63488e677151844e70623533c22007dc57c9e#code
        public struct RoutedTransaction {
            /// Transaction details to send to Router smart contracts .deposit() function.
            /// - Parameters:
            ///   - router: Address of Router Smart Contract
            ///   - payableVaultAddress: Payable vault address - the final Asgard vault address (the Router will forward to this)
            ///   - assetAddress: Asset address (e.g. ERC20 Contract Address, or 0x0 for ETH)
            ///   - amount: Base Amount of asset to send
            ///   - memo: Memo string
            public init(router: String, payableVaultAddress: String, assetAddress: String, amount: AssetAmount, memo: String) {
                routerContractAddress = router
                _payableVaultAddress = payableVaultAddress
                self.assetAddress = assetAddress
                self.amount = amount
                self.memo = memo
            }

            public let routerContractAddress: String
            private let _payableVaultAddress: String
            public var payableVaultAddress: String? { txCreationDate.timeIntervalSinceNow > -15 * 60 ? _payableVaultAddress : nil }
            public let assetAddress: String // 0x0 for ETH. 0xabc for ERC20 Contract.
            public let amount: AssetAmount
            public let memo: String
            private let txCreationDate = Date()
        }

        /// Transaction type representing a RuneNative Deposit() call into the Thorchain network with AssetAmount and Memo.
        /// Used for THOR.RUNE > Other swaps, and Bond / Unbond
        public struct RuneDepositTransaction {
            public init(memo: String, amount: AssetAmount) {
                self.memo = memo
                self.amount = amount
            }

            public let amount: AssetAmount
            public let memo: String
        }
    }

    /// Contains a list of information to display to the user in order to inform them of an estimated result if they proceed.
    struct SwapCalculations {
        /// Percentage slippage. 0.0 to 1.0
        public let slip: Decimal

        /// Amount of the swap asset they will receive
        public let output: BaseAmount

        /// Fee (in RUNE)
        public let fee: BaseAmount

        /// Asset depths from Midgard API for the first swap.
        public let assetDepthFirstSwap: Thorchain.PoolData

        /// Asset depths from Midgard API for the second swap (if applicable).
        /// Nil for single swap Rune <--> Asset transactions.
        public let assetDepthSecondSwap: Thorchain.PoolData?
    }
}
