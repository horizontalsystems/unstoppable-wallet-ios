import Combine
import Foundation

// Owns the one send-settings handler shared by every PreSendView tab, plus the per-tab view models.
// Everything is created inside a single `@StateObject` autoclosure, so the tabs are guaranteed to share
// the same handler and their state survives tab switches.
final class PreSendTabsViewModel: ObservableObject {
    private let wallet: Wallet
    private let crossPayVisible: Bool
    private var cancellables = Set<AnyCancellable>()

    let handler: IPreSendHandler?
    let standard: PreSendViewModel
    let privateSend: PrivatePreSendViewModel

    @Published var currentTab: PreSendTab = .standard
    @Published private(set) var tabs: [PreSendTab] = []
    @Published private(set) var settingsModified: Bool

    init(wallet: Wallet, predefinedAddress: ResolvedAddress?, amount: Decimal?, memo: String?, crossPayVisible: Bool) {
        self.wallet = wallet
        self.crossPayVisible = crossPayVisible

        let handler = SendHandlerFactory.preSendHandler(wallet: wallet, address: predefinedAddress)
        self.handler = handler

        standard = PreSendViewModel(wallet: wallet, handler: handler, predefinedAddress: predefinedAddress, amount: amount, memo: memo)
        privateSend = PrivatePreSendViewModel(wallet: wallet, handler: handler, service: Core.privateSendService, predefinedAddress: predefinedAddress, amount: amount)

        settingsModified = handler?.settingsModified ?? false

        handler?.settingsModifiedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.settingsModified = $0 }
            .store(in: &cancellables)

        privateSend.$isSupported
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncTabs() }
            .store(in: &cancellables)

        syncTabs()
    }

    private func syncTabs() {
        tabs = [.standard] + (privateSend.isSupported ? [.privateSend] : []) + (crossPayVisible ? [.crossPay] : [])

        if !tabs.contains(currentTab) {
            currentTab = .standard
        }
    }
}

extension PreSendTabsViewModel {
    var title: String {
        handler?.title(wallet.token.coin.code) ?? "send.send".localized
    }

    // Settings are shared, so a change made on any tab re-syncs every tab's send data.
    func syncSendData() {
        settingsModified = handler?.settingsModified ?? false
        standard.syncSendData()
        privateSend.syncSendData()
    }
}

enum PreSendTab: CaseIterable {
    case standard
    case privateSend
    case crossPay

    var title: String {
        switch self {
        case .standard: return "send.tab.standard".localized
        case .privateSend: return "send.tab.private".localized
        case .crossPay: return "send.tab.cross_pay".localized
        }
    }

    var icon: String? {
        switch self {
        case .privateSend: return "fraud"
        default: return nil
        }
    }
}
