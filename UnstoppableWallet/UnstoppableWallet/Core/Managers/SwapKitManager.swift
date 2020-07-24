import UniswapKit
import EthereumKit

class SwapKitManager {
    private var uniswapKit: UniswapKit.Kit?

    private let ethereumKitManager: EthereumKitManager

    public init(ethereumKitManager: EthereumKitManager) {
        self.ethereumKitManager = ethereumKitManager
    }

    public func kit(account: Account) -> ISwapKit? {
        if let uniswapKit = uniswapKit {
            return uniswapKit
        }

        guard let ethereumKit = try? ethereumKitManager.ethereumKit(account: account) else {
            return nil
        }

        uniswapKit = try? UniswapKit.Kit.instance(ethereumKit: ethereumKit)
        return uniswapKit
    }

}

extension UniswapKit.Kit: ISwapKit {
}