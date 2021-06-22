import Foundation
import RxCocoa
import RxSwift

class SwapSettingsViewModel {
    private let disposeBag = DisposeBag()
    private(set) var dexManager: ISwapDexManager

    private let providerNameRelay = BehaviorRelay<String?>(value: nil)

    init(dexManager: ISwapDexManager) {
        self.dexManager = dexManager

        subscribe(disposeBag, dexManager.dexUpdated) { [weak self] dex in
            self?.providerNameRelay.accept(self?.providerName)
        }
    }

}

extension SwapSettingsViewModel {

    var providerName: String? {
        dexManager.dex?.provider.rawValue
    }

    var providerNameDriver: Driver<String?> {
        providerNameRelay.asDriver()
    }

}
