import Combine
import ObjectMapper
import HsToolKit
import HsExtensions

class RestoreBinanceService {
    private let networkManager: NetworkManager
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private var tasks = Set<AnyTask>()

    var apiKey: String = "" {
        didSet {
            syncState()
        }
    }

    var secretKey: String = "" {
        didSet {
            syncState()
        }
    }

    @PostPublished private(set) var state: State = .notReady

    init(networkManager: NetworkManager, accountFactory: AccountFactory, accountManager: AccountManager) {
        self.networkManager = networkManager
        self.accountFactory = accountFactory
        self.accountManager = accountManager
    }

    private func syncState() {
        state = apiKey.trimmingCharacters(in: .whitespaces).isEmpty || secretKey.trimmingCharacters(in: .whitespaces).isEmpty ? .notReady : .idle(error: nil)
    }

    private func createAccount() {
        let type: AccountType = .cex(cexAccount: .binance(apiKey: apiKey, secret: secretKey))
        let name = accountFactory.nextAccountName(cex: .binance)
        let account = accountFactory.account(type: type, origin: .restored, backedUp: true, fileBackedUp: false, name: name)

        accountManager.save(account: account)

        state = .connected
    }

}

extension RestoreBinanceService {

    func parse(qrCodeString: String) throws -> QrCode {
        try QrCode(JSONString: qrCodeString)
    }

    func connect() {
        state = .connecting

        Task { [weak self, apiKey, secretKey, networkManager] in
            do {
                try await BinanceCexProvider.validate(apiKey: apiKey, secret: secretKey, networkManager: networkManager)
                self?.createAccount()
            } catch {
                self?.state = .idle(error: error)
            }
        }.store(in: &tasks)
    }

}

extension RestoreBinanceService {

    enum State {
        case notReady
        case idle(error: Error?)
        case connecting
        case connected
    }

    struct QrCode: ImmutableMappable {
        let apiKey: String
        let secretKey: String

        init(map: Map) throws {
            apiKey = try map.value("apiKey")
            secretKey = try map.value("secretKey")
        }
    }

}
