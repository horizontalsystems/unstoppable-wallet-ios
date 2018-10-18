import RxSwift

protocol IRandomManager {
    func getRandomIndexes(count: Int) -> [Int]
}

protocol ILocalStorage: class {
    var isBackedUp: Bool { get set }
    var lightMode: Bool { get set }
    var iUnderstand: Bool { get set }
    var isBiometricOn: Bool { get set }
    var currentLanguage: String? { get set }
    var lastExitDate: Double { get set }
    var didLaunchOnce: Bool { get }
    func clear()
}

protocol ISecureStorage: class {
    var words: [String]? { get }
    func set(words: [String]?) throws
    var pin: String? { get }
    func set(pin: String?) throws
    func clear()
}

protocol ILanguageManager {
    var currentLanguage: String { get set }
    var displayNameForCurrentLanguage: String { get }

    func localize(string: String) -> String
    func localize(string: String, arguments: [CVarArg]) -> String
}

protocol ILocalizationManager {
    var preferredLanguage: String? { get }
    var availableLanguages: [String] { get }
    func displayName(forLanguage language: String, inLanguage: String) -> String

    func localize(string: String, language: String) -> String?
    func format(localizedString: String, arguments: [CVarArg]) -> String
}

protocol IAdapterManager {
    var adapters: [IAdapter] { get }
    var subject: PublishSubject<Void> { get }
    func start()
    func refresh()
    func clear()
}

protocol IAdapter {
    var id: String { get }

    var coin: Coin { get }

    var balance: Double { get }
    var balanceSubject: PublishSubject<Double> { get }

    var progressSubject: BehaviorSubject<Double> { get }

    var lastBlockHeight: Int { get }
    var lastBlockHeightSubject: PublishSubject<Int> { get }

    var transactionRecords: [TransactionRecord] { get }
    var transactionRecordsSubject: PublishSubject<Void> { get }

    func showInfo()

    func start()
    func refresh()
    func clear()

    func send(to address: String, value: Double, completion: ((Error?) -> ())?)

    func fee(for value: Double, senderPay: Bool) throws -> Double
    func validate(address: String) throws

    var receiveAddress: String { get }
}

protocol IWordsManager {
    var words: [String]? { get }
    var isBackedUp: Bool { get set }
    var isLoggedIn: Bool { get }
    var backedUpSubject: PublishSubject<Bool> { get }
    func createWords() throws
    func validate(words: [String]) throws
    func restore(withWords words: [String]) throws
    func removeWords()
}

protocol ILockManager {
    var isLocked: Bool { get }
    func lock()
    func didEnterBackground()
    func willEnterForeground()
}

protocol IBlurManager {
    func willResignActive()
    func didBecomeActive()
}

protocol IPinManager {
    var isPinned: Bool { get }
    func store(pin: String?) throws
    func validate(pin: String) -> Bool
}

protocol ILockRouter {
    func showUnlock(delegate: IUnlockDelegate?)
}

protocol IBiometricManager {
    func validate(reason: String)
}

protocol BiometricManagerDelegate: class {
    func didValidate()
    func didFailToValidate()
}

protocol IExchangeRateManager {
    var subject: PublishSubject<[String: Double]> { get }
    var exchangeRates: [String: Double] { get }
    func updateRates()
}

protocol ISystemInfoManager {
    var appVersion: String { get }
    var biometryType: BiometryType { get }
}
