import Combine

protocol IReceiveAddressService {
    associatedtype ServiceItem
    var title: String { get }
    var state: DataStatus<ServiceItem> { get }
    var statusUpdatedPublisher: AnyPublisher<DataStatus<ServiceItem>, Never> { get }
}

protocol IReceiveAddressViewItemFactory {
    associatedtype Item
    func viewItem(item: Item) -> ReceiveAddressModule.ViewItem
}

class ReceiveAddressViewModel<Service: IReceiveAddressService, Factory: IReceiveAddressViewItemFactory> where Factory.Item == Service.ServiceItem {
    private let service: Service
    private let viewItemFactory: Factory
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var spinnerVisible: Bool = false
    @Published private(set) var errorViewItem: ReceiveAddressModule.ErrorItem? = nil
    @Published private(set) var viewItem: ReceiveAddressModule.ViewItem?

    init(service: Service, viewItemFactory: Factory) {
        self.service = service
        self.viewItemFactory = viewItemFactory

        service.statusUpdatedPublisher
                .sink { [weak self] in self?.sync(status: $0) }
                .store(in: &cancellables)

        sync(status: service.state)
    }

    private func sync(status: DataStatus<Service.ServiceItem>) {
        switch status {
        case .loading:
            spinnerVisible = true
            errorViewItem = nil
            viewItem = nil
        case .completed(let item):
            spinnerVisible = false
            errorViewItem = nil
            viewItem = viewItemFactory.viewItem(item: item)
        case .failed(let error):
            spinnerVisible = false
            switch error {
            case let error as ReceiveAddressModule.ErrorItem:
                errorViewItem = error
            default:
                errorViewItem = ReceiveAddressModule.ErrorItem(icon: "not_available_48", text: error.localizedDescription)
            }
            viewItem = nil
        }
    }

}

extension ReceiveAddressViewModel {

    var title: String {
        service.title
    }

}
