import XCTest
import Cuckoo
@testable import Bank_Dev_T

class PinInteractorTests: XCTestCase {
    enum StubError: Error { case some }

    private var mockDelegate: MockIPinInteractorDelegate!
    private var mockPinManager: MockIPinManager!
    private var interactor: PinInteractor!

    override func setUp() {
        super.setUp()

        mockDelegate = MockIPinInteractorDelegate()
        mockPinManager = MockIPinManager()

        stub(mockDelegate) { mock in
            when(mock.didSavePin()).thenDoNothing()
            when(mock.didFailToSavePin()).thenDoNothing()
        }
        stub(mockPinManager) { mock in
            when(mock.store(pin: any())).thenDoNothing()
        }

        interactor = PinInteractor(pinManager: mockPinManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockPinManager = nil
        interactor = nil

        super.tearDown()
    }

    func testSuccessSave() {
        let pin = "0000"
        interactor.save(pin: pin)

        verify(mockPinManager).store(pin: equal(to: pin))
        verify(mockDelegate).didSavePin()
    }

    func testFailToSave() {
        let pin = "0000"

        stub(mockPinManager) { mock in
            when(mock.store(pin: equal(to: pin))).thenThrow(StubError.some)
        }

        interactor.save(pin: pin)

        verify(mockDelegate, never()).didSavePin()
        verify(mockDelegate).didFailToSavePin()
    }

    func testValidateSuccess() {
        let pin = "0000"

        interactor.set(pin: pin)
        let isValid = interactor.validate(pin: pin)

        XCTAssertTrue(isValid)
    }

    func testValidateFailure() {
        interactor.set(pin: "0000")
        let isValid = interactor.validate(pin: "1111")

        XCTAssertFalse(isValid)
    }

    func testUnlockSuccess() {
        let pin = "0000"
        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(true)
        }

        let isValid = interactor.unlock(with: pin)

        XCTAssertTrue(isValid)
    }

    func testUnlockFailure() {
        let pin = "0000"
        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(false)
        }

        let isValid = interactor.unlock(with: pin)

        XCTAssertFalse(isValid)
    }

}
