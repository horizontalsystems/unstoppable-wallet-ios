import Foundation
import RxSwift
import RxCocoa
import UniswapKit

class Swap2ViewModel {
    private let disposeBag = DisposeBag()

    private let service: Swap2Service

    private var isSwapDataLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var isSwapDataHiddenRelay = BehaviorRelay<Bool>(value: true)
    private var swapDataErrorRelay = BehaviorRelay<Error?>(value: nil)
    private var tradeViewItemRelay = BehaviorRelay<Swap2Module.TradeViewItem?>(value: nil)

    private var estimatedRelay = BehaviorRelay<TradeType>(value: .exactIn)
    private var fromAmountRelay = BehaviorRelay<String?>(value: nil)
    private var fromTokenCodeRelay = BehaviorRelay<String>(value: "swap.token")
    private var fromBalanceRelay = BehaviorRelay<String?>(value: nil)
    private var balanceErrorRelay = BehaviorRelay<Error?>(value: nil)

    private var isAllowanceHiddenRelay = BehaviorRelay<Bool>(value: true)
    private var isAllowanceLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var allowanceRelay = BehaviorRelay<String?>(value: nil)
    private var allowanceErrorRelay = BehaviorRelay<Error?>(value: nil)

    private var toAmountRelay = BehaviorRelay<String?>(value: nil)
    private var toTokenCodeRelay = BehaviorRelay<String>(value: "swap.token")
    private var actionTitleRelay = BehaviorRelay<String?>(value: nil)
    private var isActionEnabledRelay = BehaviorRelay<Bool>(value: false)

    init(service: Swap2Service) {
        self.service = service

//        service.categories
//                .subscribe(onNext: { [weak self] dataState in
//                    self?.handle(dataState: dataState)
//                })
//                .disposed(by: disposeBag)
    }

//    private func handle(dataState: DataState<[GuideCategoryItem]>) {
//        if case .loading = dataState {
//            loadingRelay.accept(true)
//        } else {
//            loadingRelay.accept(false)
//        }
//
//        if case .success(let categories) = dataState {
//            self.categories = categories
//
//            filterViewItemsRelay.accept(categories.map { $0.title })
//
//            syncViewItems()
//        }
//
//        if case .error(let error) = dataState {
//            errorRelay.accept(error.convertedError)
//        } else {
//            errorRelay.accept(nil)
//        }
//    }
//
//    private func syncViewItems() {
//        guard categories.count > currentCategoryIndex else {
//            return
//        }
//
//        let viewItems = categories[currentCategoryIndex].items.map { item in
//            GuideViewItem(
//                    title: item.title,
//                    date: item.date,
//                    imageUrl: item.imageUrl,
//                    url: item.url
//            )
//        }
//
//        viewItemsRelay.accept(viewItems)
//    }

}

extension Swap2ViewModel: ISwap2ViewModel {

    var isSwapDataLoading: Driver<Bool> {
        isSwapDataLoadingRelay.asDriver()
    }

    var swapDataError: Driver<Error?> {
        swapDataErrorRelay.asDriver()
    }

    var estimated: Driver<UniswapKit.TradeType> {
        estimatedRelay.asDriver()
    }

    var fromAmount: Driver<String?> {
        fromAmountRelay.asDriver()
    }

    var fromTokenCode: Driver<String> {
        fromTokenCodeRelay.asDriver()
    }

    var fromBalance: Driver<String?> {
        fromBalanceRelay.asDriver()
    }

    var balanceError: Driver<Error?> {
        balanceErrorRelay.asDriver()
    }

    var isAllowanceHidden: Driver<Bool> {
        isAllowanceHiddenRelay.asDriver()
    }

    var isAllowanceLoading: Driver<Bool> {
        isAllowanceLoadingRelay.asDriver()
    }

    var allowance: Driver<String?> {
        allowanceRelay.asDriver()
    }

    var allowanceError: Driver<Error?> {
        allowanceErrorRelay.asDriver()
    }

    var toAmount: Driver<String?> {
        toAmountRelay.asDriver()
    }

    var toTokenCode: Driver<String> {
        toTokenCodeRelay.asDriver()
    }

    var tradeViewItem: Driver<Swap2Module.TradeViewItem?> {
        tradeViewItemRelay.asDriver()
    }

    var actionTitle: Driver<String?> {
        actionTitleRelay.asDriver()
    }

    var isActionEnabled: Driver<Bool> {
        isActionEnabledRelay.asDriver()
    }

    var isSwapDataHidden: Driver<Bool> {
        isSwapDataHiddenRelay.asDriver()
    }

    func onChangeFrom(amount: String?) {
    }

    func onSelectFrom(coin: Coin) {
    }

    func onChangeTo(amount: String?) {
    }

    func onSelectTo(coin: Coin) {
    }

    func onTapButton() {
    }

}
