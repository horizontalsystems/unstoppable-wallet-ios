import NearKit
import SwiftUI

struct NearAccountNameView: View {
    @StateObject private var viewModel: NearAccountNameViewModel

    @FocusState private var inputFocused: Bool

    init(publicKey: NearKit.PublicKey, onEnterAccountId: @escaping (String) -> Void) {
        _viewModel = StateObject(wrappedValue: NearAccountNameViewModel(publicKey: publicKey, onEnterAccountId: onEnterAccountId))
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin24) {
                        ThemeText("restore.near_account_name.description".localized, style: .subhead)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, .margin16)

                        ThemeInput(
                            caution: viewModel.cautionState,
                            buttons: ThemeInputButton.shortcuts(
                                isEmpty: viewModel.name.isEmpty,
                                whenEmpty: [
                                    .paste(identifier: TestTags.nearAccountNamePaste) { string in
                                        viewModel.name = string.trimmingCharacters(in: .whitespacesAndNewlines)
                                    },
                                ],
                                deleteIdentifier: TestTags.nearAccountNameClear,
                                onDelete: {
                                    viewModel.name = ""
                                }
                            )
                        ) {
                            InputTextView(placeholder: "alice.near", text: $viewModel.name)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($inputFocused)
                                .accessibilityIdentifier(TestTags.nearAccountNameInput)
                                .modifier(RightChecking(state: checkingStateBinding))
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                ThemeButton(text: "button.add".localized) {
                    inputFocused = false
                    viewModel.add()
                }
                .disabled(!viewModel.buttonEnabled)
            }
        }
        .navigationTitle("restore.near_account_name.title".localized)
        .onAppear {
            inputFocused = true
        }
    }

    private var checkingStateBinding: Binding<RightChecking.State> {
        Binding(
            get: { viewModel.loading ? .loading : .idle },
            set: { _ in }
        )
    }
}
