import Foundation
import RxSwift
import RxRelay
import Alamofire
import HsToolKit

class FileStorageService {
    private let queue: DispatchQueue

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            print("New State = \(state)")
            stateRelay.accept(state)
        }
    }
    private let directoryUrl: URL? // = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    private let filename: String

    private var fileUrl: URL? {
        guard let directoryUrl else {
            state = .failed(StorageError.nilDirectory)
            return nil
        }

        let fileUrl = directoryUrl.appendingPathComponent(filename)
        if !FileManager.default.fileExists(atPath: fileUrl.path, isDirectory: nil) {
            state = .failed(StorageError.notAvailable)
            return nil
        }
        return fileUrl
    }

    init(directoryUrl: URL?, filename: String) {
        self.directoryUrl = directoryUrl
        self.filename = filename

        queue = DispatchQueue(label: "io.FileStorage." + filename, qos: .background)
    }

    func read() {
        print("Start reading file")
        guard let url = fileUrl else {
            return
        }

        state = .reading

        queue.async { [weak self] in
            do {
                let data = try Data(contentsOf: url)
                self?.state = .completed(data)
            } catch {
                self?.state = .failed(error)
            }
        }
    }

    func write(data: Data) {
        print("Try to write data: \(data.hs.hex)")
        guard let url = fileUrl else {
            print("no file url")
            return
        }

        state = .writing

        queue.async { [weak self] in
            do {
                try data.write(to: url)
                self?.state = .completed(data)
            } catch {
                self?.state = .failed(error)
            }
        }
    }

    func deleteFile() {
        guard let url = fileUrl else {
            return
        }
        guard !FileManager.default.isDeletableFile(atPath: url.path) else {
            state = .failed(StorageError.notAvailable)
            return
        }

        do {
            try FileManager.default.removeItem(atPath: url.path)
        } catch {
            state = .failed(error)
        }
    }

}

extension FileStorageService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func prepare() {
        print("starting prepare storage for: \(directoryUrl?.path ?? "N/A") + \(filename) ")
        guard let directoryUrl else {
            print("state = failed! Finish")
            state = .failed(StorageError.nilDirectory)
            return
        }

        let result = Self.checkAndCreateNew(directory: directoryUrl, filename: filename)
        switch result {
        case .success(let newCreated):
            if newCreated {
                state = .completed(Data())
            }  else {
                read()
            }
        case .failure(let error): state = .failed(error)
        }
    }

}

extension FileStorageService {

    static func checkAndCreateNew(directory: URL, filename: String) -> Result<Bool, Error> {
        // if no directory try to create and use empty data for content
        if !FileManager.default.fileExists(atPath: directory.path, isDirectory: nil) {
            do {
                print("Directory not exist. Try to create!")
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

                let fileUrl = directory.appendingPathComponent(filename)
                return checkAndCreateNew(file: fileUrl)
            } catch {
                print("Directory cant be created \(error)!")
                return .failure(error)
            }
        }

        let fileUrl = directory.appendingPathComponent(filename)
        print("FileUrl = \(fileUrl.path)")
        return checkAndCreateNew(file: fileUrl)
    }

    static private func checkAndCreateNew(file: URL) -> Result<Bool, Error> {
        print("Check file exist!")
        if !FileManager.default.fileExists(atPath: file.path) {
            print("File not exist - try to create!")
            let success = FileManager.default.createFile(atPath: file.path, contents: nil)
            if success {
                print("File created!")
                return .success(true)
            } else {
                print("File cant be created!")
                return .failure(StorageError.cantCreateFile)
            }
        }
        return .success(false)
    }

}

extension FileStorageService {

    enum State {
        case idle
        case reading
        case writing
        case completed(Data)
        case failed(Error)

        var isProcessing: Bool {
            switch self {
            case .reading, .writing: return true
            default: return false
            }
        }

        var data: Data? {
            switch self {
            case .completed(let data): return data
            default: return nil
            }
        }

    }

    enum StorageError: Error {
        case nilDirectory
        case cantCreateFile
        case notInitialized
        case notAvailable
    }

}
