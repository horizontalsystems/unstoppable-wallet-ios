import Combine

class RestoreBinanceViewModel {
    private let service: RestoreBinanceService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var connectEnabled = false
    @Published private(set) var connectVisible = true
    @Published private(set) var connectingVisible = false

    private let valuesSubject = PassthroughSubject<(String, String), Never>()
    private let errorSubject = PassthroughSubject<String, Never>()
    private let successSubject = PassthroughSubject<Void, Never>()

    init(service: RestoreBinanceService) {
        self.service = service

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: RestoreBinanceService.State) {
        switch state {
        case .notReady:
            connectEnabled = false
            connectVisible = true
            connectingVisible = false
        case .idle(let error):
            connectEnabled = true
            connectVisible = true
            connectingVisible = false

            if error != nil {
                errorSubject.send("restore.binance.failed_to_connect".localized)
            }
        case .connecting:
            connectVisible = false
            connectingVisible = true
        case .connected:
            successSubject.send()
        }
    }

}

extension RestoreBinanceViewModel {

    var valuesPublisher: AnyPublisher<(String, String), Never> {
        valuesSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var successPublisher: AnyPublisher<Void, Never> {
        successSubject.eraseToAnyPublisher()
    }

    func onChange(apiKey: String) {
        service.apiKey = apiKey
    }

    func onChange(secretKey: String) {
        service.secretKey = secretKey
    }

    func onFetch(qrCodeString: String) {
        do {
            let qrCode = try service.parse(qrCodeString: qrCodeString)
            service.apiKey = qrCode.apiKey
            service.secretKey = qrCode.secretKey

            valuesSubject.send((qrCode.apiKey, qrCode.secretKey))
        } catch {
            errorSubject.send("restore.binance.invalid_qr_code".localized)
        }
    }

    func onTapConnect() {
        service.connect()
    }

}
