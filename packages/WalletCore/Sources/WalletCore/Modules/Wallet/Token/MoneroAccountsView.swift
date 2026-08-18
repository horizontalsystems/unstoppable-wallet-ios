import Foundation
import MarketKit
import MoneroKit
import RxSwift
import SwiftUI

struct MoneroAccountsView: View {
    @StateObject private var viewModel: MoneroAccountsViewModel
    @Binding private var isPresented: Bool

    init(wallet: Wallet, adapter: MoneroAdapter, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: MoneroAccountsViewModel(wallet: wallet, adapter: adapter))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                ScrollView {
                    VStack(spacing: 0) {
                        ListSection {
                            ForEach(viewModel.items) { item in
                                accountCell(item: item)
                            }
                        }

                        ThemeText("monero.accounts.description".localized, style: .subhead)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                }
            }
            .navigationTitle("monero.accounts.title".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        presentNameSheet(
                            title: "monero.accounts.new".localized,
                            buttonTitle: "button.create".localized,
                            initialName: "",
                            requireName: false
                        ) { name in
                            viewModel.createAccount(label: name)
                        }
                    }) {
                        Image("plus")
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isPresented = false }) {
                        Image("close")
                    }
                }
            }
        }
    }

    private func presentNameSheet(title: String, buttonTitle: String, initialName: String, requireName: Bool, onConfirm: @escaping (String) -> Void) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            MoneroAccountNameSheet(
                title: title,
                buttonTitle: buttonTitle,
                requireName: requireName,
                initialName: initialName,
                isPresented: isPresented,
                onConfirm: onConfirm
            )
        }
    }

    // The select area and the rename button are sibling buttons - nesting the rename
    // Button inside the row's own tappable Cell would make the outer row swallow its taps.
    @ViewBuilder private func accountCell(item: MoneroAccountsViewModel.Item) -> some View {
        HStack(spacing: 0) {
            Button(action: {
                viewModel.setActive(index: item.index)
            }) {
                HStack(spacing: .margin8) {
                    MultiText(title: item.title, subtitle: item.balanceText)

                    Spacer()

                    if item.index == viewModel.activeIndex {
                        Image.checkIcon
                    }
                }
                .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: .margin8))
                .contentShape(Rectangle())
            }
            .buttonStyle(CellButtonStyle())

            Button(action: {
                presentNameSheet(
                    title: "monero.accounts.rename".localized,
                    buttonTitle: "button.save".localized,
                    initialName: item.label ?? "",
                    requireName: true
                ) { name in
                    viewModel.renameAccount(index: item.index, label: name)
                }
            }, label: {
                Image("edit_20").renderingMode(.template)
            })
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))
            .padding(.trailing, .margin16)
        }
    }
}

struct MoneroAccountNameSheet: View {
    private static let maxNameLength = 40

    let title: String
    let buttonTitle: String
    let requireName: Bool

    @State private var name: String
    @Binding private var isPresented: Bool
    private let onConfirm: (String) -> Void

    init(title: String, buttonTitle: String, requireName: Bool, initialName: String, isPresented: Binding<Bool>, onConfirm: @escaping (String) -> Void) {
        self.title = title
        self.buttonTitle = buttonTitle
        self.requireName = requireName
        _name = State(initialValue: initialName)
        _isPresented = isPresented
        self.onConfirm = onConfirm
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                BSModule.view(for: .title(title: title))

                InputTextRow(vertical: .margin8) {
                    TextField("monero.accounts.name_placeholder".localized, text: $name)
                        .accentColor(.themeYellow)
                        .autocorrectionDisabled()
                        .font(.themeBody)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > Self.maxNameLength {
                                name = String(newValue.prefix(Self.maxNameLength))
                            }
                        }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin24, trailing: .margin16))

                Button(action: {
                    onConfirm(name)
                    isPresented = false
                }) {
                    Text(buttonTitle)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(requireName && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
        }
    }
}

class MoneroAccountsViewModel: ObservableObject {
    private let adapter: MoneroAdapter
    private let token: Token
    private let disposeBag = DisposeBag()

    @Published var items: [Item] = []
    @Published var activeIndex: UInt32

    init(wallet: Wallet, adapter: MoneroAdapter) {
        self.adapter = adapter
        token = wallet.token
        activeIndex = adapter.activeAccountIndex

        sync(accounts: adapter.accounts)

        adapter.accountsObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] accounts in
                self?.sync(accounts: accounts)
            })
            .disposed(by: disposeBag)
    }

    private func sync(accounts: [MoneroKit.AccountInfo]) {
        activeIndex = adapter.activeAccountIndex

        items = accounts.map { account in
            let title: String
            if let label = account.label, !label.isEmpty {
                title = "\(account.index). \(label)"
            } else {
                title = "\(account.index). " + "monero.account".localized
            }

            let unlocked = Decimal(account.balance.unlocked) / pow(10, token.decimals)
            let balanceText = AppValue(token: token, value: unlocked).formattedFull() ?? "n/a".localized

            return Item(index: account.index, label: account.label, title: title, balanceText: balanceText)
        }
    }

    func setActive(index: UInt32) {
        guard index != activeIndex else { return }

        activeIndex = index

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.adapter.setActiveAccount(index: index)

            DispatchQueue.main.async {
                Core.shared.adapterManager.reloadAdapterData()
            }
        }
    }

    func createAccount(label: String) {
        let resolvedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            _ = try? self?.adapter.createAccount(label: resolvedLabel.isEmpty ? nil : resolvedLabel)
        }
    }

    func renameAccount(index: UInt32, label: String) {
        let resolvedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedLabel.isEmpty else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            try? self?.adapter.setAccountLabel(index: index, label: resolvedLabel)
        }
    }
}

extension MoneroAccountsViewModel {
    struct Item: Identifiable {
        let index: UInt32
        let label: String?
        let title: String
        let balanceText: String

        var id: UInt32 { index }
    }
}
