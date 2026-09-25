import Combine
import Foundation
import MarketKit

// The Standard tab of PreSendView: a direct transfer to the recipient, with memo and destination tag.
public class PreSendViewModel: BasePreSendViewModel {
    @Published var memoType: MemoType = .none
    @Published var destinationTagState: DestinationTagState = .hidden

    @Published var memo: String = "" {
        didSet {
            syncSendData()
        }
    }

    @Published var destinationTag: String = "" {
        didSet {
            syncSendData()
        }
    }

    public convenience init(wallet: Wallet, predefinedAddress: ResolvedAddress?, amount: Decimal?, memo: String?, customDecimals: Int? = nil) {
        self.init(
            wallet: wallet,
            handler: SendHandlerFactory.preSendHandler(wallet: wallet, address: predefinedAddress),
            predefinedAddress: predefinedAddress,
            amount: amount,
            memo: memo,
            customDecimals: customDecimals
        )
    }

    init(wallet: Wallet, handler: IPreSendHandler?, predefinedAddress: ResolvedAddress?, amount: Decimal?, memo: String?, customDecimals: Int? = nil) {
        super.init(wallet: wallet, handler: handler, predefinedAddress: predefinedAddress, amount: amount, initialInputToken: wallet.token, customDecimals: customDecimals)

        if let handler {
            destinationTagState = handler.destinationTagState

            handler.destinationTagStatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.destinationTagState = $0
                    self?.syncSendData()
                }
                .store(in: &cancellables)
        }

        syncMemoType()

        if let memo {
            self.memo = memo
        }

        // Explicit: `memo`'s didSet does not fire from this class's own init, and the base init applied
        // the amount before memo type and destination tag state were known.
        syncSendData()
    }

    // Only the Standard tab tells the shared handler about the recipient: the handler's
    // address-dependent state (e.g. the XRP destination tag) follows the Standard address.
    override func didChangeAddress() {
        handler?.set(address: resolvedAddress?.address)
        syncMemoType()
    }

    override func syncSendData() {
        guard let amount else {
            sendData = nil
            return
        }

        guard let resolvedAddress else {
            sendData = nil
            cautions = []
            return
        }

        guard let handler else {
            sendData = nil
            return
        }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespaces)
        let memo = memoType != .none && !trimmedMemo.isEmpty ? trimmedMemo : nil

        let result = handler.sendData(amount: amount, address: resolvedAddress.address, memo: memo, destinationTagInput: destinationTag)

        switch result {
        case let .valid(sendData):
            self.sendData = ExtendedSendData(sendData: sendData, address: resolvedAddress.address)
            cautions = []
        case let .invalid(cautions):
            sendData = nil
            self.cautions = cautions
        }
    }

    private func syncMemoType() {
        guard let handler else {
            memoType = .none
            return
        }

        memoType = handler.memoType(address: resolvedAddress?.address)
    }
}
