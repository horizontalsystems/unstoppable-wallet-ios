import Foundation
import MarketKit

enum OpenCryptoPaySendHandlerFactory {
    static func handler(payment: OpenCryptoPayPayment,
                        entry: OpenCryptoPayPayment.Entry,
                        inner: SendData) -> ISendHandler?
    {
        // Reject accidental nesting.
        if case .openCryptoPay = inner { return nil }

        let manager = Core.shared.openCryptoPay.manager

        guard let innerHandler = SendHandlerFactory.handler(sendData: inner) else { return nil }
        guard let broadcaster = manager.broadcasterFactory.make(method: entry.method, token: entry.token) else {
            return nil
        }

        let submitter = OpenCryptoPaySubmitter(provider: manager.provider)

        return OpenCryptoPaySendHandler(
            payment: payment,
            entry: entry,
            innerHandler: innerHandler,
            broadcaster: broadcaster,
            submitter: submitter,
            paymentManager: Core.shared.openCryptoPay.paymentManager
        )
    }
}
