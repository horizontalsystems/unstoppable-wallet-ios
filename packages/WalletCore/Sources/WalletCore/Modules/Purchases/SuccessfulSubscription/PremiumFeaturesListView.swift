import SwiftUI

struct PremiumFeaturesListView: View {
    let features: [PremiumFeature]

    var body: some View {
        ListSection {
            ForEach(features) { feature in
                Cell(
                    left: {
                        ThemeImage(feature.icon, size: .iconSize24, colorStyle: .brand)
                    },
                    middle: {
                        MultiText(title: feature.title, subtitle: feature.description)
                    }
                )
            }
        }
        .themeListStyle(.lawrence)
        .padding(.horizontal, .margin16)
    }
}
