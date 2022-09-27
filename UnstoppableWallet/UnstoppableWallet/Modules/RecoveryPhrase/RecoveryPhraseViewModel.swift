class RecoveryPhraseViewModel {
    private let service: RecoveryPhraseService

    init(service: RecoveryPhraseService) {
        self.service = service
    }

}

extension RecoveryPhraseViewModel {

    var words: [String] {
        service.words
    }

    var passphrase: String? {
        service.salt.isEmpty ? nil : service.salt
    }

}
