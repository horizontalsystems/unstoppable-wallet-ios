struct DerivationSetting {
    let coinType: CoinType
    let derivation: MnemonicDerivation
}

extension DerivationSetting: Equatable {

    public static func ==(lhs: DerivationSetting, rhs: DerivationSetting) -> Bool {
        lhs.coinType == rhs.coinType && lhs.derivation == rhs.derivation
    }

}
