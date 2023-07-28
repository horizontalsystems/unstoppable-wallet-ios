import Foundation
import RxSwift
import RxRelay
import Alamofire
import HsToolKit

class FileStorage {
    private let logger: Logger?

    init(logger: Logger? = nil) {
        self.logger = logger
    }

    func prepareUbiquitousItem(url: URL, filename: String) throws {
        let fileUrl = url.appendingPathComponent(filename)

        try FileManager.default.startDownloadingUbiquitousItem(at: fileUrl)
    }

    func fileList(url: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: url.path)
    }

    func read(directoryUrl: URL, filename: String) throws -> Data {
        let fileUrl = directoryUrl.appendingPathComponent(filename)

        logger?.debug("=> FDStorage =>: Start reading file : \(fileUrl.path)")
        let data = try FileManager.default.contentsOfFile(coordinatingAccessAt: fileUrl)

        return data
    }

    func write(directoryUrl: URL, filename: String, data: Data) throws {
        let fileUrl = directoryUrl.appendingPathComponent(filename)

        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try FileManager.default.createDirectory(coordinatingAccessAt: directoryUrl, withIntermediateDirectories: false)
        }

        try FileManager.default.write(data, coordinatingAccessTo: fileUrl)
        logger?.debug("=> FDStorage =>: Finish saving file : \(fileUrl.path)")
    }

    func deleteFile(url: URL?) throws {
        logger?.debug("=> FDStorage =>: Try to delete file")
        guard let url,
              (try? FileManager.default.fileExists(coordinatingAccessAt: url).exists) ?? false else {

            logger?.debug("=> FDStorage =>: Can't find file! no need to remove")
            return
        }

        try FileManager.default.removeItem(coordinatingAccessAt: url)
        logger?.debug("=> FDStorage =>: File deleted!")
    }

}

extension FileStorage {

    enum StorageError: Error {
        case cantCreateFile
    }

}
