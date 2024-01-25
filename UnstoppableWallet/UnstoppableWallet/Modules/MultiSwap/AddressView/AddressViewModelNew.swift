import Combine
import MarketKit
import UIKit
import SwiftUI
import RxSwift

class AddressViewModelNew: ObservableObject {
    let shortcuts: [ShortCutButtonType] = [
        .icon("qr_scan_20"),
        .text("button.paste".localized),
    ]

    private var addressParserDisposeBag = DisposeBag()

    private var addressUriParser: AddressUriParser
    private let parserChain: AddressParserChain

    private let contactBookManager: ContactBookManager = App.shared.contactManager
    private let useContacts: Bool

    @Published var text: String {
        didSet {
            sync()
        }
    }

    @Published var cautionState: CautionState = .none
    @Binding var result: AddressInput.Result {
        didSet {
            switch result {
            case let .valid(val): print("Address: \(val.address.title) : \(val.address.blockchainType)")
            case let .invalid(val): print("Address: \(val.text) : \(val.error.localizedDescription)")
            case .idle: print("idle")
            case .loading: print("loading...")
            }
        }
    }

    @Published var qrScanPresented = false
    @Published var doneEnabled = true

    init(initial: AddressInput.Initial, result: Binding<AddressInput.Result>) {
        addressUriParser = AddressParserFactory.parser(blockchainType: initial.blockchainType, tokenType: nil)
        parserChain = AddressParserFactory.parserChain(blockchainType: initial.blockchainType)

        useContacts = initial.useContacts
        text = initial.address?.title ?? ""

        _result = result
        sync()
    }

    private func sync() {
        guard !text.isEmpty else {
            result = .idle
            return
        }

        result = .loading(text)

        let text = text
        // check uri
        do {
            let uri = try checkUri(text: text)

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
    func onTap(index: Int) {
        switch index {
        case 0: qrScanPresented = true
        case 1:
            if let text = UIPasteboard.general.string?.replacingOccurrences(of: "\n", with: " ") {
                self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        default: ()
        }
    }

    func onTapDelete() {
        text = ""
    }

    func didFetch(qrText: String) {
        text = "skldcjds aflkjsdfh shdfjdslfksdjhf dsfhjasdlkdsjfh dshfjasdlfkjhsd fТ"
//        Task {
//            try await Task.sleep(nanoseconds: 1_000_000_000)
//            await MainActor.run {
//            }
//        }
    }
}

enum AddressInput {
    struct Initial {
        let blockchainType: BlockchainType?
        let address: Address?
        let useContacts: Bool

        init(blockchainType: BlockchainType? = nil, address: Address? = nil, useContacts: Bool) {
            self.blockchainType = blockchainType
            self.address = address
            self.useContacts = useContacts
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
