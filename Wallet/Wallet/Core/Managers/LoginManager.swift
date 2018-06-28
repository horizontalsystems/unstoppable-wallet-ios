import Foundation
import RxSwift

class LoginManager {

    private let networkManager: INetworkManager
    private let walletManager: WalletManager
    private let realmManager: RealmManager
    private let localStorage: ILocalStorage

    init(networkManager: INetworkManager, walletManager: WalletManager, realmManager: RealmManager, localStorage: ILocalStorage) {
        self.networkManager = networkManager
        self.walletManager = walletManager
        self.realmManager = realmManager
        self.localStorage = localStorage
    }

    func login(withWords words: [String]) -> Observable<Void> {
        return Observable.just(words)
                .map { words in
                    self.walletManager.createWallet(withWords: words)
                }
                .flatMap { wallet in
                    self.networkManager.getJwtToken(identity: wallet.identity, pubKeys: wallet.pubKeys)
                }
                .flatMap { jwtToken in
                    self.realmManager.login(withJwtToken: jwtToken)
                }
                .do(onCompleted: {
                    self.localStorage.save(words: words)
                })
    }

}
