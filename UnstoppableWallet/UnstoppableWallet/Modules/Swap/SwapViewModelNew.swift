import Foundation
import RxSwift
import RxCocoa

class SwapViewModelNew {
    private let service: SwapServiceNew

    let swapDataSourceManager: SwapProviderManager

    init(service: SwapServiceNew, swapDataSourceManager: SwapProviderManager) {
        self.service = service
        self.swapDataSourceManager = swapDataSourceManager
    }

}

extension SwapViewModelNew {

    var dataSource: ISwapDataSource? {
        swapDataSourceManager.dataSourceProvider?.swapDataSource
    }

    var dataSourceUpdated: Driver<()> {
        swapDataSourceManager.dataSourceUpdated.asDriver(onErrorJustReturn: ())
    }

}