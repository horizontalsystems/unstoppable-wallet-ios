import Foundation
import Combine
import HsExtensions

class CexCoinSelectViewModel {
    private let service: CexCoinSelectService
    private var cancellables = Set<AnyCancellable>()

    @PostPublished private(set) var viewItems = [ViewItem]()

    init(service: CexCoinSelectService) {
        self.service = service

        service.$items
                .sink { [weak self] in self?.sync(items: $0) }
                .store(in: &cancellables)

        sync(items: service.items)
    }

    private func sync(items: [CexCoinSelectService.Item]) {
        viewItems = items.map { item -> ViewItem in
            ViewItem(
                    cexAsset: item.cexAsset,
                    title: item.cexAsset.coinCode,
                    subtitle: item.cexAsset.coinName,
                    imageUrl: item.cexAsset.coin?.imageUrl,
                    enabled: item.enabled
            )
        }
    }

}

extension CexCoinSelectViewModel {

    var isEmpty: Bool {
        service.isEmpty
    }

    func onUpdate(filter: String?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter?.trimmingCharacters(in: .whitespaces) ?? "")
        }
    }

}

extension CexCoinSelectViewModel {

    struct ViewItem {
        let cexAsset: CexAsset
        let title: String
        let subtitle: String
        let imageUrl: String?
        let enabled: Bool
    }

}
