import MarketKit

/// The height a restored wallet scans from (Zcash, Monero, Zano).
class BirthdayHeightRestoreSettingsHandler: RestoreSettingsHandler {
    private let provider: IBirthdayInputProvider
    private var enteredHeight: Int?

    init(provider: IBirthdayInputProvider) {
        self.provider = provider
        super.init()
    }

    override class func instance(blockchainType: BlockchainType, accountType _: AccountType?) -> IRestoreSettingsHandler? {
        BirthdayInputProviderFactory.provider(blockchainType: blockchainType).map { BirthdayHeightRestoreSettingsHandler(provider: $0) }
    }
}

extension BirthdayHeightRestoreSettingsHandler: IRestoreSettingsHandler {
    func request(token: Token, statPage: StatPage?, onEnter: @escaping (RestoreSettings) -> Void, onCancel: @escaping () -> Void) {
        enteredHeight = nil

        Coordinator.shared.present { [self] _ in
            BirthdayInputView(blockchain: token.blockchain, provider: provider, onEnterBirthdayHeight: { height in
                enteredHeight = height
                onEnter([.birthdayHeight: String(height)])
            })
        } onDismiss: { [self] in
            if enteredHeight == nil {
                onCancel()
            }
        }

        if let statPage {
            stat(page: statPage, event: .open(page: .birthdayInput))
        }
    }
}
