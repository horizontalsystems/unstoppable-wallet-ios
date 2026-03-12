import SwiftUI

struct MultiSwapProviderTypeBottomSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                BSModule.view(for: .title(title: "swap.quotes.providers.risk_levels.title".localized))
                BSModule.view(for: .footer(text: "swap.quotes.providers.risk_levels.description".localized))

                ListSection {
                    ForEach(SwapProviderType.allCases) { type in
                        HStack {
                            VStack(alignment: .leading, spacing: .margin4) {
                                BadgeViewNew(type.title, mode: .transparent, colorStyle: type.colorStyle)

                                ThemeText("swap.quotes.providers.risk_levels.\(type.rawValue).description".localized, style: .subhead)
                            }

                            Spacer()
                        }
                        .padding(.margin16)
                    }
                }
                .themeListStyle(.bordered)
                .padding(.init(top: .margin8, leading: .margin16, bottom: 0, trailing: .margin16))

                BSModule.view(for: .buttonGroup(.init(buttons: [
                    .init(
                        style: .gray,
                        title: "button.close".localized,
                        action: {
                            $isPresented.wrappedValue = false
                        }
                    ),
                ])))
            }
        }
    }
}
