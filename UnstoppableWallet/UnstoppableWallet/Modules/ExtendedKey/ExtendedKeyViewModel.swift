import RxSwift
import RxRelay
import RxCocoa

class ExtendedKeyViewModel {
    private let service: ExtendedKeyService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem>(value: .empty)

    init(service: ExtendedKeyService) {
        self.service = service

        subscribe(disposeBag, service.itemObservable) { [weak self] in self?.sync(item: $0) }

        sync(item: service.item)
    }

    private func sync(item: ExtendedKeyService.Item) {
        let viewItem = ViewItem(
                derivation: item.derivation.rawValue.uppercased(),
                derivationSwitchable: item.derivationSwitchable,
                blockchain: item.blockchain.map { $0.title },
                blockchainSwitchable: item.blockchainSwitchable,
                account: item.account.map { "\($0)" },
                key: item.key ?? "",
                keyIsPrivate: item.keyIsPrivate
        )

        viewItemRelay.accept(viewItem)
    }
}

extension ExtendedKeyViewModel {

    var viewItemDriver: Driver<ViewItem> {
        viewItemRelay.asDriver()
    }

    var title: String {
        switch service.mode {
        case .bip32RootKey: return "extended_key.bip32_root_key".localized
        case .accountExtendedPrivateKey: return "extended_key.account_extended_private_key".localized
        case .accountExtendedPublicKey: return "extended_key.account_extended_public_key".localized
        }
    }

    var derivationViewItems: [AlertViewItem] {
        MnemonicDerivation.allCases.map { derivation in
            AlertViewItem(
                    text: derivation.rawValue.uppercased(),
                    selected: service.item.derivation == derivation
            )
        }
    }

    var blockchainViewItems: [AlertViewItem] {
        service.supportedBlockchains.map { blockchain in
            AlertViewItem(
                    text: blockchain.title,
                    selected: service.item.blockchain == blockchain
            )
        }
    }

    var accountViewItems: [AlertViewItem] {
        Range<Int>(0...5).map { account in
            AlertViewItem(
                    text: "\(account)",
                    selected: service.item.account == account
            )
        }
    }

    func onSelectDerivation(index: Int) {
        service.set(derivation: MnemonicDerivation.allCases[index])
    }

    func onSelectBlockchain(index: Int) {
        service.set(blockchain: service.supportedBlockchains[index])
    }

    func onSelectAccount(index: Int) {
        service.set(account: index)
    }

}

extension ExtendedKeyViewModel {

    struct ViewItem {
        let derivation: String
        let derivationSwitchable: Bool
        let blockchain: String?
        let blockchainSwitchable: Bool
        let account: String?
        let key: String
        let keyIsPrivate: Bool

        static var empty: ViewItem {
            ViewItem(derivation: "", derivationSwitchable: false, blockchain: nil, blockchainSwitchable: false, account: nil, key: "", keyIsPrivate: false)
        }
    }

}
