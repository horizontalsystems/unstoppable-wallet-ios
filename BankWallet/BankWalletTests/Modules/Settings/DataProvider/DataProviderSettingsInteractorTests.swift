import XCTest
import Cuckoo
@testable import Bank_Dev_T

class DataProviderSettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockIDataProviderSettingsInteractorDelegate!
    private var mockDataProviderManager: MockIFullTransactionDataProviderManager!

    private var interactor: DataProviderSettingsInteractor!

    private let coinCode = "coin_code"
    private let firstName = "first_provider"
    private let secondName = "second_provider"

    private var firstProvider: MockIProvider!
    private var secondProvider: MockIProvider!
    private var providers: [IProvider]!

    override func setUp() {
        super.setUp()

        firstProvider = MockIProvider()
        stub(firstProvider) { mock in
            when(mock.name.get).thenReturn(firstName)
        }
        secondProvider = MockIProvider()
        stub(secondProvider) { mock in
            when(mock.name.get).thenReturn(secondName)
        }
        providers = [firstProvider, secondProvider]

        mockDelegate = MockIDataProviderSettingsInteractorDelegate()
        mockDataProviderManager = MockIFullTransactionDataProviderManager()

        stub(mockDelegate) { mock in
            when(mock.didSetBaseProvider()).thenDoNothing()
        }
        stub(mockDataProviderManager) { mock in
            when(mock.providers(for: any())).thenReturn(providers)
            when(mock.baseProvider(for: any())).thenReturn(firstProvider)
            when(mock.setBaseProvider(name: any(), for: any())).thenDoNothing()
        }

        interactor = DataProviderSettingsInteractor(dataProviderManager: mockDataProviderManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockDataProviderManager = nil

        interactor = nil

        super.tearDown()
    }

    func testGetProviders() {
        XCTAssertEqual(interactor.providers(for: coinCode).map { $0.name }, providers.map { $0.name })
    }

    func testGetBaseProvider() {
        XCTAssertEqual(interactor.baseProvider(for: coinCode).name, firstName)
    }

    func testSetBaseCurrency() {
        interactor.setBaseProvider(name: firstName, for: coinCode)

        verify(mockDataProviderManager).setBaseProvider(name: equal(to: firstName), for: equal(to: coinCode))
        verify(mockDelegate).didSetBaseProvider()
    }

}
