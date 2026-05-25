import Combine
import Foundation
import MarketKit
import RxRelay
import RxSwift
import WalletCore

final class AppAdapterManager {
    private let disposeBag = DisposeBag()

    private let engine: AdapterManager

    private let evmBlockchainManager: EvmBlockchainManager
    private let tronKitManager: TronKitManager
    private let tonKitManager: TonKitManager
    private let stellarKitManager: StellarKitManager
    private let zanoKitManager: ZanoKitManager
    private let solanaKitManager: SolanaKitManager
    private let moneroNodeManager: MoneroNodeManager
    private let zanoNodeManager: ZanoNodeManager

    init(
        engine: AdapterManager,
        evmBlockchainManager: EvmBlockchainManager,
        btcBlockchainManager: BtcBlockchainManager,
        tronKitManager: TronKitManager,
        tonKitManager: TonKitManager,
        stellarKitManager: StellarKitManager,
        zanoKitManager: ZanoKitManager,
        solanaKitManager: SolanaKitManager,
        moneroNodeManager: MoneroNodeManager,
        zanoNodeManager: ZanoNodeManager
    ) {
        self.engine = engine
        self.evmBlockchainManager = evmBlockchainManager
        self.tronKitManager = tronKitManager
        self.tonKitManager = tonKitManager
        self.stellarKitManager = stellarKitManager
        self.zanoKitManager = zanoKitManager
        self.solanaKitManager = solanaKitManager
        self.moneroNodeManager = moneroNodeManager
        self.zanoNodeManager = zanoNodeManager

        for blockchain in evmBlockchainManager.allBlockchains {
            if let manager = try? evmBlockchainManager.evmKitManager(blockchainType: blockchain.type) {
                subscribe(disposeBag, manager.evmKitUpdatedObservable) { [weak self] in
                    self?.reloadAdapters(forBlockchainType: blockchain.type)
                }
            }
        }
        subscribe(disposeBag, btcBlockchainManager.restoreModeUpdatedObservable) { [weak self] blockchainType in
            self?.engine.reloadRestoredAdapters(forBlockchainType: blockchainType)
        }
        subscribe(disposeBag, moneroNodeManager.nodeObservable) { [weak self] blockchainType in
            self?.reloadAdapters(forBlockchainType: blockchainType)
        }
        subscribe(disposeBag, zanoNodeManager.nodeObservable) { [weak self] blockchainType in
            self?.zanoKitManager.recreateKit()
            self?.reloadAdapters(forBlockchainType: blockchainType)
        }
        subscribe(disposeBag, tronKitManager.tronKitUpdatedObservable) { [weak self] in
            self?.reloadAdapters(forBlockchainType: .tron)
        }
        subscribe(disposeBag, solanaKitManager.kitStoppedObservable) { [weak self] in
            self?.reloadAdapters(forBlockchainType: .solana)
        }
    }
}

extension AppAdapterManager {
    var adapterData: AdapterManager.AdapterData {
        engine.adapterData
    }

    var adapterDataReadyPublisher: AnyPublisher<AdapterManager.AdapterData, Never> {
        engine.adapterDataReadyPublisher
            .eraseToAnyPublisher()
    }

    func adapter(for wallet: Wallet) -> IAdapter? {
        engine.adapter(for: wallet)
    }

    func adapter(for token: Token) -> IAdapter? {
        engine.adapter(for: token)
    }

    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
        engine.balanceAdapter(for: wallet)
    }

    func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
        engine.depositAdapter(for: wallet)
    }

    func reloadAdapters(forBlockchainType blockchainType: BlockchainType) {
        engine.reloadAdapters(forBlockchainType: blockchainType)
    }

    func refresh() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }

            for blockchain in evmBlockchainManager.allBlockchains {
                try? evmBlockchainManager.evmKitManager(blockchainType: blockchain.type).evmKitWrapper?.evmKit.refresh()
            }

            engine.refreshAdapters()

            tronKitManager.tronKitWrapper?.tronKit.refresh()
            tonKitManager.tonKit?.sync()
            stellarKitManager.stellarKit?.sync()
            zanoKitManager.kit?.refresh()
            solanaKitManager.solanaKit?.refresh()
        }
    }

    func refresh(wallet: Wallet) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }

            if let blockchainType = evmBlockchainManager.blockchain(token: wallet.token)?.type {
                try? evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit.refresh()
            } else if wallet.token.blockchainType == .tron {
                tronKitManager.tronKitWrapper?.tronKit.refresh()
            } else if wallet.token.blockchainType == .ton {
                tonKitManager.tonKit?.sync()
            } else if wallet.token.blockchainType == .stellar {
                stellarKitManager.stellarKit?.sync()
            } else if wallet.token.blockchainType == .solana {
                solanaKitManager.solanaKit?.refresh()
            } else if wallet.token.blockchainType == .monero {
                (engine.adapter(for: wallet) as? MoneroAdapter)?.restart()
            } else if wallet.token.blockchainType == .zano {
                zanoKitManager.kit?.restart()
            } else {
                engine.refreshAdapter(wallet: wallet)
            }
        }
    }
}
