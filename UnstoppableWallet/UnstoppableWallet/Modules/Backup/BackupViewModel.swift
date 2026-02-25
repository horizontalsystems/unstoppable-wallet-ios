import Combine
import Foundation

class BackupViewModel: ObservableObject {
    private let cloudBackupManager = Core.shared.cloudBackupManager

    let type: BackupModule.BackupType
    let initialStep: BackupModule.Step

    @Published var destination: BackupModule.Destination?
    @Published var selectedAccountIds: Set<String>
    @Published var processing: Bool = false
    @Published private(set) var cloudAvailable: Bool

    private(set) var name: String = ""
    private(set) var password: String = ""

    private var cancellables = Set<AnyCancellable>()

    private let dismissSubject = PassthroughSubject<Void, Never>()
    var dismissPublisher: AnyPublisher<Void, Never> {
        dismissSubject.eraseToAnyPublisher()
    }

    private let shareSubject = PassthroughSubject<URL, Never>()
    var sharePublisher: AnyPublisher<URL, Never> {
        shareSubject.eraseToAnyPublisher()
    }

    private let errorSubject = PassthroughSubject<String, Never>()
    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    init(type: BackupModule.BackupType, destination: BackupModule.Destination? = nil) {
        self.type = type
        self.destination = destination
        cloudAvailable = cloudBackupManager.iCloudUrl != nil

        initialStep = BackupViewModel.initialStep(type: type, destination: destination)

        switch type {
        case let .wallet(accountId):
            selectedAccountIds = [accountId]
        case let .app(accountIds):
            selectedAccountIds = accountIds
        }

        cloudBackupManager.$state
            .sink { [weak self] state in
                switch state {
                case .error:
                    self?.cloudAvailable = false
                default:
                    self?.cloudAvailable = true
                }
            }
            .store(in: &cancellables)
    }

    var currentBackupType: BackupModule.BackupType {
        switch type {
        case .wallet:
            return type
        case .app:
            return .app(selectedAccountIds)
        }
    }

    func setDestination(_ destination: BackupModule.Destination) {
        self.destination = destination
    }

    func setSelectedAccountIds(_ ids: Set<String>) {
        selectedAccountIds = ids
    }

    func setName(_ name: String) {
        self.name = name
    }

    @MainActor
    func set(password: String) {
        self.password = password
    }

    @MainActor
    func set(processing: Bool) {
        self.processing = processing
    }

    func save() async throws {
        guard let destination else { return }

        let service = BackupServiceFactory.create(destination: destination)
        let result = try await service.save(type: currentBackupType, name: name, password: password)

        await MainActor.run {
            switch result {
            case .saved:
                HudHelper.instance.show(banner: .savedToCloud)
                dismissSubject.send()
            case let .share(url):
                shareSubject.send(url)
            }
        }
    }

    func handleSuccessShared() {
        HudHelper.instance.show(banner: .done)
        dismissSubject.send()
    }

    func handleShareError(_ error: Error) {
        errorSubject.send(error.localizedDescription)
    }

    func cancel() {
        dismissSubject.send()
    }

    @MainActor
    private func handleSuccess(result: BackupModule.BackupResult) {
        processing = false

        switch result {
        case .saved:
            HudHelper.instance.show(banner: .savedToCloud)
            dismissSubject.send()
        case let .share(url):
            shareSubject.send(url)
        }
    }

    @MainActor
    private func handleError(_ error: Error) {
        processing = false
        errorSubject.send(error.localizedDescription)
    }

    private static func initialStep(type: BackupModule.BackupType, destination: BackupModule.Destination?) -> BackupModule.Step {
        if destination == nil {
            return .selectDestination
        }

        switch type {
        case .app:
            return .selectContent
        case .wallet:
            return .disclaimer
        }
    }
}
