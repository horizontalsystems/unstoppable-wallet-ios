class BackupManualViewModel {
    private let service: BackupManualService

    init(service: BackupManualService) {
        self.service = service
    }
}

extension BackupManualViewModel {
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
