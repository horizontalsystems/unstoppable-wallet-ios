
import Foundation

// TODO: To save GAS, Convert 'SWAP' to '=', 'DONATE' to '%', 'WITHDRAW' to '-' and 'ADD' to '+'. Also modify unit tests.
// https://docs.thorchain.org/developers/transaction-memos


/// Memo extensions
/// Logic implemented as per
/// https://gitlab.com/thorchain/asgardex-common/asgardex-util/-/blob/master/src/memo.ts
extension Thorchain {
    
    /// Memo to swap.
    /// See https://docs.thorchain.org/developers/transaction-memos#transactions
    /// - Parameters:
    ///   - asset: Asset to swap to (e.g. if destinationAddress is a 'tthor...' then asset would be 'THOR.RUNE')
    ///   - destinationAddress: Destination address to swap to. If address is empty, it sends back to self. This should be a wallet address controlled by you: Thorchain will send funds here. Be careful when using testnet vs main that you have a valid address for the network you are operating on.
    ///   - limit: Price protection. If the value isn't achieved then it is refunded. i.e. set 10000000 to be guaranteed a minimum of 1 full asset. If LIM is ommitted or nil, then there is no price protection.
    /// - Returns: Swap memo
    public static func getSwapMemo(asset: Asset, destinationAddress: String = "", limit: BaseAmount? = nil) -> String {
        assert(destinationAddress.count > 0)  // No empty destination addresses allowed (sending asset back to itself is supported in Thorchain, but pointless here)
        return "SWAP:\(asset.memoString):\(destinationAddress):\(limit != nil ? String(limit!.amount) : "")"
    }
    
    
    /// Memo to deposit.
    /// Memo is based on definition in https://gitlab.com/thorchain/thornode/-/blob/develop/x/thorchain/memo/memo.go#L35
    /// - Parameters:
    ///   - asset: Asset to deposit into a specified pool
    ///   - address: (optional) For cross-chain deposits, an address is needed to cross-reference addresses
    /// - Returns: Deposit memo
    public static func getDepositMemo(asset: Asset, address: String = "") -> String {
        "ADD:\(asset.memoString):\(address)"
    }
    
    
    /// Memo to withdraw.
    /// https://docs.thorchain.org/developers/transaction-memos#transactions
    /// - Parameters:
    ///   - asset: Asset to withdraw from a pool
    ///   - percent: Percent (0-100%)
    ///   - targetAsset: (optional) To withdraw asymmetrically. Specify the asset, eg "THOR.RUNE" or   (eg "BTC.BTC").
    /// - Returns: Withdraw memo.
    public static func getWithdrawMemo(asset: Asset, percent: Double, targetAsset: Asset? = nil) -> String {
        var target = ""
        if let targetAsset = targetAsset {
            target = targetAsset.memoString
        }
        // Accept percent between 0 - 100 only
        let percentClamped = min( max(percent, 0), 100)
        
        // Calculate percent into basis points (0-10000, where 100% = 10000)
        let points = Int(percentClamped * 100)
        assert(points >= 0 && points <= 10000)
        
        return "WITHDRAW:\(asset.memoString):\(points):\(target)"
    }

    /// Memo to switch.
    /// Memo is based on definition in https://gitlab.com/thorchain/thornode/-/blob/develop/x/thorchain/memo/memo.go#L55
    /// - Parameter address: Address to send amounts to
    /// - Returns: Switch memo.
    public static func getSwitchMemo(address: String) -> String {
        "SWITCH:\(address)"
    }
    
    
    /// Memo to bond
    /// Memo is based on definition in https://gitlab.com/thorchain/thornode/-/blob/develop/x/thorchain/memo/memo.go#L55
    /// https://docs.thorchain.org/thornodes/joining#2-send-bond
    /// - Parameter thorAddress: THOR address to send amounts to
    /// - Returns: Bond memo
    public static func getBondMemo(thorAddress: String) -> String {
        "BOND:\(thorAddress)"
    }


    /// Memo to unbond
    /// Memo is based on definition in https://gitlab.com/thorchain/thornode/-/blob/develop/x/thorchain/memo/memo.go#L55
    /// https://docs.thorchain.org/thornodes/leaving#unbonding
    /// - Parameters:
    ///   - thorAddress: THOR address unbond from
    ///   - units: Base Amount of units to unbond
    /// - Returns: Unbond memo
    public static func getUnbondMemo(thorAddress: String, units: BaseAmount) -> String {
        "UNBOND:\(thorAddress):\(units.amount)"
    }

    
    /// Memo to leave
    /// Memo is based on definition in https://gitlab.com/thorchain/thornode/-/blob/develop/x/thorchain/memo/memo.go#L55
    /// https://docs.thorchain.org/thornodes/leaving#leaving
    /// - Parameter thorAddress: THOR address to leave from
    /// - Returns: Leave memo
    public static func getLeaveMemo(thorAddress: String) -> String {
        "LEAVE:\(thorAddress)"
    }
}
