import Foundation
import RxSwift
import HsToolKit
import HsExtensions
import MarketKit

protocol ICexProvider {
    func assets() async throws -> [CexAssetResponse]
    func deposit(id: String, network: String?) async throws -> (String, String?)
    func withdraw(id: String, network: String?, address: String, amount: Decimal) async throws -> String
}

class WalletCexElementService {
    private let account: Account
    private let provider: ICexProvider
    private let cexAssetManager: CexAssetManager
    private var tasks = Set<AnyTask>()

    weak var delegate: IWalletElementServiceDelegate?

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    private(set) var state: WalletModule.ElementState = .loading {
        didSet {
            delegate?.didUpdate(elementState: state, elementService: self)
        }
    }

    private var cexAssets: [CexAsset]

    init(account: Account, provider: ICexProvider, cexAssetManager: CexAssetManager) {
        self.account = account
        self.provider = provider
        self.cexAssetManager = cexAssetManager

        cexAssets = cexAssetManager.balanceCexAssets(account: account)

        sync()
    }

    private var elements: [WalletModule.Element] {
        cexAssets.map { .cexAsset(cexAsset: $0) }
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = cexAssets.isEmpty ? .loading : .loaded(elements: elements)
        case .loaded:
            state = .loaded(elements: elements)
        case .failed(let reason):
            state = cexAssets.isEmpty ? .failed(reason: reason) : .loaded(elements: elements)
        }
    }

    private func sync() {
        tasks = Set()

        switch internalState {
        case .loaded: ()
        default: internalState = .loading
        }

        Task { [weak self, provider, cexAssetManager, account] in
            do {
                let assets = try await provider.assets()

                cexAssetManager.resave(cexAssetResponses: assets, account: account)
                self?.cexAssets = cexAssetManager.balanceCexAssets(account: account)

                self?.internalState = .loaded
            } catch {
                print("ERROR: \(error)")
                self?.internalState = .failed(reason: .syncFailed)
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

        return BalanceData(balance: cexAsset.freeBalance, balanceLocked: cexAsset.lockedBalance)
    }

    func state(element: WalletModule.Element) -> AdapterState? {
        switch internalState {
        case .failed(let reason): return .notSynced(error: AppError.unknownError)
        default: return .synced
        }
    }

    func refresh() {
        sync()
    }

    func disable(element: WalletModule.Element) {
        // not supported
    }

}

extension WalletCexElementService {

    enum State {
        case loading
        case loaded
        case failed(reason: WalletModule.FailureReason)
    }

}
