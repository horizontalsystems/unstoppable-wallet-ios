import Foundation

class TimeLockInfoDataSource: InfoDataSourceNew {
    var viewItems: [InfoViewModel.ViewItem] {
        [
            .separator,
            .text(string: "lock_info.text".localized)
        ]
    }
}
