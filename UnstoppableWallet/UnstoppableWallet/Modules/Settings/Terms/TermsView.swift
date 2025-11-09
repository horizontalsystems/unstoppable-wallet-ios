import SwiftUI

struct TermsView: View {
    @StateObject private var viewModel = TermsViewModel()

    @Binding var isPresented: Bool
    let onAccept: (() -> Void)?

    @State private var checkedIds = Set<String>()

    init(isPresented: Binding<Bool>, onAccept: (() -> Void)? = nil) {
        _isPresented = isPresented
        self.onAccept = onAccept
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                if viewModel.allTermsAccepted {
                    content(readOnly: true)
                } else {
                    BottomGradientWrapper {
                        content(readOnly: false)
                    } bottomContent: {
                        Button(action: {
                            viewModel.setTermsAccepted()
                            isPresented = false
                            onAccept?()
                        }) {
                            Text("terms.i_agree".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .yellow))
                        .disabled(checkedIds.count < viewModel.terms.count)
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
            .onAppear {
                checkedIds = viewModel.acceptedTermIds
            }
        }
    }

    @ViewBuilder private func content(readOnly: Bool) -> some View {
        ScrollView {
            VStack(spacing: .margin24) {
                ListSection {
                    ForEach(viewModel.terms) { term in
                        if readOnly {
                            ListRow {
                                rowContent(term: term, checked: true)
                            }
                        } else {
                            ClickableRow(action: {
                                toggleTerm(term)
                            }) {
                                rowContent(term: term, checked: checkedIds.contains(term.id))
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }

    @ViewBuilder private func rowContent(term: TermsManager.Term, checked: Bool) -> some View {
        Image(checked ? "checkbox_active_24" : "checkbox_diactive_24")
        Text(term.localizedKey.localized)
            .themeSubhead2(color: .themeLeah)
    }

    private func toggleTerm(_ term: TermsManager.Term) {
        if checkedIds.contains(term.id) {
            checkedIds.remove(term.id)
        } else {
            checkedIds.insert(term.id)
        }
    }
}
