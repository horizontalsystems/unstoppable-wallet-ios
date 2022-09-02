import UIKit

struct ProFeatures {
    private static let yakFeatures = [
        "pro_features.lock_info.coin_details.volume".localized,
        "pro_features.lock_info.coin_details.liquidity".localized,
        "pro_features.lock_info.coin_details.active_addresses".localized,
        "pro_features.lock_info.coin_details.transaction_count".localized,
        "pro_features.lock_info.coin_details.transaction_volume".localized,
    ]

    static func mountainYakBottomSheet(action: (() -> ())? = nil) -> UIViewController {
        let title = BottomSheetItem.ComplexTitleViewItem(title: "pro_features.lock_info.title".localized, image: UIImage(named: "lock_24")?.withTintColor(.themeJacob))
        let description = InformationModule.Item.description(text: "pro_features.lock_info.coin_details.description".localized, isHighlighted: true)
        let features = InformationModule.Item.section(items: yakFeatures.map {
            .simple(viewItem: BottomSheetItem.SimpleViewItem(title: $0, selected: true))
        })
        let goToMintButton = InformationModule.ButtonItem(style: .yellow, title: "pro_features.lock_info.go_to_mint".localized, action: InformationModule.afterClose(action))

        return InformationModule.viewController(title: .complex(viewItem: title), items: [description, features], buttons: [goToMintButton]).toBottomSheet
    }

}
