import Foundation
import Combine
import RxSwift
import ObjectMapper
import Alamofire
import HsToolKit

extension NetworkManager {

    public func single<Mapper: IApiMapper>(request: DataRequest, mapper: Mapper, sync: Bool = false, postDelay: TimeInterval? = nil) -> Single<Mapper.T> {
        Single<Mapper.T>.create { [weak self] observer in
            guard let manager = self else {
                observer(.error(NetworkManager.RequestError.disposed))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let json = try await manager.fetchJson(request: request)
                    let result = try mapper.map(statusCode: 200, data: json)
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    public func single<Mapper: IApiMapper>(url: URLConvertible, method: HTTPMethod, parameters: Parameters, mapper: Mapper, encoding: ParameterEncoding = URLEncoding.default,
                                           headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil) -> Single<Mapper.T> {
        Single<Mapper.T>.create { [weak self] observer in
            guard let manager = self else {
                observer(.error(NetworkManager.RequestError.disposed))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let json = try await manager.fetchJson(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor, responseCacherBehavior: responseCacherBehavior)
                    let result = try mapper.map(statusCode: 200, data: json)
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    public func single(request: DataRequest, sync: Bool = false, postDelay: TimeInterval? = nil) -> Single<Data> {
        Single<Data>.create { [weak self] observer in
            guard let manager = self else {
                observer(.error(NetworkManager.RequestError.disposed))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let data = try await manager.fetchData(request: request)
                    observer(.success(data))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    public func single<T: ImmutableMappable>(request: DataRequest, sync: Bool = false, postDelay: TimeInterval = 0, context: MapContext? = nil) -> Single<T> {
        Single<T>.create { [weak self] observer in
            guard let manager = self else {
                observer(.error(NetworkManager.RequestError.disposed))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let json = try await manager.fetchJson(request: request)
                    let result = try T(JSONObject: json, context: context)
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    public func single<T: ImmutableMappable>(request: DataRequest, context: MapContext? = nil) -> Single<[T]> {
        Single<[T]>.create { [weak self] observer in
            guard let manager = self else {
                observer(.error(NetworkManager.RequestError.disposed))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let json = try await manager.fetchJson(request: request)
                    let result = try Mapper<T>(context: context).mapArray(JSONObject: json)
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    public func single<T: ImmutableMappable>(url: URLConvertible, method: HTTPMethod, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil, context: MapContext? = nil) -> Single<T> {
        Single<T>.create { [weak self] observer in
            guard let manager = self else {
                observer(.error(NetworkManager.RequestError.disposed))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result: T = try await manager.fetch(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor, responseCacherBehavior: responseCacherBehavior, context: context)
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    public func single<T: ImmutableMappable>(url: URLConvertible, method: HTTPMethod, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil, context: MapContext? = nil) -> Single<[T]> {
        Single<[T]>.create { [weak self] observer in
            guard let manager = self else {
                observer(.error(NetworkManager.RequestError.disposed))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result: [T] = try await manager.fetch(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor, responseCacherBehavior: responseCacherBehavior, context: context)
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    public func single<T: ImmutableMappable>(url: URLConvertible, method: HTTPMethod, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil, context: MapContext? = nil) -> Single<[String: T]> {
        Single<[String: T]>.create { [weak self] observer in
            guard let manager = self else {
                observer(.error(NetworkManager.RequestError.disposed))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result: [String: T] = try await manager.fetch(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor, responseCacherBehavior: responseCacherBehavior, context: context)
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    public enum RequestError: Error {
        case invalidResponse(statusCode: Int, data: Any?)
        case noResponse(reason: String?)
        case disposed
    }

}

public protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilityObservable: Observable<Bool> { get }
    var connectionTypeUpdatedObservable: Observable<Void> { get }
}

extension ReachabilityManager: IReachabilityManager {

    public var reachabilityObservable: Observable<Bool> {
        $isReachable.asObservable()
    }

    public var connectionTypeUpdatedObservable: Observable<Void> {
        connectionTypeChangedPublisher.asObservable()
    }

}

extension BackgroundModeObserver {

    public var foregroundFromExpiredBackgroundObservable: Observable<Void> {
        foregroundFromExpiredBackgroundPublisher.asObservable()
    }

}

public protocol IApiMapper {
    associatedtype T
    func map(statusCode: Int, data: Any?) throws -> T
}

public class SerialNetworkManager {
    private let networkManager: NetworkManager

    public init(requestInterval: TimeInterval, logger: Logger) {
        networkManager = NetworkManager(interRequestInterval: requestInterval, logger: logger)
    }

    public func single<Mapper: IApiMapper>(url: URLConvertible, method: HTTPMethod, parameters: Parameters, mapper: Mapper, encoding: ParameterEncoding = URLEncoding.default,
                                           headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil) -> Single<Mapper.T> {
        Single<Mapper.T>.create { [weak self] observer in
            guard let manager = self?.networkManager else {
                observer(.error(NetworkManager.RequestError.disposed))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let json = try await manager.fetchJson(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor, responseCacherBehavior: responseCacherBehavior)
                    let result = try mapper.map(statusCode: 200, data: json)
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

}
