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

                        InputTextRow {
                            TextField("alice.near" as String, text: $viewModel.name)
                                .font(.themeBody)
                                .tint(.themeInputFieldTintColor)
                                .autocorrectionDisabled()
                                .autocapitalization(.none)
                                .focused($inputFocused)
                                .modifier(RightChecking(state: checkingStateBinding))
                        }
                        .modifier(CautionBorder(cautionState: cautionStateBinding))
                        .modifier(CautionPrompt(cautionState: cautionStateBinding))
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: {
                    inputFocused = false
                    viewModel.add()
                }) {
                    Text("button.add".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
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

    private var cautionStateBinding: Binding<CautionState> {
        Binding(
            get: { viewModel.cautionState },
            set: { _ in }
        )
    }
}
