import Foundation
import RxSwift
import RxRelay
import Alamofire
import HsToolKit

class FileDataStorage {
    private let queue: DispatchQueue = DispatchQueue(label: "io.horizontalsystems.unstoppable.file_storage.data", qos: .background)

    func read(directoryUrl: URL, filename: String) -> Single<Data> {
        let fileUrl = directoryUrl.appendingPathComponent(filename)

        return Single.create { [weak self] observer in
            self?.queue.async {
                do {
//                    print("Start reading file : \(fileUrl.path)")
                    let data = try Data(contentsOf: fileUrl)
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

//        print("DIRECTORY \(directoryUrl.path) exist? \(FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil))")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
//                print("Firectory created")
            } catch {
//                print("Error: \(error)")
                return .error(StorageError.cantCreateFile)
            }
        }


        let writeSingle = Single.create { [weak self] observer in
            self?.queue.async {
                do {
//                    print("Start writing file : \(fileUrl.path)")
//                    print("Try to write data: \(data.hs.hex)")

                    try data.write(to: fileUrl)
//                    print("Wrote data: \(data.hs.hex)")

                    let data2 = try Data(contentsOf: fileUrl)
//                    print("Data2 SUCCESS: \(data2.hs.hexString)")
                    observer(.success(()))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }

        return deleteFile(url: fileUrl).flatMap { writeSingle }
    }

    func deleteFile(url: URL?) -> Single<()> {
//        print("Try to delete file")
        guard let url,
              FileManager.default.fileExists(atPath: url.path) else {

//            print("Can't find file! no need to remove")
            return .just(())
        }

        return Single.create { [weak self] observer in
            self?.queue.async {
                do {
                    try FileManager.default.removeItem(atPath: url.path)
//                    print("File deleted!")
                    observer(.success(()))
                } catch {
//                    print("throw error: \(error)")
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