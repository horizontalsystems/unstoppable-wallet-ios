import SwiftUI

struct BackupVerifyWordsView: View {
    @StateObject private var viewModel: BackupVerifyWordsViewModel
    @Binding private var isPresented: Bool
    private let onComplete: (() -> Void)?

    init(account: Account, isPresented: Binding<Bool>, onComplete: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: BackupVerifyWordsViewModel(account: account))
        _isPresented = isPresented
        self.onComplete = onComplete
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: 0) {
                ListSectionFooter(text: "backup_verify_words.description".localized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, .margin32)

                VStack(spacing: .margin16) {
                    ForEach(viewModel.inputViewItems) { item in
                        inputRow(item)
                    }
                }
                .padding(.bottom, .margin16)

                CenteredFlowLayout(itemSpacing: .margin12, lineSpacing: .margin16) {
                    ForEach(viewModel.wordViewItems) { item in
                        ThemeButton(text: item.text, style: .secondary, size: .small) {
                            viewModel.onSelectWord(index: item.id)
                        }
                        .disabled(!item.enabled)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("backup_verify_words.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isPresented = false
                }) {
                    Image("close")
                }
            }
        }
        .onReceive(viewModel.successPublisher) {
            isPresented = false
            onComplete?()
        }
    }

    private func inputRow(_ item: BackupVerifyWordsViewModel.InputViewItem) -> some View {
        ThemeText(item.text, style: .body)
            .frame(maxWidth: .infinity, minHeight: .heightCell48, alignment: .leading)
            .padding(.horizontal, .margin16)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                    .stroke(item.selected ? Color.themeYellow50 : Color.themeBlade, lineWidth: .heightOneDp)
            )
    }
}
