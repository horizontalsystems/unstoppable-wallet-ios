import Foundation
import RealmSwift

class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    let mnemonic: IMnemonic
    let localStorage: ILocalStorage

    init(mnemonic: IMnemonic, localStorage: ILocalStorage) {
        self.mnemonic = mnemonic
        self.localStorage = localStorage
    }

}

extension RestoreInteractor: IRestoreInteractor {

    func restore(withWords words: [String]) {
        if mnemonic.validate(words: words) {

            guard let authURL = URL(string: "https://grouvi-wallet.us1a.cloud.realm.io") else {
                print("No auth url")
                delegate?.didFailToRestore()
                return
            }

            let credentials = SyncCredentials.usernamePassword(username: "ermat", password: "123")

            SyncUser.logIn(with: credentials, server: authURL, onCompletion: { [weak self] user, error in
                if let user = user {
                    print("User: \(user)")

                    self?.localStorage.save(words: words)
                    self?.delegate?.didRestore()
                } else if let error = error {
                    print("Error: \(error)")
                    self?.delegate?.didFailToRestore()
                }
            })

        } else {
            delegate?.didFailToRestore()
        }
    }

}
