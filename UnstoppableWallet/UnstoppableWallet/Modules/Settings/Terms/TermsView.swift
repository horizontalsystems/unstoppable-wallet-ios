import SwiftUI

struct TermsView: View {
    private let termCount = 2

    @StateObject private var viewModel = TermsViewModelNew()

    @Binding var isPresented: Bool
    let onAccept: (() -> ())?

    @State private var checkedIndices = Set<Int>()

    init(isPresented: Binding<Bool>, onAccept: (() -> ())? = nil) {
        _isPresented = isPresented
        self.onAccept = onAccept
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                if viewModel.termsAccepted {
                    content()
                } else {
                    BottomGradientWrapper {
                        content()
                    } bottomContent: {
                        Button(action: {
                            viewModel.setTermsAccepted()
                            isPresented = false
                            onAccept?()
                        }) {
                            Text("terms.i_agree".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .yellow))
                        .disabled(checkedIndices.count < termCount)
                    }
                }
            }
            .navigationTitle("terms.title".localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    @ViewBuilder private func content() -> some View {
        ScrollView {
            VStack(spacing: .margin24) {
                ListSection {
                    ForEach(0 ..< termCount, id: \.self) { index in
                        if viewModel.termsAccepted {
                            ListRow {
                                rowContent(index: index, checked: true)
                            }
                        } else {
                            ClickableRow(action: {
                                if checkedIndices.contains(index) {
                                    checkedIndices.remove(index)
                                } else {
                                    checkedIndices.insert(index)
                                }
                            }) {
                                rowContent(index: index, checked: checkedIndices.contains(index))
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }

    @ViewBuilder private func rowContent(index: Int, checked: Bool) -> some View {
        Image(checked ? "checkbox_active_24" : "checkbox_diactive_24")
        Text("terms.item.\(index + 1)".localized).themeSubhead2(color: .themeLeah)
    }
}
