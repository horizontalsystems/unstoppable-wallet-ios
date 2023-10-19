import Foundation
import RxSwift
import HsToolKit
import HsExtensions
import MarketKit

class WalletCexElementService {
    private let account: Account
    private let provider: ICexAssetProvider
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

    init(account: Account, provider: ICexAssetProvider, cexAssetManager: CexAssetManager) {
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
            switch reason {
            case .syncFailed: state = cexAssets.isEmpty ? .failed(reason: reason) : .loaded(elements: elements)
            case .invalidApiKey: state = .failed(reason: reason)
            }
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

        return VerifiedBalanceData(fullBalance: cexAsset.freeBalance + cexAsset.lockedBalance, available: cexAsset.freeBalance)
    }

    func state(element: WalletModule.Element) -> AdapterState? {
        switch internalState {
        case .failed(let reason): return .notSynced(error: reason)
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
