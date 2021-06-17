import Foundation
import RxCocoa
import RxRelay

class SwapSettingsViewModel {
    private let service: SwapSettingsService

    let swapDataSourceManager: SwapProviderManager

    init(service: SwapSettingsService, swapDataSourceManager: SwapProviderManager) {
        self.service = service
        self.swapDataSourceManager = swapDataSourceManager
    }

}

extension SwapSettingsViewModel {

    var provider: String? {
        swapDataSourceManager.dex?.provider.rawValue
    }

    var dataSource: ISwapSettingsDataSource? {
        swapDataSourceManager.dataSourceProvider?.swapSettingsDataSource
    }

    var dataSourceUpdated: Driver<()> {
        swapDataSourceManager.dataSourceUpdated.asDriver(onErrorJustReturn: ())
    }

}