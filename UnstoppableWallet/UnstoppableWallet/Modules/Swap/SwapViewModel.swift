import Foundation

class SwapViewModel {
    private(set) var dexManager: ISwapDexManager

    init(dexManager: ISwapDexManager) {
        self.dexManager = dexManager
    }

}
