import Combine
import EventSource
import Foundation
import HdWalletKit
import HsExtensions
import StreamURLSessionTransport
import TonConnectAPI
import TonSwift
import TweetNacl

class TonConnectManager {
    private let apiClient: TonConnectAPI.Client
    private let storage: TonConnectStorage
    private let accountManager: AccountManager
    private var cancellables = Set<AnyCancellable>()

    @PostPublished private(set) var tonConnectApps = [TonConnectApp]()

    private var task: Task<Void, Error>?
    private let jsonDecoder = JSONDecoder()

    private let sendTransactionRequestSubject = PassthroughSubject<TonConnectSendTransactionRequest, Never>()

    init(storage: TonConnectStorage, accountManager: AccountManager) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(Int.max)
        configuration.timeoutIntervalForResource = TimeInterval(Int.max)

        apiClient = TonConnectAPI.Client(
            serverURL: URL(string: "https://bridge.unstoppable.money/bridge")!,
            transport: StreamURLSessionTransport(urlSessionConfiguration: configuration),
            middlewares: []
        )

        self.storage = storage
        self.accountManager = accountManager

        accountManager.accountDeletedPublisher
            .sink { [weak self] in self?.handleDeleted(account: $0) }
            .store(in: &cancellables)

        syncTonConnectApps()
    }

    private func handleDeleted(account: Account) {
        let apps = tonConnectApps.filter { $0.accountId == account.id }

        guard !apps.isEmpty else {
            return
        }

        Task { [weak self] in
            for app in apps {
                try await self?.disconnect(tonConnectApp: app)
            }
        }
    }

    private func syncTonConnectApps() {
        do {
            tonConnectApps = try storage.tonConnectApps()
        } catch {
            tonConnectApps = []
        }

        start()
    }

    public func start() {
        task?.cancel()

        // print("Start")

        guard !tonConnectApps.isEmpty else {
            return
        }

        // print("Apps: \(tonConnectApps.map { $0.manifest.name })")

        let task = Task { [storage, tonConnectApps] in
            let ids = tonConnectApps.map(\.keyPair.publicKey.hexString).joined(separator: ",")

            // print("IDS: \(ids)")

            let errorParser = EventSourceDecodableErrorParser<TonConnectError>()
            let stream = try await EventSource.eventSource({
                let response = try await self.apiClient.events(
                    query: .init(client_id: [ids], last_event_id: storage.lastEventId())
                )

                return try response.ok.body.text_event_hyphen_stream
            }, errorParser: errorParser)

            // print("Start listening....")

            for try await events in stream {
                handle(events: events)
            }

            // print("Stop listening....")

            guard !Task.isCancelled else { return }

            start()
        }

        self.task = task
    }

    private func handle(events: [EventSource.Event]) {
        // print("HANDLE: \(events)")
        guard let event = events.last(where: { $0.event == "message" }),
              let data = event.data?.data(using: .utf8),
              let tonConnectEvent = try? jsonDecoder.decode(TonConnectEvent.self, from: data)
        else {
            return
        }

        if let id = event.id {
            try? storage.save(lastEventId: id)
        }

        handleEvent(tonConnectEvent: tonConnectEvent)
    }

    private func handleEvent(tonConnectEvent: TonConnectEvent) {
        // print("HANDLE EVENT: \(tonConnectEvent)")
        guard let app = tonConnectApps.first(where: { $0.clientId == tonConnectEvent.from }) else {
            return
        }

        do {
            let sessionCrypto = try TonConnectSessionCrypto(privateKey: app.keyPair.privateKey)

            guard let senderPublicKey = Data(hex: app.clientId), let message = Data(base64Encoded: tonConnectEvent.message) else {
                return
            }

            let decryptedMessage = try sessionCrypto.decrypt(message: message, senderPublicKey: senderPublicKey)

            // print("DECRYPTED: \(String(data: decryptedMessage, encoding: .utf8) ?? "nil")")

            let request: TonConnect.AppRequest = try jsonDecoder.decode(
                TonConnect.AppRequest.self,
                from: decryptedMessage
            )

            // print("REQUEST: \(request)")

            switch request.method {
            case .sendTransaction:
                if let param = request.params.first {
                    sendTransactionRequestSubject.send(.init(id: request.id, param: param, app: app))
                }
            case .disconnect:
                try delete(tonConnectApp: app)
            }

        } catch {
            print("Log: Failed to handle ton connect event \(tonConnectEvent), error: \(error)")
        }
    }

    private func parseTonConnect(deeplink: String) throws -> TonConnectParameters {
        guard
            let url = URL(string: deeplink),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            components.scheme == .httpsScheme || components.scheme == .tcScheme
        else {
            throw ServiceError.incorrectUrl
        }
         
        return try TonConnectManager.parseParameters(queryItems: components.queryItems)
    }

    private func loadManifest(url: URL) async throws -> TonConnectManifest {
        let (data, _) = try await URLSession.shared.data(from: url)
        let jsonDecoder = JSONDecoder()
        return try jsonDecoder.decode(TonConnectManifest.self, from: data)
    }

    private func send(message: Encodable, clientId: String, sessionCrypto: TonConnectSessionCrypto) async throws {
        let encoded = try JSONEncoder().encode(message)

        guard let receiverPublicKey = Data(hex: clientId) else {
            throw ServiceError.incorrectClientId
        }

        let encrypted = try sessionCrypto.encrypt(message: encoded, receiverPublicKey: receiverPublicKey)

        let _ = try await apiClient.message(
            query: .init(client_id: sessionCrypto.sessionId, to: clientId, ttl: 300),
            body: .plainText(.init(stringLiteral: encrypted.base64EncodedString()))
        )
        
        // _ = try resp.ok.body.json
    }

    private func storeConnectedApp(account: Account, sessionCrypto: TonConnectSessionCrypto, parameters: TonConnectParameters, manifest: TonConnectManifest) throws {
        let tonConnectApp = TonConnectApp(accountId: account.id, clientId: parameters.clientId, manifest: manifest, keyPair: sessionCrypto.keyPair)
        try storage.save(tonConnectApp: tonConnectApp)
    }

    private func delete(tonConnectApp: TonConnectApp) throws {
        try storage.delete(tonConnectApp: tonConnectApp)

        syncTonConnectApps()
    }
}

