import MarketKit
import SwiftUI
import WalletCore

struct CryptoPaySendTokenListView: View {
    @StateObject private var viewModel: CryptoPaySendTokenListViewModel
    @State private var path = NavigationPath()
    @State private var selectedSendData: SendData?
    @Binding var isPresented: Bool

    init(url: URL, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: CryptoPaySendTokenListViewModel(url: url))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView(style: .list) {
                content
            }
            .navigationTitle("send.send".localized)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .send:
                    if let sendData = selectedSendData {
                        RegularSendView(sendData: sendData, address: nil) {
                            isPresented = false
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            VStack {
                ProgressView()
            }
            .frame(maxHeight: .infinity)
        case let .failed(error):
            PlaceholderViewNew(icon: "warning_filled", subtitle: error.smartDescription) {
                ThemeButton(text: "button.retry".localized, mode: .transparent, size: .small) {
                    Task { await viewModel.load() }
                }
            }
        case let .loaded(payment):
            LoadedTokenList(viewModel: viewModel, payment: payment) { sendData in
                selectedSendData = sendData
                path.append(Route.send)
            }
        }
    }
}

extension CryptoPaySendTokenListView {
    private enum Route: Hashable {
        case send
    }
}

private struct LoadedTokenList: View {
    @ObservedObject var viewModel: CryptoPaySendTokenListViewModel
    @StateObject private var pickerViewModel: SendTokenListViewModel
    @State private var searchText = ""

    private let payment: OpenCryptoPayPayment
    private let onSendDataReady: (SendData) -> Void

    init(viewModel: CryptoPaySendTokenListViewModel,
         payment: OpenCryptoPayPayment,
         onSendDataReady: @escaping (SendData) -> Void)
    {
        self.viewModel = viewModel
        let tokens = payment.entries.map { SendTokenListViewModel.SendOptions.TokenAmount(token: $0.token, amount: $0.displayAmount) }
        let options = SendTokenListViewModel.SendOptions(tokens: tokens)
        _pickerViewModel = StateObject(wrappedValue: SendTokenListViewModel(options: options))
        self.payment = payment
        self.onSendDataReady = onSendDataReady
    }

    var body: some View {
        VStack(spacing: 0) {
            ThemeText("open_crypto_pay.token_list.description".localized, style: .subhead)
                .padding(.horizontal, .margin16)
                .padding(.top, .margin12)
                .padding(.bottom, .margin32)
                .frame(maxWidth: .infinity)
                .background(Color.themeTyler)

            WalletPickerView(
                viewModel: pickerViewModel,
                searchText: $searchText,
                blockchainFilter: .constant(nil),
                onSelect: { wallet in
                    select(wallet: wallet)
                },
                onFailed: { wallet, state in
                    Coordinator.shared.presentBalanceError(wallet: wallet, state: state)
                }
            )
        }
        .searchBar(text: $searchText, prompt: "placeholder.search".localized)
    }

    private func select(wallet: Wallet) {
        stat(page: .sendTokenList, event: .openSend(token: wallet.token))

        Task { @MainActor in
            HudHelper.instance.show(banner: .preparing)
            do {
                let sendData = try await viewModel.resolve(wallet: wallet, payment: payment)
                HudHelper.instance.hide()
                onSendDataReady(sendData)
            } catch is CancellationError {
                HudHelper.instance.hide()
            } catch {
                HudHelper.instance.hide()
                HudHelper.instance.show(banner: .error(string: error.smartDescription))
            }
        }
    }
}
