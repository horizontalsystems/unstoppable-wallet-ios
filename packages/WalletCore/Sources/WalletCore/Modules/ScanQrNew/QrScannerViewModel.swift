import Combine
import PhotosUI
import SwiftUI

class ScanQrViewModelNew: ObservableObject {
    private let cameraManager = QrCameraManagerNew()
    private(set) var didFetch: ((String) -> Void)?
    private let resultSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    @Published var cameraPermissionDenied = false
    @Published var pickerItem: PhotosPickerItem?

    var session: AVCaptureSession {
        cameraManager.session
    }

    var resultPublisher: AnyPublisher<String, Never> {
        resultSubject.eraseToAnyPublisher()
    }

    init(didFetch: ((String) -> Void)?) {
        self.didFetch = didFetch

        cameraManager.scannedPublisher
            .first()
            .sink { [weak self] value in
                self?.handleResult(value)
            }
            .store(in: &cancellables)

        cameraManager.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { error in
                HudHelper.instance.show(banner: .error(string: error.smartDescription))
            }
            .store(in: &cancellables)

        $pickerItem
            .compactMap { $0 }
            .sink { [weak self] item in
                self?.loadImage(from: item)
            }
            .store(in: &cancellables)
    }

    func requestCameraAccess() {
        PermissionsHelper.performWithCameraPermission { [weak self] granted in
            if granted {
                self?.cameraManager.configure()
                self?.cameraManager.start()
            } else {
                DispatchQueue.main.async {
                    self?.cameraPermissionDenied = true
                }
            }
        }
    }

    func startSession() {
        cameraManager.start()
    }

    func stopSession() {
        cameraManager.stop()
    }

    func onPaste() {
        handleResult(UIPasteboard.general.string ?? "")
    }

    private func handleResult(_ string: String) {
        cameraManager.stop()
        resultSubject.send(string)
    }

    private func loadImage(from item: PhotosPickerItem) {
        Task { @MainActor [weak self] in
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let result = QrImageScannerNew.scan(image: image)
            else {
                self?.pickerItem = nil
                HudHelper.instance.show(banner: .error(string: "scan_qr.gallery.no_qr".localized))
                return
            }

            self?.handleResult(result)
        }
    }
}
