import Foundation
import RxSwift
import HsToolKit
import HsExtensions
import MarketKit

protocol ICexProvider {
    func balances() async throws -> [CexBalance]
    func allAssetInfos() async throws -> [CexAssetInfo]
    func deposit(cexAsset: CexAsset, network: String?) async throws -> String
    func withdraw(cexAsset: CexAsset, network: String, address: String, amount: Decimal) async throws -> String
}

class WalletCexElementService {
    private let provider: ICexProvider
    private var tasks = Set<AnyTask>()

    weak var delegate: IWalletElementServiceDelegate?

    private(set) var state: WalletModule.ElementState = .loading {
        didSet {
            delegate?.didUpdate(elementState: state, elementService: self)
        }
    }

    private var items = [CexAsset: BalanceData]()

    init(provider: ICexProvider) {
        self.provider = provider

        sync()
    }

    private func sync() {
        tasks = Set()

        switch state {
        case .loaded: ()
        default: state = .loading
        }

        Task { [weak self, provider] in
            do {
                let balances = try await provider.balances()
                let items = Dictionary(balances.map { ($0.asset, BalanceData(balance: $0.free, balanceLocked: $0.locked)) }, uniquingKeysWith: { lhs, _ in lhs })
                self?.items = items
                self?.state = .loaded(elements: items.keys.map { .cexAsset(cexAsset: $0) })
            } catch {
                print("ERROR: \(error)")
                self?.state = .failed(reason: .syncFailed)
            }
        }.store(in: &tasks)
    }

}

extension WalletCexElementService: IWalletElementService {

    func isMainNet(element: WalletModule.Element) -> Bool? {
        true
    }

    func balanceData(element: WalletModule.Element) -> BalanceData? {
        guard let cexAsset = element.cexAsset else {
            return nil
        }

        return items[cexAsset]
    }

    func state(element: WalletModule.Element) -> AdapterState? {
        .synced
    }

    func refresh() {
        sync()
    }

    func disable(element: WalletModule.Element) {
        // not supported
    }

}
