import Foundation

class FeeInfoDataSource: InfoDataSource {
    let title = "send.fee_info.title".localized

    var viewItems: [InfoViewModel.ViewItem] {
        [
            .separator,
            .text(string: "send.fee_info.description".localized),
            .header(title: "send.fee_info.header_slow".localized),
            .text(string: "send.fee_info.content_slow".localized),
            .header(title: "send.fee_info.header_average".localized),
            .text(string: "send.fee_info.content_average".localized),
            .header(title: "send.fee_info.header_fast".localized),
            .text(string: "send.fee_info.content_fast".localized),
            .margin(height: .margin24),
            .text(string: "send.fee_info.content_conclusion".localized)
        ]
    }
}
