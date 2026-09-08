//
//  AttachmentCameraPickerView.swift
//  TestOnboardingChat
//

import AVFoundation
import SwiftUI
import UIKit

struct AttachmentCameraPickerView: View {
    @Bindable var viewModel: InputBarViewModel

    @State private var cameraStatus: AVAuthorizationStatus

    init(viewModel: InputBarViewModel) {
        self.viewModel = viewModel
        _cameraStatus = State(
            initialValue: AVCaptureDevice.authorizationStatus(for: .video)
        )
    }

    var body: some View {
        Group {
            if cameraStatus == .denied || cameraStatus == .restricted {
                CameraAccessDeniedPromptView()
            } else {
                CameraOpenPromptView {
                    openCamera()
                }
                .fullScreenCover(isPresented: $viewModel.cameraPickerShown) {
                    CameraImagePickerView(
                        isPresented: $viewModel.cameraPickerShown,
                        gallerySupportedTypes: viewModel.config.gallerySupportedTypes,
                        onAssetPicked: { viewModel.cameraAssetAdded($0) }
                    )
                    .ignoresSafeArea()
                }
                .onLoad {
                    openCamera()
                }
            }
        }
    }

    private func openCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            viewModel.cameraPickerShown = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        viewModel.cameraPickerShown = true
                    } else {
                        cameraStatus = .denied
                    }
                }
            }
        default:
            cameraStatus = status
        }
    }
}

struct CameraOpenPromptView: View {
    var onTap: () -> Void

    var body: some View {
        AttachmentPickerPromptView(
            image: Image(systemName: "camera.fill"),
            description: "Take a photo or video to attach to your message.",
            buttonText: "Open Camera",
            onTap: onTap
        )
    }
}

struct CameraAccessDeniedPromptView: View {
    var body: some View {
        AttachmentPickerPromptView(
            image: Image(systemName: "camera.fill"),
            description: "Allow camera access in Settings to take photos and videos.",
            buttonText: "Open Settings",
            onTap: { openSettings() }
        )
    }
}

struct CameraImagePickerView: View {
    @Binding var isPresented: Bool
    var gallerySupportedTypes: GallerySupportedTypes
    var onAssetPicked: (AddedMediaAsset) -> Void

    var body: some View {
        AttachmentImagePickerView(
            isPresented: $isPresented,
            sourceType: .camera,
            gallerySupportedTypes: gallerySupportedTypes,
            onAssetPicked: onAssetPicked
        )
    }
}

struct AttachmentImagePickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    let gallerySupportedTypes: GallerySupportedTypes
    var onAssetPicked: (AddedMediaAsset) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = InputBarCameraImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        }
        switch gallerySupportedTypes {
        case .images:
            picker.mediaTypes = ["public.image"]
        case .videos:
            picker.mediaTypes = ["public.movie"]
        case .imagesAndVideo:
            picker.mediaTypes = ["public.image", "public.movie"]
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> ImagePickerCoordinator {
        ImagePickerCoordinator(parent: self)
    }
}

private final class InputBarCameraImagePickerController: UIImagePickerController {
    override func viewDidLoad() {
        super.viewDidLoad()
        accessibilityLabel = ""
        view.accessibilityLabel = ""
    }
}

final class ImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: AttachmentImagePickerView

    init(parent: AttachmentImagePickerView) {
        self.parent = parent
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let uiImage = info[.originalImage] as? UIImage,
           let imageURL = try? uiImage.saveAsJpgToTemporaryUrl() {
            parent.onAssetPicked(
                AddedMediaAsset(
                    url: imageURL,
                    type: .image,
                    image: uiImage
                )
            )
        } else if let videoURL = info[.mediaURL] as? URL {
            let avAsset = AVURLAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: avAsset)
            generator.appliesPreferredTrackTransform = true
            if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
                let thumbnail = UIImage(cgImage: cgImage)
                let duration = CMTimeGetSeconds(avAsset.duration)
                parent.onAssetPicked(
                    AddedMediaAsset(
                        url: videoURL,
                        type: .video,
                        image: thumbnail,
                        duration: duration.isFinite ? duration : nil
                    )
                )
            }
        }
        parent.isPresented = false
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        parent.isPresented = false
        picker.dismiss(animated: true)
    }
}
