import Foundation
import BitcoinKit

class MnemonicManager: MnemonicProtocol {

    func generateWords() -> [String] {
        return (try? Mnemonic.generate()) ?? []
    }

}
