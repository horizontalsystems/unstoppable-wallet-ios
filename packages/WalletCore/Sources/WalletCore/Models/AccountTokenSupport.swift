import MarketKit

public enum AccountTokenSupport {
    private static var providers: [IAccountTokenSupportProvider] = []

    public static func register(_ provider: IAccountTokenSupportProvider) {
        providers.insert(provider, at: 0)
    }

    static func supports(accountType: AccountType, token: Token) -> Bool? {
        for provider in providers {
            if let supported = provider.supports(accountType: accountType, token: token) {
                return supported
            }
        }

        return nil
    }
}

public protocol IAccountTokenSupportProvider {
    func supports(accountType: AccountType, token: Token) -> Bool?
}
