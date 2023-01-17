import Foundation
import RxSwift
import RxRelay
import RxCocoa

class RestoreNonStandardViewModel {
    private let service: RestoreService
    private let mnemonicViewModel: RestoreMnemonicNonStandardViewModel

    private let proceedRelay = PublishRelay<(String, AccountType)>()

    init(service: RestoreService, mnemonicViewModel: RestoreMnemonicNonStandardViewModel) {
        self.service = service
        self.mnemonicViewModel = mnemonicViewModel
    }

}

extension RestoreNonStandardViewModel {

    var proceedSignal: Signal<(String, AccountType)> {
        proceedRelay.asSignal()
    }

    var namePlaceholder: String {
        service.defaultAccountName
    }

    func onChange(name: String) {
        service.name = name
    }

    func onTapProceed() {
        if let accountType = mnemonicViewModel.resolveAccountType() {
            proceedRelay.accept((service.resolvedName, accountType))
        }
    }

}
