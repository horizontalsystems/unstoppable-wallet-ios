class RestoreSelectPredefinedAccountTypeService {
    let predefinedAccountTypes: [PredefinedAccountType]

    init(predefinedAccountTypeManager: IPredefinedAccountTypeManager) {
        predefinedAccountTypes = predefinedAccountTypeManager.allTypes
    }

}
