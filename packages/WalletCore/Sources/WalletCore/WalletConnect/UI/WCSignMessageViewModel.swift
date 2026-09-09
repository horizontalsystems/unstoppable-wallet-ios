import Combine
import Foundation

class WCSignMessageViewModel: ObservableObject {
    struct Row: Identifiable {
        let title: String
        let value: String
        let copyable: Bool
        var id: String { title }
    }

    private let item: WCRequestItem
    private let manager: WCManager?

    let dAppName: String
    let dAppHost: String?
    let iconUrl: String?
    let rows: [Row]
    let message: String
    let cautions: [CautionNew]
    let isBlocked: Bool

    @Published private(set) var signing = false

    private let finishSubject = PassthroughSubject<Void, Never>()
    private let errorSubject = PassthroughSubject<String, Never>()
    private(set) var finished = false

    init(item: WCRequestItem) {
        self.item = item
        manager = Core.shared.walletConnect

        let request = item.request
        let payload = request?.payload
        dAppName = item.session.dAppName
        let peer = manager?.startedKit?.sessions.first { $0.topic == item.session.topic }?.peer
        dAppHost = peer.map { URLComponents(string: $0.url)?.host ?? $0.url }
        iconUrl = peer?.icons.last
        isBlocked = request?.isBlocked ?? true

        var rows = [Row]()
        if let evm = payload as? WCEvmSignMessagePayload, let typedData = evm.typedData {
            rows.append(Row(title: "wallet_connect.sign.request_type".localized, value: typedData.primaryType, copyable: false))
            if let name = typedData.domain.objectValue?["name"]?.stringValue {
                rows.append(Row(title: "wallet_connect.sign.domain".localized, value: name, copyable: false))
            }
            if let contract = evm.typedDataDomain?.verifyingContract {
                rows.append(Row(title: "wallet_connect.sign.contract".localized, value: contract.shortened, copyable: true))
            }
        } else if let from = payload?.from {
            rows.append(Row(title: "wallet_connect.sign.domain".localized, value: from.shortened, copyable: true))
        }
        if let payload, let type = manager?.chainSupportRegistry.support(namespace: payload.chainId.namespace)?.blockchainType(chain: payload.chainId) {
            rows.append(Row(title: "wallet_connect.sign.network".localized, value: WCBlockchainsView.name(type: type), copyable: false))
        }
        if let accountName = Core.shared.accountManager.activeAccount?.name {
            rows.append(Row(title: "wallet_connect.connect.wallet".localized, value: accountName, copyable: false))
        }
        self.rows = rows

        switch payload {
        case let evm as WCEvmSignMessagePayload: message = evm.readableMessage
        case let solana as WCSolanaSignMessagePayload: message = solana.readableMessage
        default: message = ""
        }

        switch request?.verdict {
        case let .caution(reason): cautions = [CautionNew(text: reason.text, type: .warning)]
        case let .block(reason): cautions = [CautionNew(text: reason.text, type: .error)]
        case .pass, nil: cautions = []
        }
    }

    var finishPublisher: AnyPublisher<Void, Never> { finishSubject.eraseToAnyPublisher() }
    var errorPublisher: AnyPublisher<String, Never> { errorSubject.eraseToAnyPublisher() }

    var signEnabled: Bool { !isBlocked && !signing }

    func sign() {
        guard let request = item.request, let handler = manager?.signMessageHandlerRegistry.handler(for: request.payload) else { return }
        signing = true

        Task { [weak self] in
            do {
                try await handler.sign(request: request)
                await self?.finish()
            } catch {
                await self?.fail(error)
            }
        }
    }

    func reject() {
        guard !finished, let kit = manager?.startedKit else { return }
        finished = true
        Task { [item] in
            try? await kit.reject(item: item)
        }
    }

    // a blocked request is answered with an error as soon as the screen goes away
    func rejectIfBlocked() {
        if isBlocked { reject() }
    }

    @MainActor private func finish() {
        signing = false
        finished = true
        finishSubject.send()
    }

    @MainActor private func fail(_ error: Error) {
        signing = false
        errorSubject.send(error.smartDescription)
    }
}
