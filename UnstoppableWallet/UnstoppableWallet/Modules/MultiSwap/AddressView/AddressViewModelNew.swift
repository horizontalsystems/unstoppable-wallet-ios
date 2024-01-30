import Combine
import MarketKit
import UIKit
import SwiftUI
import RxSwift

class AddressViewModelNew: ObservableObject {
    private var addressParserDisposeBag = DisposeBag()

    private var addressUriParser: AddressUriParser
    private let parserChain: AddressParserChain

    let blockchainType: BlockchainType?
    private let contactBookManager: ContactBookManager = App.shared.contactManager
    private let showContacts: Bool

    private var expectedTextValue: String? = nil

    var updateText: (String) -> ()
    @Published var internalText: String {
        didSet {
            print("==> Try set Text from internal to Publisher: \(internalText)")
            if internalText == oldValue { return }
            print("==> Set! Text from internal to Publisher: \(internalText)")

            updateText(oldValue)
            sync()
        }
    }

    @Binding var result: AddressInput.Result {
        didSet {
            switch result {
            case .loading: checkingState = .loading
            case .valid: checkingState = .checked
            default: checkingState = .idle
            }

            switch result {
            case let .valid(val):
                print("Address: \(val.address.title) : \(val.address.blockchainType) || \(val.uri?.address) + \(val.uri?.amount?.description)")
            case let .invalid(val):
                print("Address: \(val.text) : \(val.error.localizedDescription)")
            case .idle: print("idle")
            case .loading: print("loading...")
            }
            print("Checking State: \(checkingState)")
        }
    }

    @Published var checkingState: RightChecking.State = .idle

    @Published var contactsPresented = false
    @Published var qrScanPresented = false

    init(initial: AddressInput.Initial, text: Binding<String>, result: Binding<AddressInput.Result>) {
        _result = result
        internalText = text.wrappedValue
        updateText = {
            if text.wrappedValue == $0 { return }
            text.wrappedValue = $0
        }

        print("Init ViewModel. /Text: \(text.wrappedValue)")
        addressUriParser = AddressParserFactory.parser(blockchainType: initial.blockchainType, tokenType: nil)
        parserChain = AddressParserFactory.parserChain(blockchainType: initial.blockchainType)

        blockchainType = initial.blockchainType

        // show contact book if initial shows and we have contacts for defined blockchain
        if let blockchainType, initial.showContacts {
            showContacts = !contactBookManager.contacts(blockchainUid: blockchainType.uid).isEmpty
        } else {
            showContacts = false
        }

        sync()
    }

    private func sync() {
        print("==> Sync new text value")
        if internalText == expectedTextValue {   // avoid double sync already updated text from 'uri'
            print("==> Avoid sync because already synced form uri")
            return
        }
        expectedTextValue = nil

        guard !internalText.isEmpty else {
            result = .idle
            return
        }

        result = .loading(internalText)

        let text = internalText
        // check uri
        do {
            let uri = try checkUri(text: text)

            if let uri {    // we must show address from uri
                print("==> Change text from uri using only address")
                expectedTextValue = uri.address
                self.internalText = uri.address
            }

            // get address from uri or all text
            let address = uri?.address ?? text
            // try to parse by chain this address/text
            addressParserDisposeBag = DisposeBag()
            parserChain
                .handle(address: address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onSuccess: { [weak self] in self?.sync($0, uri: uri) },
                        onError: { [weak self] in self?.sync($0, text: text) }
                )
                .disposed(by: addressParserDisposeBag)
        } catch {
            result = .invalid(.init(text: text, error: error))
        }
    }

    private func sync(_ address: Address?, uri: AddressUri?) {
        guard let address else {
            result = .idle
            return
        }

        result = .valid(.init(address: address, uri: uri))
    }

    private func sync(_ error: Error, text: String) {
        result = .invalid(.init(text: text, error: error))
    }

    private func checkUri(text: String) throws -> AddressUri? {
        do {
            return try addressUriParser.parse(url: text.trimmingCharacters(in: .whitespaces))
        } catch {
            switch error {
            case AddressUriParser.ParseError.noUri, AddressUriParser.ParseError.wrongUri:
                // there is no Uri or we can't handle. Just return nil
                return nil
            default:
                // there is right Uri, but wrong blockchain or token. Return Error
                throw error
            }
        }
    }
}

extension AddressViewModelNew {
    //Shortcut section
    var shortcuts: [ShortCutButtonType] {
        let items: [ShortCutButtonType] = showContacts ? [.icon("user_20")] : []
        return items + [.icon("qr_scan_20"), .text("button.paste".localized)]
    }

    func onTap(index: Int) {
        let updatedIndex = index - (showContacts ? 1 : 0)
        switch updatedIndex {
        case -1: contactsPresented = true
        case 0: qrScanPresented = true
        case 1:
            if let text = UIPasteboard.general.string?.replacingOccurrences(of: "\n", with: " ") {
                self.internalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        default: ()
        }
    }

    func onTapDelete() {
        internalText = ""
    }

    func didFetch(qrText: String) {
        internalText = qrText
    }
}

extension AddressViewModelNew: ContactBookSelectorDelegate {
    func onFetch(address: String) {
        internalText = address
    }
}

enum AddressInput {
    struct Initial {
        let blockchainType: BlockchainType?
        let showContacts: Bool

        init(blockchainType: BlockchainType? = nil, showContacts: Bool) {
            self.blockchainType = blockchainType
            self.showContacts = showContacts
        }
    }

    struct Success: Equatable {
        let address: Address
        let uri: AddressUri?
    }

    struct Failure: Equatable {
        let text: String
        let error: Error

        static func ==(lhs: Failure, rhs: Failure) -> Bool {
            lhs.text == rhs.text &&
            lhs.error.localizedDescription == rhs.error.localizedDescription
        }
    }

    enum Result: Equatable {
        case idle
        case loading(String)
        case valid(Success)
        case invalid(Failure)
    }
}
