import RxCocoa
import RxRelay
import RxSwift

class WCSignMessageRequestViewModel {
    private let service: WCSignMessageRequestService

    private let errorRelay = PublishRelay<Error>()
    private let dismissRelay = PublishRelay<Void>()

    init(service: WCSignMessageRequestService) {
        self.service = service
    }
}

extension WCSignMessageRequestViewModel {
    var sections: [Section] {
        service.sections.map { section in
            Section(
                header: section.header?.title,
                items: section.items.map { item in
                    switch item {
                    case let .domain(domain):
                        return .value(title: "wallet_connect.sign.domain".localized, value: domain)
                    case let .dApp(name: name):
                        return .value(title: "wallet_connect.sign.dapp_name".localized, value: name)
                    case let .blockchain(name: name, address: address):
                        return .value(title: name, value: address.shortened)
                    case let .message(message):
                        return .message(message)
                    }
                }
            )
        }
    }

    var errorSignal: Signal<Error> {
        errorRelay.asSignal()
    }

    var dismissSignal: Signal<Void> {
        dismissRelay.asSignal()
    }

    func onSign() {
        do {
            try service.sign()
            dismissRelay.accept(())
        } catch {
            errorRelay.accept(error)
        }
    }

    func onReject() {
        service.reject()
        dismissRelay.accept(())
    }
}

extension WCSignMessageRequestViewModel {
    enum ViewItem {
        case value(title: String, value: String)
        case message(String)
    }

    struct Section {
        let header: String?
        let items: [ViewItem]
    }
}

extension WCSignMessageRequestService.Header {
    var title: String {
        switch self {
        case .signMessage: return "wallet_connect.sign.message".localized
        }
    }
}
