import Combine
import Foundation

protocol IReceiveAddressService {
    associatedtype ServiceItem
    var title: String { get }
    var coinName: String { get }
    var state: DataStatus<ServiceItem> { get }
    var statusUpdatedPublisher: AnyPublisher<DataStatus<ServiceItem>, Never> { get }
}

protocol IReceiveAddressViewItemFactory {
    associatedtype Item
    func viewItem(item: Item, amount: String?) -> ReceiveAddressModule.ViewItem
    func popup(item: Item) -> ReceiveAddressModule.PopupWarningItem?
    func actions(item: Item) -> [ReceiveAddressModule.ActionType]
}

class ReceiveAddressViewModel<Service: IReceiveAddressService, Factory: IReceiveAddressViewItemFactory>: ObservableObject where Factory.Item == Service.ServiceItem {
    private let service: Service
    private let viewItemFactory: Factory
    private let decimalParser: AmountDecimalParser
    private var cancellables = Set<AnyCancellable>()
    private var hasAppeared = false

    @Published private(set) var state: DataStatus<ReceiveAddressModule.ViewItem> = .loading
    @Published private(set) var popup: ReceiveAddressModule.PopupWarningItem?
    @Published private(set) var actions: [ReceiveAddressModule.ActionType] = []
    @Published private(set) var amount: Decimal = 0

    init(service: Service, viewItemFactory: Factory, decimalParser: AmountDecimalParser) {
        self.service = service
        self.viewItemFactory = viewItemFactory
        self.decimalParser = decimalParser

        service.statusUpdatedPublisher
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: DataStatus<Service.ServiceItem>) {
        self.state = state.map { viewItemFactory.viewItem(item: $0, amount: amount == 0 ? nil : amount.description) }
        syncPopup(state: state)
        syncActions(state: state)
    }

    private func syncPopup(state: DataStatus<Service.ServiceItem>) {
        if hasAppeared, let item = state.data {
            let popup = viewItemFactory.popup(item: item)
            self.popup = popup
        }
    }

    private func syncActions(state: DataStatus<Service.ServiceItem>) {
        if let item = state.data {
            actions = viewItemFactory.actions(item: item)
        }
    }
}

extension ReceiveAddressViewModel {
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
}
