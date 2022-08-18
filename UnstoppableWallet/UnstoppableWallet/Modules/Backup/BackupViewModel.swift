class BackupViewModel {
    private let service: BackupService

    init(service: BackupService) {
        self.service = service
    }

}

extension BackupViewModel {

    var account: Account {
        service.account
    }

    var words: [String] {
        service.words
    }

    var passphrase: String? {
        service.salt.isEmpty ? nil : service.salt
    }

}
