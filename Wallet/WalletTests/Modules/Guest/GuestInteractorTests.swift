import XCTest
import Cuckoo
@testable import Wallet

class GuestInteractorTests: XCTestCase {

    private var mockPresenter: MockGuestPresenterProtocol!
    private var mockMnemonic: MockMnemonicProtocol!
    private var mockLocalStorage: MockLocalStorageProtocol!
    private var interactor: GuestInteractor!

    private let words = ["burden", "swap", "fabric", "book", "palm", "main", "salute", "raw", "core", "reflect", "parade", "tone"]

    override func setUp() {
        super.setUp()

        mockPresenter = MockGuestPresenterProtocol()
        mockMnemonic = MockMnemonicProtocol()
        mockLocalStorage = MockLocalStorageProtocol()
        interactor = GuestInteractor(mnemonic: mockMnemonic, localStorage: mockLocalStorage)

        interactor.presenter = mockPresenter

        stub(mockMnemonic) { mock in
            when(mock.generateWords()).thenReturn(words)
        }
        stub(mockLocalStorage) { mock in
            when(mock.save(words: any())).thenDoNothing()
        }
        stub(mockPresenter) { mock in
            when(mock.didCreateWallet()).thenDoNothing()
        }
    }

    override func tearDown() {
        mockPresenter = nil
        mockMnemonic = nil
        mockLocalStorage = nil
        interactor = nil

        super.tearDown()
    }

    func testCreateWallet() {
        interactor.createWallet()

        verify(mockLocalStorage).save(words: equal(to: words))
        verify(mockPresenter).didCreateWallet()
    }

}
