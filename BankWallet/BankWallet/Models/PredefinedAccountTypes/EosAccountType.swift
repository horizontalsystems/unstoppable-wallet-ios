class EosAccountType: IPredefinedAccountType {
    let title = "EOS"
    let coinCodes = "EOS, NDX, IQ, EOSDT, NUT"

    var defaultAccountType: DefaultAccountType {
        .eos
    }

    func supports(accountType: AccountType) -> Bool {
        if case .eos = accountType {
            return true
        }

        return false
    }

}
