import Combine
import Foundation
import MarketKit
import SwiftUI

protocol ICurrentAddressProvider {
    var address: String? { get }
}

protocol IReceiveAddressService {
    var title: String { get }
    var coinName: String { get }
    var coinType: BlockchainType { get }
    var state: DataStatus<ReceiveAddress> { get }
    var statusUpdatedPublisher: AnyPublisher<DataStatus<ReceiveAddress>, Never> { get }
}

class BaseReceiveAddressViewModel: ObservableObject {
    private let service: BaseReceiveAddressService
    private let viewItemFactory: ReceiveAddressViewItemFactory
    private let decimalParser: AmountDecimalParser
    private var cancellables = Set<AnyCancellable>()
    private var hasAppeared = false

    @Published private(set) var state: DataStatus<ReceiveAddressModule.ViewItem> = .loading
    @Published private(set) var actions: [ReceiveAddressModule.ActionType] = []
    @Published private(set) var amount: Decimal = 0

    private let popupSubject = PassthroughSubject<ReceiveAddressModule.PopupWarningItem, Never>()

    private var amountFieldChangedSuccessSubject = PassthroughSubject<Bool, Never>()
    var amountFieldChangedSuccessPublisher: AnyPublisher<Bool, Never> {
        amountFieldChangedSuccessSubject.eraseToAnyPublisher()
    }

    init(service: BaseReceiveAddressService, viewItemFactory: ReceiveAddressViewItemFactory, decimalParser: AmountDecimalParser) {
        self.service = service
        self.viewItemFactory = viewItemFactory
        self.decimalParser = decimalParser

        service.statusUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.sync(state: $0)
            }
            .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: DataStatus<ReceiveAddress>) {
        self.state = state.map { viewItemFactory.viewItem(item: $0, amount: amount == 0 ? nil : amount.description) }
        syncPopup(state: state)
        syncActions(state: state)
    }

    private func syncPopup(state: DataStatus<ReceiveAddress>) {
        if hasAppeared, let item = state.data, let popup = viewItemFactory.popup(item: item) {
            popupSubject.send(popup)
        }
    }

    private func syncActions(state: DataStatus<ReceiveAddress>) {
        if let item = state.data {
            actions = viewItemFactory.actions(item: item)
        }
    }

    func popupButtons(mode _: ReceiveAddressModule.PopupWarningItem.Mode, isPresented _: Binding<Bool>) -> [ButtonGroupViewModel.ButtonItem] {
        []
    }
}

extension BaseReceiveAddressViewModel {
    var popupPublisher: AnyPublisher<ReceiveAddressModule.PopupWarningItem, Never> {
        popupSubject.eraseToAnyPublisher()
    }

    var wallet: Wallet {
        service.wallet
    }

    var title: String {
        service.title
    }

    var coinName: String {
        service.coinName
    }

    func set(amount: String) {
        let value = decimalParser.parseAnyDecimal(from: amount) ?? 0
        self.amount = value
        sync(state: service.state)
    }

    func onFirstAppear() {
        hasAppeared = true
        syncPopup(state: service.state)
    }

    func showPopup() {
        syncPopup(state: service.state)
    }

    func onAmountChanged(_ text: String) {
        set(amount: text)
        stat(page: .receive, event: .setAmount)
    }

    var initialText: String {
        amount == 0 ? "" : amount.description
    }
}

extension BaseReceiveAddressViewModel {
    static func instance(wallet: Wallet) -> BaseReceiveAddressViewModel {
        let service = BaseReceiveAddressService(wallet: wallet)
        let depositViewItemFactory = ReceiveAddressViewItemFactory()

        return BaseReceiveAddressViewModel(service: service, viewItemFactory: depositViewItemFactory, decimalParser: AmountDecimalParser())
    }
}
