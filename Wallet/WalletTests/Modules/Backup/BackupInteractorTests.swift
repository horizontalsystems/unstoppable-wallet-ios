import XCTest
import Cuckoo
@testable import Wallet

class BackupInteractorTests: XCTestCase {

    private var mockPresenter: MockBackupPresenterProtocol!
    private var mockWalletDataProvider: MockWalletDataProviderProtocol!
    private var mockIndexesProvider: MockBackupRandomIndexesProviderProtocol!
    private var interactor: BackupInteractor!

    private let walletData = WalletData(
            words: ["burden", "swap", "fabric", "book", "palm", "main", "salute", "raw", "core", "reflect", "parade", "tone"]
    )
    private let indexes = [2, 11]

    override func setUp() {
        super.setUp()

        mockPresenter = MockBackupPresenterProtocol()
        mockWalletDataProvider = MockWalletDataProviderProtocol()
        mockIndexesProvider = MockBackupRandomIndexesProviderProtocol()
        interactor = BackupInteractor(walletDataProvider: mockWalletDataProvider, indexesProvider: mockIndexesProvider)

        interactor.presenter = mockPresenter

        stub(mockWalletDataProvider) { mock in
            when(mock.walletData.get).thenReturn(walletData)
        }
        stub(mockIndexesProvider) { mock in
            when(mock.getRandomIndexes(count: 2)).thenReturn(indexes)
        }
        stub(mockPresenter) { mock in
            when(mock.didFetch(words: any())).thenDoNothing()
            when(mock.didFetch(confirmationIndexes: any())).thenDoNothing()
            when(mock.didValidateSuccess()).thenDoNothing()
            when(mock.didValidateFailure()).thenDoNothing()
        }
    }

    override func tearDown() {
        mockPresenter = nil
        mockWalletDataProvider = nil
        mockIndexesProvider = nil
        interactor = nil

        super.tearDown()
    }

    func testFetchWords() {
        interactor.fetchWords()

        verify(mockPresenter).didFetch(words: equal(to: walletData.words))
    }

    func testFetchConfirmationIndexes() {
        interactor.fetchConfirmationIndexes()

        verify(mockPresenter).didFetch(confirmationIndexes: equal(to: indexes))
    }

    func testValidateSuccess() {
        interactor.validate(confirmationWords: [3: "fabric", 12: "tone"])

        verify(mockPresenter).didValidateSuccess()
        verifyNoMoreInteractions(mockPresenter)
    }

    func testValidateFailureByOrder() {
        interactor.validate(confirmationWords: [1: "fabric", 12: "tone"])

        verify(mockPresenter).didValidateFailure()
        verifyNoMoreInteractions(mockPresenter)
    }

    func testValidateFailureByName() {
        interactor.validate(confirmationWords: [3: "fabric2", 12: "tone"])

        verify(mockPresenter).didValidateFailure()
        verifyNoMoreInteractions(mockPresenter)
    }

}
