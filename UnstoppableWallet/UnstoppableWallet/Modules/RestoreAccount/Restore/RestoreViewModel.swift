import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol IRestoreSubViewModel: AnyObject {
    func resolveAccountType() -> AccountType?
    func clear()
}

class RestoreViewModel {
    private let service: RestoreService
    private let mnemonicViewModel: IRestoreSubViewModel
    private let privateKeyViewModel: IRestoreSubViewModel

    private let restoreTypeRelay = BehaviorRelay<RestoreType>(value: .mnemonic)
    private let proceedRelay = PublishRelay<(String, AccountType)>()

    init(service: RestoreService, mnemonicViewModel: IRestoreSubViewModel, privateKeyViewModel: IRestoreSubViewModel) {
        self.service = service
        self.mnemonicViewModel = mnemonicViewModel
        self.privateKeyViewModel = privateKeyViewModel
    }

    private var subViewModel: IRestoreSubViewModel {
        switch restoreTypeRelay.value {
        case .mnemonic: return mnemonicViewModel
        case .privateKey: return privateKeyViewModel
        }
    }

}

extension RestoreViewModel {

    var restoreTypeDriver: Driver<RestoreType> {
        restoreTypeRelay.asDriver()
    }

    var proceedSignal: Signal<(String, AccountType)> {
        proceedRelay.asSignal()
    }

    var namePlaceholder: String {
        service.defaultAccountName
    }

    func onChange(name: String) {
        service.name = name
    }

    func onSelect(restoreType: RestoreType) {
        guard restoreTypeRelay.value != restoreType else {
            return
        }

        subViewModel.clear()
        restoreTypeRelay.accept(restoreType)
    }

    func onTapProceed() {
        if let accountType = subViewModel.resolveAccountType() {
            proceedRelay.accept((service.resolvedName, accountType))
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
