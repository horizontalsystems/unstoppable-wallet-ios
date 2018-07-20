import Foundation

public class WalletManager {
    public static let shared = WalletManager()

    enum ValidationError: Error {
        case invalidWordsCount
        case invalidWords
    }

    let localStorage: ILocalStorage

    private var mnemonic: [String]!
    private var hdWallet: HDWallet!

    public var words: [String] {
        return mnemonic
    }

    var wallet: HDWallet {
        return hdWallet
    }

    public var hasWallet: Bool {
        return hdWallet != nil
    }

    init(localStorage: ILocalStorage = UserDefaultsStorage.shared) {
        self.localStorage = localStorage

        if let savedWords = localStorage.savedWords {
            initWallet(with: savedWords)
        }
    }

    public func createWallet() throws {
        let generatedWords = try Mnemonic.generate()
        initWallet(with: generatedWords)
        localStorage.save(words: generatedWords)
    }

    public func restoreWallet(withWords words: [String]) throws {
        try validate(words: words)
        initWallet(with: words)
        localStorage.save(words: words)
    }

    public func removeWallet() {
        mnemonic = nil
        hdWallet = nil
        localStorage.clearWords()
    }

    private func initWallet(with words: [String]) {
        mnemonic = words
        hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: mnemonic), network: TestNet())
    }

    private func validate(words: [String]) throws {
        let set = Set(words)

        guard set.count == 12 else {
            throw ValidationError.invalidWordsCount
        }

        let wordsList = WordList.english.map(String.init)

        for word in set {
            if word == "" || !wordsList.contains(word) {
                throw ValidationError.invalidWords
            }
        }
    }

}
