import Foundation
import RxSwift

enum PingManagerError: Error { case wrongUrl, responseFailure }

class PingManager: IPingManager {

    func serverAvailable(url: String, timeoutInterval: TimeInterval = 5.0) -> Observable<TimeInterval> {
        guard let url = URL(string: url) else { return Observable.error(PingManagerError.wrongUrl) }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval

        let date = Date()
        return Observable<TimeInterval>.create { observer in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    observer.onError(error)
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        observer.onNext(Date().timeIntervalSince(date))
                        observer.onCompleted()
                    } else {
                        observer.onError(PingManagerError.responseFailure)
                    }
                }
            }
            task.resume()

            return Disposables.create()
        }
    }

}
