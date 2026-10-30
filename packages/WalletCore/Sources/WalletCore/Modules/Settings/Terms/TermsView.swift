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
                        ThemeButton(text: "terms.i_agree".localized) {
                            viewModel.setTermsAccepted()
                            isPresented = false
                            onAccept?()
                        }
                        .disabled(checkedIds.count < viewModel.terms.count)
                    }
                }
            }
            .navigationTitle("terms.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
            .onAppear {
                checkedIds = viewModel.acceptedTermIds
            }
        }
    }

    private func content(readOnly: Bool) -> some View {
        ScrollView {
            VStack(spacing: .margin24) {
                ListSection {
                    ForEach(viewModel.terms) { term in
                        if readOnly {
                            Cell(
                                left: { Image.checkbox(active: true) },
                                middle: { rowTitle(term: term) }
                            )
                        } else {
                            Cell(
                                left: { Image.checkbox(active: checkedIds.contains(term.id)) },
                                middle: { rowTitle(term: term) },
                                action: {
                                    toggleTerm(term)
                                }
                            )
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }

    private func rowTitle(term: TermsManager.Term) -> some View {
        ThemeText(term.localizedKey.localized, style: .subhead, colorStyle: .primary)
    }

    private func toggleTerm(_ term: TermsManager.Term) {
        if checkedIds.contains(term.id) {
            checkedIds.remove(term.id)
        } else {
            checkedIds.insert(term.id)
        }
    }
}
