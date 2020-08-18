import Foundation

class MainShowService {
    private let localStorage: ILocalStorage

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

    func setMainShownOnce() {
        DispatchQueue.global(qos: .background).async {
            self.localStorage.mainShownOnce = true
        }
    }

}
