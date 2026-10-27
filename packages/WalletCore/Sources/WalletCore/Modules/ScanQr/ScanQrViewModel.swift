import Combine
import PhotosUI
import SwiftUI

public final class ScanQrViewModel: ObservableObject {
    private let cameraManager = QrCameraManager()
    public private(set) var didFetch: ((String) -> Void)?
    private let resultSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var isActive = false // main thread only

    @Published public var cameraPermissionDenied = false
    @Published public var cameraUnsupported = false
    @Published public var pickerItem: PhotosPickerItem?

    public var session: AVCaptureSession {
        cameraManager.session
    }

    public var resultPublisher: AnyPublisher<String, Never> {
        resultSubject.eraseToAnyPublisher()
    }

    public init(didFetch: ((String) -> Void)?) {
        self.didFetch = didFetch

        cameraManager.scannedPublisher
            .first()
            .sink { [weak self] value in
                self?.handleResult(value)
            }
            .store(in: &cancellables)

        cameraManager.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.cameraUnsupported = true
            }
            .store(in: &cancellables)

        cameraManager.configuredPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.cameraUnsupported = false
            }
            .store(in: &cancellables)

        $pickerItem
            .compactMap { $0 }
            .sink { [weak self] item in
                self?.loadImage(from: item)
            }
            .store(in: &cancellables)
    }

    public func requestCameraAccess() {
        isActive = true

        PermissionsHelper.performWithCameraPermission { [weak self] granted in
            DispatchQueue.main.async { [weak self] in
                guard let self, isActive else { return }

                if granted {
                    cameraManager.configure()
                    cameraManager.start()
                } else {
                    cameraPermissionDenied = true
                }
            }
        }
    }

    public func stopSession() {
        isActive = false
        cameraManager.stop()
    }

    public func onPaste() {
        handleResult(UIPasteboard.general.string ?? "")
    }

    private func handleResult(_ string: String) {
        isActive = false
        cameraManager.stop()
        resultSubject.send(string)
    }

    private func loadImage(from item: PhotosPickerItem) {
        Task { @MainActor [weak self] in
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let result = QrImageScanner.scan(image: image)
            else {
                self?.pickerItem = nil
                HudHelper.instance.show(banner: .error(string: "scan_qr.gallery.no_qr".localized))
                return
            }

            self?.handleResult(result)
        }
    }
}
