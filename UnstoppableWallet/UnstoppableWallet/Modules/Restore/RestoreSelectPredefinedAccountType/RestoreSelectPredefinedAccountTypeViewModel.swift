class RestoreSelectPredefinedAccountTypeViewModel {
    private let service: RestoreSelectPredefinedAccountTypeService

    init(service: RestoreSelectPredefinedAccountTypeService) {
        self.service = service
    }

    var viewItems: [ViewItem] {
        service.predefinedAccountTypes.map { type in
            ViewItem(predefinedAccountType: type, title: type.title, coinCodes: type.coinCodes)
        }
    }

}

extension RestoreSelectPredefinedAccountTypeViewModel {

    struct ViewItem {
        let predefinedAccountType: PredefinedAccountType
        let title: String
        let coinCodes: String
    }

}
