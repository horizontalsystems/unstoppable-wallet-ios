import MarketKit
import SwiftUI

struct BirthdayInputView: View {
    @StateObject private var viewModel: BirthdayInputViewModel
    @Environment(\.presentationMode) private var presentationMode

    private let blockchain: Blockchain

    @FocusState private var inputFocused: Bool

    init(blockchain: Blockchain, initialHeight: Int? = nil, provider: IBirthdayInputProvider, onEnterBirthdayHeight: @escaping (Int) -> Void) {
        _viewModel = StateObject(wrappedValue: BirthdayInputViewModel(initialHeight: initialHeight, provider: provider, onEnterBirthdayHeight: onEnterBirthdayHeight))
        self.blockchain = blockchain
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 24) {
                            ThemeText("birthday_input.description".localized, style: .subhead)
                                .padding(.horizontal, 16)

                            VStack(spacing: 8) {
                                InputTextRow {
                                    ShortcutButtonsView(
                                        content: {
                                            InputTextView(
                                                placeholder: viewModel.placeholder,
                                                text: $viewModel.heightString
                                            )
                                            .keyboardType(.numberPad)
                                            .autocorrectionDisabled()
                                            .focused($inputFocused)
                                        },
                                        showDelete: .init(get: { !viewModel.heightString.isEmpty }, set: { _ in }),
                                        items: [.icon("date"), .text("button.paste".localized)],
                                        onTap: { index in
                                            switch index {
                                            case 0:
                                                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                                    BirthdayPickerView(
                                                        date: viewModel.defaultDate,
                                                        startDate: viewModel.startDate,
                                                        isPresented: isPresented
                                                    ) { date in
                                                        viewModel.handle(date: date)
                                                    }
                                                }
                                            case 1:
                                                if let string = UIPasteboard.general.string {
                                                    viewModel.heightString = string.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                                                }
                                            default: ()
                                            }
                                        }, onTapDelete: {
                                            viewModel.heightString = ""
                                        }
                                    )
                                }

                                HStack {
                                    ThemeText("birthday_input.block_date".localized, style: .caption)
                                    Spacer()
                                    ThemeText(viewModel.date.map { DateHelper.instance.formatFullDateOnly(from: $0) } ?? "n/a".localized, style: .captionSB)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                    }
                    .onTapGesture {
                        inputFocused = false
                    }
                } bottomContent: {
                    Button(action: {
                        viewModel.apply()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(viewModel.buttonTitle)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                    .disabled(!viewModel.buttonEnabled)
                }
            }
            .navigationTitle(blockchain.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
