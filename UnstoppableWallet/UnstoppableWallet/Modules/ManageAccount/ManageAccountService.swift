import RxSwift
import RxRelay
import MarketKit

class ManageAccountService {
    private let accountRelay = PublishRelay<Account>()
    private(set) var account: Account {
        didSet {
            accountRelay.accept(account)
        }
    }

    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .cannotSave {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let accountDeletedRelay = PublishRelay<()>()

    private var newName: String

    init?(accountId: String, accountManager: IAccountManager, walletManager: WalletManager, restoreSettingsManager: RestoreSettingsManager) {
        guard let account = accountManager.account(id: accountId) else {
            return nil
        }

        self.account = account
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.restoreSettingsManager = restoreSettingsManager

        newName = account.name

        subscribe(disposeBag, accountManager.accountUpdatedObservable) { [weak self] in self?.handleUpdated(account: $0) }
        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] in self?.handleDeleted(account: $0) }

        syncState()
    }

    private func syncState() {
        if !newName.isEmpty && account.name != newName {
            state = .canSave
        } else {
            state = .cannotSave
        }
    }

    private func handleUpdated(account: Account) {
        if account.id == self.account.id {
            self.account = account
        }
    }

    private func handleDeleted(account: Account) {
        if account.id == self.account.id {
            accountDeletedRelay.accept(())
        }
    }

}

extension ManageAccountService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var accountObservable: Observable<Account> {
        accountRelay.asObservable()
    }

    var accountDeletedObservable: Observable<()> {
        accountDeletedRelay.asObservable()
    }

    var accountSettingsInfo: [(Coin, RestoreSettingType, String)] {
        let accountWallets = walletManager.wallets(account: account)

        return restoreSettingsManager.accountSettingsInfo(account: account).compactMap { coinType, restoreSettingType, value in
            guard let wallet = accountWallets.first(where: { $0.coinType == coinType }) else {
                return nil
            }

            // hide birthday height if it is set to 0
            if restoreSettingType == .birthdayHeight && value == "0" {
                return nil
            }

            return (wallet.coin, restoreSettingType, value)
        }
    }

    func set(name: String) {
        newName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        syncState()
    }

    func saveAccount() {
        account.name = newName
        accountManager.update(account: account)
    }

}

extension ManageAccountService {

    enum State {
        case cannotSave
        case canSave
    }

}