extension TonConnectManager {
    var sendTransactionRequestPublisher: AnyPublisher<TonConnectSendTransactionRequest, Never> {
        sendTransactionRequestSubject.eraseToAnyPublisher()
    }

    func loadTonConnectConfiguration(parameters: TonConnectParameters) async throws -> TonConnectConfig {
        do {
            let manifest = try await loadManifest(url: parameters.requestPayload.manifestUrl)
            return TonConnectConfig(parameters: parameters, manifest: manifest)
        } catch {
            throw ServiceError.manifestLoadFailed
        }
    }

    func loadTonConnectConfiguration(deeplink: String) async throws -> TonConnectConfig {
        let parameters = try parseTonConnect(deeplink: deeplink)

        return try await loadTonConnectConfiguration(parameters: parameters)
    }

    func connect(account: Account, parameters: TonConnectParameters, manifest: TonConnectManifest) async throws {
        let (publicKey, secretKey) = try TonKitManager.keyPair(accountType: account.type)

        let message = try TonConnectResponseBuilder.buildConnectEventSuccesResponse(
            requestPayloadItems: parameters.requestPayload.items,
            contract: TonKitManager.contract(publicKey: publicKey),
            keyPair: KeyPair(publicKey: .init(data: publicKey), privateKey: .init(data: secretKey)),
            manifest: manifest
        )

        let sessionCrypto = try TonConnectSessionCrypto()

        try await send(message: message, clientId: parameters.clientId, sessionCrypto: sessionCrypto)
        try storeConnectedApp(account: account, sessionCrypto: sessionCrypto, parameters: parameters, manifest: manifest)

        syncTonConnectApps()
    }

    func disconnect(tonConnectApp: TonConnectApp) async throws {
        let sessionCrypto = try TonConnectSessionCrypto(privateKey: tonConnectApp.keyPair.privateKey)
        try await send(message: TonConnect.DisconnectEvent(), clientId: tonConnectApp.clientId, sessionCrypto: sessionCrypto)

        try delete(tonConnectApp: tonConnectApp)
    }

    func approve(request: TonConnectSendTransactionRequest, boc: String) async throws {
        let message = TonConnect.SendTransactionResponse.success(.init(result: boc, id: request.id))
        let sessionCrypto = try TonConnectSessionCrypto(privateKey: request.app.keyPair.privateKey)

        try await send(message: message, clientId: request.app.clientId, sessionCrypto: sessionCrypto)
    }

    func reject(request: TonConnectSendTransactionRequest) async throws {
        let message = TonConnect.SendTransactionResponse.error(.init(id: request.id, error: .init(code: .userDeclinedTransaction, message: "")))
        let sessionCrypto = try TonConnectSessionCrypto(privateKey: request.app.keyPair.privateKey)

        try await send(message: message, clientId: request.app.clientId, sessionCrypto: sessionCrypto)
    }
}

extension TonConnectManager {
    static func parseParameters(queryItems: [URLQueryItem]?) throws -> TonConnectParameters {
        guard let queryItems = queryItems,
              let versionValue = queryItems.first(where: { $0.name == .versionKey })?.value,
              let version = TonConnectParameters.Version(rawValue: versionValue),
              let clientId = queryItems.first(where: { $0.name == .clientIdKey })?.value,
              let requestPayloadValue = queryItems.first(where: { $0.name == .requestPayloadKey })?.value,
              let requestPayloadData = requestPayloadValue.data(using: .utf8),
              let requestPayload = try? JSONDecoder().decode(TonConnectRequestPayload.self, from: requestPayloadData)
          else {
              throw ServiceError.incorrectUrl
          }
        
        let returnDeepLink = queryItems.first(where: { $0.name == .returnDeepLink })?.value
        return TonConnectParameters(version: version, clientId: clientId, requestPayload: requestPayload, ret: returnDeepLink)
    }
}

extension TonConnectManager {
    enum ServiceError: Error {
        case incorrectUrl
        case manifestLoadFailed
        case incorrectClientId
    }

    struct TonConnectError: Swift.Error, Decodable {
        let statusCode: Int
        let message: String
    }

    struct TonConnectEvent: Decodable {
        let from: String
        let message: String
    }
}

private extension String {
    static let tcScheme = "tc"
    static let httpsScheme = "https"
    static let versionKey = "v"
    static let clientIdKey = "id"
    static let requestPayloadKey = "r"
    static let returnDeepLink = "ret"
}

struct TonConnectSendTransactionRequest {
    let id: String
    let param: SendTransactionParam
    let app: TonConnectApp
}
