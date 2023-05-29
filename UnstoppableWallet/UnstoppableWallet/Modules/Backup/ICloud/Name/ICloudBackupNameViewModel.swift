import Combine
import Foundation
import HsExtensions

class ICloudBackupNameViewModel {
    private var cancellables = Set<AnyCancellable>()

    private let service: ICloudBackupNameService
    @Published public var nameError: String?
    @Published public var nextAvailable: Bool = false

    init(service: ICloudBackupNameService) {
        self.service = service

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: ICloudBackupNameService.State) {
        switch state {
        case .failure(let error):
            nameError = error.localizedDescription
            nextAvailable = false
        case .success:
            nameError = nil
            nextAvailable = true
        }
    }

}

extension ICloudBackupNameViewModel {

    var initialName: String {
        service.initialName
    }

    var account: Account {
        service.account
    }

    var name: String? {
        guard case let .success(name) = service.state else {
            return nil
        }

        return name
    }

    func onChange(name: String?) {
        service.set(name: name ?? "")
    }

}

extension ICloudBackupNameService.NameError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .empty: return "backup.cloud.name.error.empty".localized
        case .alreadyExist: return "backup.cloud.name.error.already_exist".localized
        }
    }

}
