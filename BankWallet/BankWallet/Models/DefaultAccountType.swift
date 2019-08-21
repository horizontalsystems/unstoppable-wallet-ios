enum DefaultAccountType {
    case mnemonic(wordsCount: Int)
    case eos
}

extension DefaultAccountType: Equatable {

    public static func ==(lhs: DefaultAccountType, rhs: DefaultAccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWordsCount), let .mnemonic(rhsWordsCount)):
            return lhsWordsCount == rhsWordsCount
        case (.eos, .eos):
            return true
        default: return false
        }
    }

}
