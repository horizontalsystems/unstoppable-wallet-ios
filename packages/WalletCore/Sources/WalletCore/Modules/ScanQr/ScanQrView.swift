import PhotosUI
import SwiftUI

public struct ScanQrView: View {
    @StateObject private var viewModel: ScanQrViewModel
    @Binding private var isPresented: Bool

    private let reportAfterDismiss: Bool
    private let options: ScanQrModule.Options

    public init(reportAfterDismiss: Bool = false, options: ScanQrModule.Options = [.paste, .picker], isPresented: Binding<Bool>, didFetch: ((String) -> Void)?) {
        self.reportAfterDismiss = reportAfterDismiss
        self.options = options
        _isPresented = isPresented
        _viewModel = StateObject(wrappedValue: ScanQrViewModel(didFetch: didFetch))
    }

    public var body: some View {
        ThemeNavigationStack {
            ZStack {
                QrCameraPreview(session: viewModel.session)
                    .ignoresSafeArea()

                QrScannerOverlayView(sideMargin: .margin24)
                    .ignoresSafeArea()

                if viewModel.cameraPermissionDenied {
                    permissionDeniedView
                } else if viewModel.cameraUnsupported {
                    unsupportedView
                }

                VStack {
                    Spacer()
                    buttons
                }
                .padding(.horizontal, .margin24)
                .padding(.bottom, .margin24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("balance.scan".localized)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
            .onAppear {
                viewModel.requestCameraAccess()
            }
            .onDisappear {
                viewModel.stopSession()
            }
            .onReceive(viewModel.resultPublisher) { string in
                if reportAfterDismiss {
                    isPresented = false
                    DispatchQueue.main.async {
                        viewModel.didFetch?(string)
                    }
                } else {
                    viewModel.didFetch?(string)
                    isPresented = false
                }
            }
        }
    }

    @ViewBuilder private var buttons: some View {
        if options.contains(.picker) || options.contains(.paste) {
            HStack(spacing: .margin16) {
                if options.contains(.picker) {
                    PhotosPicker(
                        selection: $viewModel.pickerItem,
                        matching: .images
                    ) {
                        HStack(spacing: .margin8) {
                            Image("gallery").renderingMode(.template)
                            Text("button.gallery".localized)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .gray))
                }

                if options.contains(.paste) {
                    Button(action: { viewModel.onPaste() }) {
                        HStack(spacing: .margin8) {
                            Image("copy").renderingMode(.template)
                            Text("button.paste".localized)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                }
            }
        }
    }

    @ViewBuilder private var permissionDeniedView: some View {
        VStack(spacing: .margin32) {
            Text("access_camera.message".localized)
                .themeSubhead2(color: .themeGray, alignment: .center)

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("access_camera.settings".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .transparent))
        }
        .padding(.horizontal, .margin32)
    }

    @ViewBuilder private var unsupportedView: some View {
        ThemeText("access_camera.not_supported".localized, style: .subheadR, colorStyle: .secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, .margin32)
    }
}
