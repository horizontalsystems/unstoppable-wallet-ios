import XCTest
import Cuckoo
@testable import Wallet

class RestoreInteractorTests: XCTestCase {

    private var mockPresenter: MockRestorePresenterProtocol!
    private var mockMnemonic: MockMnemonicProtocol!
    private var mockLocalStorage: MockLocalStorageProtocol!
    private var interactor: RestoreInteractor!

    private let words = ["burden", "swap", "fabric", "book", "palm", "main", "salute", "raw", "core", "reflect", "parade", "tone"]
    private let invalidWords = ["word1", "word2"]

    override func setUp() {
        super.setUp()

        mockPresenter = MockRestorePresenterProtocol()
        mockMnemonic = MockMnemonicProtocol()
        mockLocalStorage = MockLocalStorageProtocol()
        interactor = RestoreInteractor(mnemonic: mockMnemonic, localStorage: mockLocalStorage)

        interactor.presenter = mockPresenter

        stub(mockMnemonic) { mock in
            when(mock.validate(words: equal(to: words))).thenReturn(true)
            when(mock.validate(words: equal(to: invalidWords))).thenReturn(false)
        }
        stub(mockLocalStorage) { mock in
            when(mock.save(words: any())).thenDoNothing()
        }
        stub(mockPresenter) { mock in
            when(mock.didFailToRestore()).thenDoNothing()
            when(mock.didRestoreWallet()).thenDoNothing()
        }
    }

    override func tearDown() {
        mockPresenter = nil
        mockMnemonic = nil
        mockLocalStorage = nil
        interactor = nil

        super.tearDown()
    }

    func testRestoreFailed() {
        interactor.restoreWallet(withWords: invalidWords)

        verify(mockPresenter).didFailToRestore()
        verifyNoMoreInteractions(mockLocalStorage)
    }

    func testRestoreWallet() {
        interactor.restoreWallet(withWords: words)

        verify(mockLocalStorage).save(words: equal(to: words))
        verify(mockPresenter).didRestoreWallet()
    }

}
