import Foundation

class TimeLockInfoDataSource: InfoDataSource {
    let title = "lock_info.title".localized

    var viewItems: [InfoViewModel.ViewItem] {
        [
            .separator,
            .text(string: "lock_info.text".localized)
        ]
    }
}
