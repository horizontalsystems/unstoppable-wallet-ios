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

                            VStack(spacing: 12) {
                                ListSection {
                                    cell(item: .riskOfRestrictions)
                                    cell(item: .userResponsibility)
                                }

                                ThemeText("swap.terms.footer".localized, style: .subhead)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
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
                ToolbarItem {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    @ViewBuilder private func cell(item: Item) -> some View {
        Cell(
            left: {
                checkboxImage(isSelected: acceptedItems.contains(item))
            },
            middle: {
                VStack(alignment: .leading, spacing: 0) {
                    ThemeText(item.title, style: .subhead, colorStyle: .primary)
                    ThemeText(item.description, style: .subhead)
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

    @ViewBuilder private func checkboxImage(isSelected: Bool) -> some View {
        ThemeImage(isSelected ? "checkbox_circle_on" : "checkbox_circle_off", size: 24, colorStyle: isSelected ? .yellow : .andy)
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
            result.append(textPart(string: "(\("swap.aml".localized))", color: .themeJacob))
            if !components[1].isEmpty { result.append(textPart(string: components[1])) }

            return result
        }

        private func textPart(string: String, color: Color? = nil) -> AttributedString {
            var part = AttributedString(string)

            if let color {
                part.foregroundColor = color
            }

            return part
        }
    }
}
