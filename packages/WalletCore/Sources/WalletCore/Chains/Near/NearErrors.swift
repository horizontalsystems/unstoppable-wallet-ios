import NearKit

extension NearKit.NoEndpointAvailable: ConvertibleError {
    var convertedError: Error {
        underlying?.isNoConnection == true ? AppError.noConnection : self
    }
}
