import Foundation
import RxSwift
import RxRelay
import RxCocoa

class PrivateKeysViewModel {
    private let service: PrivateKeysService

    private let openUnlockRelay = PublishRelay<()>()
    private let openEvmPrivateKeyRelay = PublishRelay<AccountType>()
    private let openBip32RootKeyRelay = PublishRelay<AccountType>()
    private let openAccountExtendedPrivateKeyRelay = PublishRelay<AccountType>()

    private var unlockRequest: UnlockRequest = .evmPrivateKey

    init(service: PrivateKeysService) {
        self.service = service
    }

}

extension PrivateKeysViewModel {

    var openUnlockSignal: Signal<()> {
        openUnlockRelay.asSignal()
    }

    var openEvmPrivateKeySignal: Signal<AccountType> {
        openEvmPrivateKeyRelay.asSignal()
    }

    var openBip32RootKeySignal: Signal<AccountType> {
        openBip32RootKeyRelay.asSignal()
    }

    var openAccountExtendedPrivateKeySignal: Signal<AccountType> {
        openAccountExtendedPrivateKeyRelay.asSignal()
    }

    var showEvmPrivateKey: Bool {
        service.evmPrivateKeySupported
    }

    var showBip32RootKey: Bool {
        service.bip32RootKeySupported
    }

    var showAccountExtendedPrivateKey: Bool {
        service.accountExtendedPrivateKeySupported
    }

    func onUnlock() {
        switch unlockRequest {
        case .evmPrivateKey: openEvmPrivateKeyRelay.accept(service.accountType)
        case .bip32RootKey: openBip32RootKeyRelay.accept(service.accountType)
        case .accountExtendedPrivateKey: openAccountExtendedPrivateKeyRelay.accept(service.accountType)
        }
    }

    func onTapEvmPrivateKey() {
        if service.isPasscodeSet {
            unlockRequest = .evmPrivateKey
            openUnlockRelay.accept(())
        } else {
            openEvmPrivateKeyRelay.accept(service.accountType)
        }
    }

    func onTapBip32RootKey() {
        if service.isPasscodeSet {
            unlockRequest = .bip32RootKey
            openUnlockRelay.accept(())
        } else {
            openBip32RootKeyRelay.accept(service.accountType)
        }
    }

    func onTapAccountExtendedPrivateKey() {
        if service.isPasscodeSet {
            unlockRequest = .accountExtendedPrivateKey
            openUnlockRelay.accept(())
        } else {
            openAccountExtendedPrivateKeyRelay.accept(service.accountType)
        }
    }

}

extension PrivateKeysViewModel {

    enum UnlockRequest {
        case evmPrivateKey
        case bip32RootKey
        case accountExtendedPrivateKey
    }

}
