import Foundation

class AccountCreator {
    private let wordsManager: IWordsManager

    init(wordsManager: IWordsManager) {
        self.wordsManager = wordsManager
    }

    func account(coin: Coin) -> Account? {
        guard let words = try? wordsManager.generateWords() else {
            return nil
        }

        return Account(
                id: UUID().uuidString,
                name: "Mnemonic",
                type: .mnemonic(words: words, derivation: .bip44, salt: nil),
                backedUp: false,
                defaultSyncMode: .fast
        )
    }

}
