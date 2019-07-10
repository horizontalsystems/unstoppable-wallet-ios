class EosAccountType: IPredefinedAccountType {
    let title = "key_type.eos"
    let coinCodes = "key_type.eos.text"

    var defaultAccountType: DefaultAccountType? {
        return nil // creating EOS account is not supported yet
    }

    func supports(accountType: AccountType) -> Bool {
        if case .eos = accountType {
            return true
        }

        return false
    }

}
