import Foundation
import RxSwift
import RxRelay
import Alamofire
import HsToolKit

class FileDataStorage {
    private let queue: DispatchQueue = DispatchQueue(label: "\(AppConfig.label).file_storage.data", qos: .background)

    private let logger: Logger?

    init(logger: Logger? = nil) {
        self.logger = logger
    }

    func prepareUbiquitousItem(url: URL, filename: String) throws {
        let fileUrl = url.appendingPathComponent(filename)

        try FileManager.default.startDownloadingUbiquitousItem(at: fileUrl)
    }

    func read(directoryUrl: URL, filename: String) -> Single<Data> {
        let fileUrl = directoryUrl.appendingPathComponent(filename)

        return Single.create { [weak self] observer in
            self?.queue.async {
                do {
                    self?.logger?.debug("=> FDStorage =>: Start reading file : \(fileUrl.path)")
                    let data = try FileManager.default.contentsOfFile(coordinatingAccessAt: fileUrl)
                    observer(.success(data))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func write(directoryUrl: URL, filename: String, data: Data) -> Single<()> {
        let fileUrl = directoryUrl.appendingPathComponent(filename)

        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(coordinatingAccessAt: directoryUrl, withIntermediateDirectories: false)
            } catch {
                return .error(StorageError.cantCreateFile)
            }
        }


        let writeSingle = Single.create { [weak self] observer in
            self?.queue.async {
                do {
                    try FileManager.default.write(data, coordinatingAccessTo: fileUrl)
                    observer(.success(()))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }

        return writeSingle
    }

    func deleteFile(url: URL?) -> Single<()> {
        logger?.debug("=> FDStorage =>: Try to delete file")
        guard let url,
              (try? FileManager.default.fileExists(coordinatingAccessAt: url).exists) ?? false else {

            logger?.debug("=> FDStorage =>: Can't find file! no need to remove")
            return .just(())
        }

        return Single.create { [weak self] observer in
            self?.queue.async {
                do {
                    try FileManager.default.removeItem(coordinatingAccessAt: url)
                    self?.logger?.debug("=> FDStorage =>: File deleted!")
                    observer(.success(()))
                } catch {
                    self?.logger?.debug("=> FDStorage =>: throw error: \(error)")
                    observer(.error(error))
                }
            }

            return Disposables.create()
        }
    }

}

extension FileDataStorage {

    enum StorageError: Error {
        case cantCreateFile
        case cantDeleteFile
    }

}
