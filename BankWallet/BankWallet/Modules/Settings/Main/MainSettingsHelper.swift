class MainSettingsHelper {

    func isBackedUp(nonBackedUpCount: Int) -> Bool {
        return nonBackedUpCount == 0
    }

    func displayName(baseCurrency: Currency) -> String {
        return baseCurrency.code
    }

}
