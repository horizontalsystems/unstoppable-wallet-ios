import Foundation
import RxSwift
import RxRelay
import RxCocoa

class RestorePrivateKeyViewModel {
    private let service: RestorePrivateKeyService
    private let disposeBag = DisposeBag()

    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)

    private var text = ""

    init(service: RestorePrivateKeyService) {
        self.service = service
    }

}

extension RestorePrivateKeyViewModel {

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    func onChange(text: String) {
        self.text = text
        cautionRelay.accept(nil)
    }

}

extension RestorePrivateKeyViewModel: IRestoreSubViewModel {

    func resolveAccountType() -> AccountType? {
        cautionRelay.accept(nil)

        do {
            return try service.accountType(text: text)
        } catch {
            cautionRelay.accept(Caution(text: "restore.private_key.invalid_key".localized, type: .error))
            return nil
        }
    }

    func clear() {
    }

}
