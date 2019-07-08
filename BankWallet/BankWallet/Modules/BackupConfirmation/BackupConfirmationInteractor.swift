import Foundation

class BackupConfirmationInteractor {
    private let randomManager: IRandomManager

    init(randomManager: IRandomManager) {
        self.randomManager = randomManager
    }

}

extension BackupConfirmationInteractor: IBackupConfirmationInteractor {

    func fetchConfirmationIndexes(max: Int, count: Int) -> [Int] {
        return randomManager.getRandomIndexes(max: max, count: count)
    }

}
