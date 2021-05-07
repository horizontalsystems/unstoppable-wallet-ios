import RxSwift

class AppVersionStorage {
    private let storage: IAppVersionRecordStorage

    init(storage: IAppVersionRecordStorage) {
        self.storage = storage
    }

}

extension AppVersionStorage: IAppVersionStorage {

    var appVersions: [AppVersion] {
        storage.appVersionRecords.compactMap {
            AppVersion(version: $0.version, build: $0.build, date: $0.date)
        }
    }

    func save(appVersions: [AppVersion]) {
        let records = appVersions.map {
            AppVersionRecord(version: $0.version, build: $0.build, date: $0.date)
        }
        storage.save(appVersionRecords: records)
    }

}
