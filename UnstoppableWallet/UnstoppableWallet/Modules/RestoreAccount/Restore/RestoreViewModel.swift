import Foundation
import RxSwift
import RxRelay
import RxCocoa

class RestoreViewModel {
    private let mnemonicViewModel: RestoreMnemonicViewModel
    private let privateKeyViewModel: RestorePrivateKeyViewModel

    private let restoreTypeRelay = BehaviorRelay<RestoreType>(value: .mnemonic)
    private let proceedRelay = PublishRelay<AccountType>()

    init(mnemonicViewModel: RestoreMnemonicViewModel, privateKeyViewModel: RestorePrivateKeyViewModel) {
        self.mnemonicViewModel = mnemonicViewModel
        self.privateKeyViewModel = privateKeyViewModel
    }

}

extension RestoreViewModel {

    var restoreTypeDriver: Driver<RestoreType> {
        restoreTypeRelay.asDriver()
    }

    var proceedSignal: Signal<AccountType> {
        proceedRelay.asSignal()
    }

    func onSelect(restoreType: RestoreType) {
        guard restoreTypeRelay.value != restoreType else {
            return
        }

        switch restoreTypeRelay.value {
        case .mnemonic:
            mnemonicViewModel.clear()
        case .privateKey:
            privateKeyViewModel.clear()
        }

        restoreTypeRelay.accept(restoreType)
    }

    func onTapProceed() {
        switch restoreTypeRelay.value {
        case .mnemonic:
            if let accountType = mnemonicViewModel.resolveAccountType() {
                proceedRelay.accept(accountType)
            }
        case .privateKey:
            if let accountType = privateKeyViewModel.resolveAccountType() {
                proceedRelay.accept(accountType)
            }
        }
    }

}

extension RestoreViewModel {

    enum RestoreType: CaseIterable {
        case mnemonic
        case privateKey

        var title: String {
            switch self {
            case .mnemonic: return "restore.restore_type.mnemonic".localized
            case .privateKey: return "restore.restore_type.private_key".localized
            }
        }
    }

}
