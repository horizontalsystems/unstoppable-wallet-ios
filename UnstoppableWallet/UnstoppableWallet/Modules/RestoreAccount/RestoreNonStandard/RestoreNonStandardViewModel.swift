import Foundation
import RxSwift
import RxRelay
import RxCocoa

class RestoreNonStandardViewModel {
    private let mnemonicViewModel: RestoreMnemonicNonStandardViewModel

    private let proceedRelay = PublishRelay<AccountType>()

    init(mnemonicViewModel: RestoreMnemonicNonStandardViewModel) {
        self.mnemonicViewModel = mnemonicViewModel
    }

}

extension RestoreNonStandardViewModel {

    var proceedSignal: Signal<AccountType> {
        proceedRelay.asSignal()
    }

    func onTapProceed() {
        if let accountType = mnemonicViewModel.resolveAccountType() {
            proceedRelay.accept(accountType)
        }
    }

}
