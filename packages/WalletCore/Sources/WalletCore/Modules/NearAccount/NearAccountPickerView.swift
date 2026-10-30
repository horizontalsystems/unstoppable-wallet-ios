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
                                Task { await viewModel.useDefault() }
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
            .onReceive(viewModel.finishPublisher) {
                isPresented = false
            }
        }
        // on the stack, not its root page: the root reappears when the name entry is popped, the stack does not
        .task {
            await viewModel.load()
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
                            Cell(
                                left: {
                                    Image.checkbox(active: viewModel.selectedAccountId == row.accountId)
                                },
                                middle: {
                                    MultiText(title: row.title, subtitle: row.subtitle.isEmpty ? nil : row.subtitle)
                                },
                                action: {
                                    withAnimation(.linear(duration: 0.2)) {
                                        viewModel.selectedAccountId = row.accountId
                                    }
                                }
                            )
                        }
                    }
                    .themeListStyle(.bordered)

                    if let selected = rows.first(where: { $0.accountId == viewModel.selectedAccountId }) {
                        ForEach(selected.warnings, id: \.self) { warning in
                            AlertCardView(warning.alertCardItem)
                                .transition(.opacity)
                        }
                    }

                    ListSection {
                        Cell(
                            middle: {
                                MultiText(title: "restore.near_account.enter_name".localized)
                            },
                            right: {
                                Image.disclosureIcon
                            },
                            action: {
                                nameEntryPresented = true
                            }
                        )
                    }
                    .themeListStyle(.bordered)
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
        } bottomContent: {
            ThemeButton(text: "button.continue".localized) {
                viewModel.select()
            }
            .disabled(viewModel.selectedAccountId == nil)
        }
    }
}

private extension NearAccountPickerViewModel.Warning {
    var alertCardItem: AlertCardViewItem {
        switch self {
        case .accessLost: return AlertCardViewItem(text: "restore.near_account.access_lost".localized, type: .critical)
        case .otherFullAccessKeys: return AlertCardViewItem(text: "restore.near_account.other_keys_warning".localized, type: .critical)
        case .contract: return AlertCardViewItem(text: "restore.near_account.contract_warning".localized, type: .caution)
        }
    }
}
