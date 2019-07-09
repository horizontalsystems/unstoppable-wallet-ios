class EosAccountType: IPredefinedAccountType {
    let title = "key_type.eos"
    let coinCodes = "EOS"

    var defaultAccountType: DefaultAccountType? {
        return nil // creating EOS account is not supported yet
    }

}
