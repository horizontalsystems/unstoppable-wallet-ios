import Combine
import Foundation
import MarketKit

// The Private tab of PreSendView. Deliberately thin: no quoting, no tasks, nothing to cancel. The
// `.privateSend` SendData is built synchronously; all network work lives in PrivateSendHandler, on the
// confirmation screen, where the deposit transfer is built from a snapshot of the shared `handler`'s
// settings taken here, on the main thread.
final class PrivatePreSendViewModel: BasePreSendViewModel {
    private let service: PrivateSendService?

    // A synchronous read of the already-background-synced confidential token cache: it never blocks
    // and never triggers a fetch on the render path.
    @Published private(set) var isSupported: Bool

    init(wallet: Wallet, handler: IPreSendHandler?, service: PrivateSendService?, predefinedAddress: ResolvedAddress?, amount: Decimal?) {
        self.service = service
        isSupported = Self.isSupported(token: wallet.token, service: service)

        super.init(wallet: wallet, handler: handler, predefinedAddress: predefinedAddress, amount: amount, initialInputToken: wallet.token)

        service?.syncPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.syncSupported() }
            .store(in: &cancellables)
    }

    // Never calls `handler.set(address:)`: the shared handler's address-dependent state belongs to the
    // Standard tab, and the private deposit address does not exist until the order is committed.
    override func syncSendData() {
        guard isSupported, let amount, amount != 0, let resolvedAddress else {
            sendData = nil
            cautions = []
            return
        }

        let request = PrivateSendRequest(
            token: token,
            recipient: resolvedAddress.address,
            amount: amount,
            depositSettings: handler?.depositSettingsSnapshot
        )

        // The real recipient, never a deposit address.
        sendData = ExtendedSendData(sendData: .privateSend(request: request), address: resolvedAddress.address)
        cautions = []
    }

    private func syncSupported() {
        let isSupported = Self.isSupported(token: token, service: service)

        guard isSupported != self.isSupported else {
            return
        }

        self.isSupported = isSupported
        syncSendData()
    }

    // A nil service yields false permanently, so an app that never wires private send is unaffected.
    // XRP is rejected by PrivateSendHandlerProvider, so the tab must not offer it either.
    private static func isSupported(token: Token, service: PrivateSendService?) -> Bool {
        guard token.blockchainType != .xrp else {
            return false
        }

        return service?.isSupported(token: token) ?? false
    }
}
