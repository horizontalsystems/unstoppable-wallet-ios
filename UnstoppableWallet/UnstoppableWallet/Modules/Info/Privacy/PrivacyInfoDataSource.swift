import Foundation

class PrivacyInfoDataSource: InfoDataSource {
    let title = "settings_privacy_info.title".localized

    var viewItems: [InfoViewModel.ViewItem] {
        [
            .separator,
            .text(string: "settings_privacy_info.description".localized),
            .header(title: "settings_privacy_info.header_blockchain_transactions".localized),
            .text(string: "settings_privacy_info.content_blockchain_transactions".localized),
            .header(title: "settings_privacy_info.header_blockchain_connection".localized),
            .text(string: "settings_privacy_info.content_blockchain_connection".localized),
            .header(title: "settings_privacy_info.header_blockchain_restore".localized),
            .text(string: "settings_privacy_info.content_blockchain_restore".localized)
        ]
    }
}
