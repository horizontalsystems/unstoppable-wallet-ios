import Foundation
import Cuckoo
@testable import Bank

class MockApp {

    let mockSecureStorage: MockISecureStorage
    let mockLocalStorage: MockILocalStorage
    let mockWordsManager: MockWordsManager

    let mockPinManager: MockPinManager
    let mockLockRouter: MockLockRouter
    let mockLockManager: MockLockManager
    let mockBlurManager: MockBlurManager

    var mockAdapterManager: MockAdapterManager!

    init() {
        mockSecureStorage = MockISecureStorage()

        stub(mockSecureStorage) { mock in
            when(mock.words.get).thenReturn([])
        }

        mockLocalStorage = MockILocalStorage()
        mockWordsManager = MockWordsManager(secureStorage: mockSecureStorage, localStorage: mockLocalStorage)

        mockPinManager = MockPinManager(secureStorage: mockSecureStorage)
        mockLockRouter = MockLockRouter()
        mockLockManager = MockLockManager(localStorage: mockLocalStorage, wordsManager: mockWordsManager, pinManager: mockPinManager, lockRouter: mockLockRouter)
        mockBlurManager = MockBlurManager(lockManager: mockLockManager)

        mockAdapterManager = MockAdapterManager(words: [])
    }

}
