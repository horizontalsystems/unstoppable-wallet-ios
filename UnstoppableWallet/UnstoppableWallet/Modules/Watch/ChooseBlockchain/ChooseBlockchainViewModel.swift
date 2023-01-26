import Foundation
import MarketKit
import RxSwift
import RxRelay
import RxCocoa

class ChooseBlockchainViewModel {
    private var disposeBag = DisposeBag()
    private let service: ChooseBlockchainService
    private let watchRelay = PublishRelay<Void>()
    private let watchEnabledRelay = BehaviorRelay<Bool>(value: false)

    private var enabledBlockchainUids = [String]()

    var viewItems = [CoinToggleViewModel.ViewItem]()

    init(service: ChooseBlockchainService) {
        self.service = service

        viewItems = service.blockchains.map { blockchain in
            return CoinToggleViewModel.ViewItem(
                uid: blockchain.uid,
                imageUrl: blockchain.type.imageUrl,
                placeholderImageName: blockchain.type.placeholderImageName(tokenProtocol: .native),
                title: blockchain.name,
                subtitle: description(blockchainType: blockchain.type),
                badge: nil,
                state: .toggleVisible(enabled: false, hasSettings: false, hasInfo: false)
            )
        }
    }

    private func description(blockchainType: BlockchainType) -> String {
        switch blockchainType {
        case .ethereum: return "ETH, ERC20 tokens"
        case .binanceSmartChain: return "BNB, BEP20 tokens"
        case .polygon: return "MATIC, ERC20 tokens"
        case .avalanche: return "AVAX, ERC20 tokens"
        case .gnosis: return "xDAI, ERC20 tokens"
        case .optimism: return "L2 chain"
        case .arbitrumOne: return "L2 chain"
        default: return ""
        }
    }

}

extension ChooseBlockchainViewModel {

    var watchSignal: Signal<Void> {
        watchRelay.asSignal()
    }

    var watchEnabledDriver: Driver<Bool> {
        watchEnabledRelay.asDriver()
    }

    func onTapWatch() {
        service.watch(enabledBlockchainUids: enabledBlockchainUids)
        watchRelay.accept(())
    }

}

extension ChooseBlockchainViewModel: ICoinToggleViewModel {

    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> {
        Driver.just(viewItems)
    }

    func onEnable(uid: String) {
        if enabledBlockchainUids.isEmpty {
            watchEnabledRelay.accept(true)
        }

        enabledBlockchainUids.append(uid)
    }

    func onDisable(uid: String) {
        if let index = enabledBlockchainUids.firstIndex(of: uid) {
            enabledBlockchainUids.remove(at: index)

            if enabledBlockchainUids.isEmpty {
                watchEnabledRelay.accept(false)
            }
        }
    }

    func onTapSettings(uid: String) { }
    func onTapInfo(uid: String) { }
    func onUpdate(filter: String) {}

}
