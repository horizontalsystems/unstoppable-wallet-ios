class EosAccountType: IPredefinedAccountType {
    let title = "key_type.eos"
    let coinCodes = "key_type.eos.text"

    var defaultAccountType: DefaultAccountType {
        return .eos
    }

    func supports(accountType: AccountType) -> Bool {
        if case .eos = accountType {
            return true
        }

        return false
    }

}
