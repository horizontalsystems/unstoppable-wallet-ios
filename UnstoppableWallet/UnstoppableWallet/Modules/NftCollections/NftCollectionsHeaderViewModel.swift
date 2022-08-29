//import RxSwift
//import RxRelay
//import RxCocoa
//
//class NftCollectionsHeaderViewModel {
//    private let service: NftCollectionsService
//    private let disposeBag = DisposeBag()
//
//    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
//    private let playHapticRelay = PublishRelay<()>()
//
//    init(service: NftCollectionsService) {
//        self.service = service
//
//        subscribe(disposeBag, service.totalItemObservable) { [weak self] in self?.sync(totalItem: $0) }
//        subscribe(disposeBag, service.balanceHiddenObservable) { [weak self] _ in self?.onUpdateBalanceHidden() }
//
//        sync(totalItem: service.totalItem)
//    }
//
//    private func sync(totalItem: NftCollectionsService.TotalItem?) {
//        let viewItem: ViewItem? = totalItem.flatMap { totalItem in
//            let balanceHidden = service.balanceHidden
//
//            let amount = balanceHidden ? "*****" : ValueFormatter.instance.formatShort(currencyValue: totalItem.currencyValue)
//
//            let convertedValue: String
//            if balanceHidden {
//                convertedValue = "*****"
//            } else if let value = totalItem.convertedValue, let formattedValue = ValueFormatter.instance.formatShort(coinValue: value) {
//                convertedValue = "≈ \(formattedValue)"
//            } else {
//                convertedValue = "---"
//            }
//
//            return ViewItem(
//                    amount: amount,
//                    amountExpired: balanceHidden ? false : totalItem.expired,
//                    convertedValue: convertedValue,
//                    convertedValueExpired: balanceHidden ? false : totalItem.convertedValueExpired
//            )
//        }
//
//        viewItemRelay.accept(viewItem)
//    }
//
//    private func onUpdateBalanceHidden() {
//        sync(totalItem: service.totalItem)
//    }
//
//    private func title(mode: NftCollectionsService.Mode) -> String {
//        switch mode {
//        case .lastSale: return "nft_collections.last_sale".localized
//        case .average7d: return "nft_collections.average_7d".localized
//        case .average30d: return "nft_collections.average_30d".localized
//        }
//    }
//
//}
//
//extension NftCollectionsHeaderViewModel {
//
//    var viewItemDriver: Driver<ViewItem?> {
//        viewItemRelay.asDriver()
//    }
//
//    var playHapticSignal: Signal<()> {
//        playHapticRelay.asSignal()
//    }
//
//    var priceTypeItems: [String] {
//        NftCollectionsService.Mode.allCases.map { title(mode: $0) }
//    }
//
//    var priceTypeIndex: Int {
//        NftCollectionsService.Mode.allCases.firstIndex(of: service.mode) ?? 0
//    }
//
//    func onTapTotalAmount() {
//        service.toggleBalanceHidden()
//        playHapticRelay.accept(())
//    }
//
//    func onTapConvertedTotalAmount() {
//        service.toggleConversionCoin()
//        playHapticRelay.accept(())
//    }
//
//    func onSelectPriceType(index: Int) {
//        service.mode = NftCollectionsService.Mode.allCases[index]
//    }
//
//}
//
//extension NftCollectionsHeaderViewModel {
//
//    struct ViewItem {
//        let amount: String?
//        let amountExpired: Bool
//        let convertedValue: String?
//        let convertedValueExpired: Bool
//    }
//
//}
