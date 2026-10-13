import NearKit
import SwiftUI

struct NearAccountPickerView: View {
    @StateObject private var viewModel: NearAccountPickerViewModel
    @Binding var isPresented: Bool

    @State private var nameEntryPresented = false

    init(publicKey: NearKit.PublicKey, isPresented: Binding<Bool>, onSelect: @escaping (String) -> Void, onUseDefault: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: NearAccountPickerViewModel(publicKey: publicKey, onSelect: onSelect, onUseDefault: onUseDefault))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case let .loaded(rows):
                    list(rows: rows)
                case .failed:
                    PlaceholderViewNew(icon: "warning_filled", subtitle: "restore.near_account.search_failed".localized) {
                        VStack(spacing: .margin16) {
                            ThemeButton(text: "button.retry".localized, mode: .transparent, size: .small) {
                                Task { await viewModel.load() }
                            }
                            ThemeButton(text: "restore.near_account.enter_name".localized, mode: .transparent, size: .small) {
                                nameEntryPresented = true
                            }
                            ThemeButton(text: "restore.near_account.use_default".localized, mode: .transparent, size: .small) {
                                viewModel.useDefault()
                            }
                        }
                    }
                }
            }
            .navigationTitle("restore.near_account.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
            .navigationDestination(isPresented: $nameEntryPresented) {
                NearAccountNameView(publicKey: viewModel.publicKey) { accountId in
                    nameEntryPresented = false
                    Task { await viewModel.add(accountId: accountId) }
                }
            }
            .task {
                await viewModel.load()
            }
            .onReceive(viewModel.finishPublisher) {
                isPresented = false
            }
        }
    }

    @ViewBuilder private func list(rows: [NearAccountPickerViewModel.Row]) -> some View {
        BottomGradientWrapper {
            ScrollView {
                VStack(spacing: .margin24) {
                    ThemeText("restore.near_account.description".localized, style: .subhead)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, .margin16)

                    ListSection {
                        ForEach(rows) { row in
                            ClickableRow(action: {
                                viewModel.selectedAccountId = row.accountId
                            }) {
                                Image(viewModel.selectedAccountId == row.accountId ? "circle_radioon_24" : "circle_radiooff_24")

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(row.title).themeBody()
                                    if !row.subtitle.isEmpty {
                                        Text(row.subtitle).themeSubhead2()
                                    }
                                }
                            }
                        }
                    }
                    .themeListStyle(.bordered)

                    ListSection {
                        ClickableRow(action: {
                            nameEntryPresented = true
                        }) {
                            Text("restore.near_account.enter_name".localized).themeBody()
                            Spacer()
                            Image.disclosureIcon
                        }
                    }
                    .themeListStyle(.bordered)
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
        } bottomContent: {
            Button(action: {
                viewModel.select()
            }) {
                Text("button.continue".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .yellow))
            .disabled(viewModel.selectedAccountId == nil)
        }
    }
}
