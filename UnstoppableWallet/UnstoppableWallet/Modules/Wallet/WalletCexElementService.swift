import Foundation
import RxSwift
import HsToolKit
import HsExtensions
import MarketKit

protocol ICexProvider {
    func balances() async throws -> [CexBalance]
}

class WalletCexElementService {
    private let provider: ICexProvider
    private var tasks = Set<AnyTask>()

    weak var delegate: IWalletElementServiceDelegate?

    private var items = [CexAsset: BalanceData]() {
        didSet {
            delegate?.didUpdate(elements: items.keys.map { .cexAsset(cexAsset: $0) })
        }
    }

    init(provider: ICexProvider) {
        self.provider = provider

        Task { [weak self, provider] in
            do {
                let balances = try await provider.balances()
                self?.items = Dictionary(balances.map { ($0.asset, BalanceData(balance: $0.free, balanceLocked: $0.locked)) }, uniquingKeysWith: { lhs, _ in lhs })
            } catch {
                print("ERROR: \(error)")
            }
        }.store(in: &tasks)
    }

}

extension WalletCexElementService: IWalletElementService {

    var elements: [WalletModule.Element] {
        []
    }

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
        // todo
    }

    func disable(element: WalletModule.Element) {
        // not supported
    }

}
