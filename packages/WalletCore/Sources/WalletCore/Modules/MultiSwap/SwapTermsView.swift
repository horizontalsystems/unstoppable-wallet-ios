import SwiftUI

struct SwapTermsView: View {
    @Binding var isPresented: Bool
    let onAgree: () -> Void

    @State private var acceptedItems = Set<Item>()

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 24) {
                            ThemeText("swap.terms.description".localized, style: .subhead)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)

                            ListSection {
                                cell(item: .riskOfRestrictions)
                                cell(item: .userResponsibility)
                            }
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                    }
                } bottomContent: {
                    ThemeButton(text: "terms.i_agree".localized) {
                        isPresented = false
                        onAgree()
                    }
                    .disabled(acceptedItems.count != Item.allCases.count)
                }
            }
            .navigationTitle("swap.terms.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }

    @ViewBuilder private func cell(item: Item) -> some View {
        Cell(
            left: {
                Image.checkbox(active: acceptedItems.contains(item))
            },
            middle: {
                VStack(alignment: .leading, spacing: 0) {
                    ThemeText(item.title, style: .subhead, colorStyle: .primary)
                    ThemeText(item.description, style: .subhead)
                        .environment(\.openURL, OpenURLAction { url in
                            guard url == Item.providerInfoUrl else {
                                return .systemAction
                            }

                            onTapProviderInfo()
                            return .handled
                        })
                }
            },
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.linear(duration: 0.2)) {
                if acceptedItems.contains(item) {
                    acceptedItems.remove(item)
                } else {
                    acceptedItems.insert(item)
                }
            }
        }
    }
}

extension SwapTermsView {
    enum Item: CaseIterable {
        case riskOfRestrictions
        case userResponsibility

        var title: String {
            switch self {
            case .riskOfRestrictions: return "swap.terms.risk_of_restrictions".localized
            case .userResponsibility: return "swap.terms.user_responsibility".localized
            }
        }

        var description: ThemeText.TextType {
            switch self {
            case .riskOfRestrictions: return .attributed(riskOfRestrictionsText)
            case .userResponsibility: return .plain("swap.terms.user_responsibility.description".localized)
            }
        }

        var riskOfRestrictionsText: AttributedString {
            let string = "swap.terms.risk_of_restrictions.description".localized
            let components = string.components(separatedBy: "%@")

            guard components.count == 2 else {
                return AttributedString(string)
            }

            var result = AttributedString("")

            if !components[0].isEmpty { result.append(textPart(string: components[0])) }
            result.append(textPart(string: "swap.quotes.providers.risk_levels.title".localized, color: .themeJacob, url: Self.providerInfoUrl))
            if !components[1].isEmpty { result.append(textPart(string: components[1])) }

            return result
        }

        static let providerInfoUrl = URL(string: "unstoppable://swap-provider-info")!

        private func textPart(string: String, color: Color? = nil, url: URL? = nil) -> AttributedString {
            var part = AttributedString(string)

            if let color {
                part.foregroundColor = color
                part.underlineStyle = .single
            }
            part.link = url

            return part
        }
    }
    
    private func onTapProviderInfo() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            MultiSwapProviderTypeBottomSheet(isPresented: isPresented)
        }
    }
}
