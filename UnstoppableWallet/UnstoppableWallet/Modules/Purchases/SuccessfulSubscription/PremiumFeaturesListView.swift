import SwiftUI

struct PremiumFeaturesListView: View {
    let categories: [PremiumCategory]

    var body: some View {
        ForEach(categories) { category in
            SectionHeader(image: {
                Image(category.icon)
                    .resizable()
                    .renderingMode(.template)
                    .frame(size: .iconSize20)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: 0xFFAA00),
                                Color(hex: 0xFE4A11),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }, text: category.title)

            ListSection {
                ForEach(category.features) { feature in
                    row(
                        title: feature.title,
                        description: feature.description,
                        icon: feature.icon,
                        action: {
                            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                PremiumFeaturesInfoBottomSheetView(isPresented: isPresented, currentSlideIndex: feature.index, action: {
                                    isPresented.wrappedValue = false
                                })
                            }
                        }
                    )
                }
            }
            .themeListStyle(.lawrence)
            .padding(.horizontal, .margin16)
        }
    }

    @ViewBuilder private func row(title: String, description: String, icon: String, action: @escaping () -> Void) -> some View {
        Cell(
            left: {
                Image(icon).icon(colorStyle: .yellow)
            },
            middle: {
                MultiText(eyebrow: ComponentText(text: title, colorStyle: .primary), description: description)
            },
            action: action
        )
    }
}
