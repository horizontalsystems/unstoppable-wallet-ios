import Foundation
import Combine
import HsExtensions

class CexCoinSelectViewModel {
    private let service: CexCoinSelectService
    private var cancellables = Set<AnyCancellable>()

    @PostPublished private(set) var viewItems = [ViewItem]()

    init(service: CexCoinSelectService) {
        self.service = service

        service.$cexAssets
                .sink { [weak self] in self?.sync(cexAssets: $0) }
                .store(in: &cancellables)

        sync(cexAssets: service.cexAssets)
    }

    private func sync(cexAssets: [CexAsset]) {
        viewItems = cexAssets.map { cexAsset -> ViewItem in
            ViewItem(
                    cexAsset: cexAsset,
                    title: cexAsset.coinCode,
                    subtitle: cexAsset.coinName,
                    imageUrl: cexAsset.coin?.imageUrl
            )
        }
    }

}

extension CexCoinSelectViewModel {

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
    }

}
