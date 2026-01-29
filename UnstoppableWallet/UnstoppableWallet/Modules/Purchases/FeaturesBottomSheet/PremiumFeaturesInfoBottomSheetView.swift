import SwiftUI

struct PremiumFeaturesInfoBottomSheetView: View {
    @Binding private var isPresented: Bool

    private let action: () -> Void

    @State private var currentSlideIndex: Int
    var buttonTitle: String

    init(isPresented: Binding<Bool>, currentSlideIndex: Int = 0, buttonTitle: String, action: @escaping () -> Void) {
        _isPresented = isPresented
        self.currentSlideIndex = currentSlideIndex
        self.buttonTitle = buttonTitle
        self.action = action
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                ZStack {
                    VStack {
                        ThemeRadialView(radialPositions: .corners, right: 0x00E1FF) {
                            EmptyView()
                        }
                        .frame(height: 360)
                        .clipped()

                        Spacer()
                    }

                    TabView(selection: $currentSlideIndex) {
                        ForEach(0 ..< PremiumFeature.allCases.count, id: \.self) { index in
                            let feature = PremiumFeature.allCases[index]
                            VStack(spacing: 0) {
                                Image("premium_\(feature.rawValue)")
                                    .padding(.top, feature.topPadding)
                                    .padding(.bottom, feature.bottomPadding)
                                    .frame(height: 360)

                                BSModule.view(for: .title2(text: feature.title))
                                BSModule.view(for: .text(text: ComponentText(text: feature.info, colorStyle: .primary)))
                                Spacer()
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                .frame(height: 505)
                .overlay(alignment: .topTrailing) {
                    IconButton(icon: "close", style: .secondary, size: .small) {
                        isPresented = false
                    }
                    .padding([.top, .trailing], .margin16)
                }

                HStack(spacing: .margin4) {
                    ForEach(0 ..< PremiumFeature.allCases.count, id: \.self) { index in
                        Capsule()
                            .fill(currentSlideIndex == index ? Color.themeJacob : Color.themeAndy)
                            .frame(width: currentSlideIndex == index ? 20 : 8, height: 4)
                            .animation(.spring(response: 0.7, dampingFraction: 0.7), value: currentSlideIndex)
                    }
                }
                .frame(height: .margin32)

                BSModule.view(for: .text(text: ComponentText(
                    text: "purchase.bottom_sheet.description".localized,
                    colorStyle: .yellow
                )))

                BSModule.view(for: .buttonGroup(.init(buttons: [
                    .init(
                        style: .yellow,
                        title: buttonTitle,
                        action: {
                            action()
                        }
                    ),
                ])))
            }
        }
    }
}

private extension PremiumFeature {
    var topPadding: CGFloat {
        switch self {
        case .secureSend, .robberyProtection, .tokenInsights, .advancedSearch, .tradeSignals, .prioritySupport, .swapControl: return .margin24
        default: return 0
        }
    }

    var bottomPadding: CGFloat {
        .margin24 - topPadding
    }
}
