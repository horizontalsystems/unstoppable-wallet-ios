import Foundation
import RxSwift

class UnspentOutputManager {
    private let disposeBag = DisposeBag()

    private let databaseManager: IDatabaseManager
    private let networkManager: INetworkManager
    private let updateSubject: PublishSubject<[UnspentOutput]>

    init(databaseManager: IDatabaseManager, networkManager: INetworkManager, updateSubject: PublishSubject<[UnspentOutput]>) {
        self.databaseManager = databaseManager
        self.networkManager = networkManager
        self.updateSubject = updateSubject
    }

    func refresh() {
        networkManager.getUnspentOutputs().subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] outputs in
            self?.databaseManager.truncateUnspentOutputs()
            self?.databaseManager.insert(unspentOutputs: outputs)
            self?.updateSubject.onNext(outputs)
        })
    }

}
