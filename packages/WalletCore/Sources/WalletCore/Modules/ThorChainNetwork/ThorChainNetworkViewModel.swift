import Combine
import Foundation
import MarketKit
import RxSwift
import ThorChainKit

final class ThorChainNetworkViewModel: ObservableObject {
    let blockchain: Blockchain
    private let endpointManager = Core.shared.thorChainEndpointManager
    private let disposeBag = DisposeBag()

    @Published private(set) var endpointFamilies = [ThorChainKit.EndpointFamilyDescriptor]()
    @Published var selectedEndpointFamilyId: String?
    @Published private(set) var currentEndpointFamilyId: String?

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        subscribe(disposeBag, endpointManager.endpointObservable) { [weak self] in
            DispatchQueue.main.async { [weak self] in self?.sync() }
        }

        sync()
    }

    var saveEnabled: Bool {
        selectedEndpointFamilyId != currentEndpointFamilyId
    }

    func save() {
        guard let selectedEndpointFamilyId,
              let endpointFamily = endpointFamilies.first(where: { $0.id == selectedEndpointFamilyId })
        else {
            return
        }

        try? endpointManager.setCurrent(endpointFamily: endpointFamily)
    }

    private func sync() {
        endpointFamilies = (try? endpointManager.endpointFamilies()) ?? []
        currentEndpointFamilyId = try? endpointManager.endpointFamily().id
        selectedEndpointFamilyId = currentEndpointFamilyId
    }
}
