//
//  InputBarViewModel.swift
//  TestOnboardingChat
//

import AVFoundation
import CoreGraphics
import Observation
import Photos
import SwiftUI
import UniformTypeIdentifiers

@Observable
@MainActor
final class InputBarViewModel: ChatInputBarController {
    var pendingAssets: [InputBarAsset] = []
    var pendingVoiceRecordings: [InputBarVoiceRecording] = []
    var pendingLocation: InputBarLocation?
    var pickerOverlay: PickerOverlayState = .hidden
    var keyboardHeight: CGFloat = 0
    var popupHeight: CGFloat = 350
    var recordingState: VoiceRecordingState = .initial
    var recordingGestureLocation: CGPoint = .zero {
        didSet {
            guard recordingState.isRecording else { return }
            if recordingGestureLocation.y < VoiceRecordingConstants.lockMaxDistance {
                recordingState = .locked
                recordingGestureLocation = .zero
            } else if recordingGestureLocation.x < VoiceRecordingConstants.cancelMaxDistance {
                audioRecordingInfo = .initial
                recordingState = .initial
                recordingGestureLocation = .zero
                voiceRecordingService.cancelRecording()
            }
        }
    }
    var audioRecordingInfo = AudioRecordingInfo.initial
    var pendingAudioRecording: InputBarVoiceRecording?
    var attachmentSizeExceeded = false
    var photoLibraryAssets: PHFetchResult<PHAsset>?
    var cameraPickerShown = false
    var filePickerShown = false
    var recordingSnackBarText: String?
    var isLocationSheetPresented = false

    let config: InputBarFeatureConfig
    let locationPickerViewModel = LocationPickerViewModel()
    let voiceRecordingService = VoiceRecordingService()
    let voicePlayback = VoiceRecordingPlaybackService()

    init(config: InputBarFeatureConfig) {
        self.config = config
        locationPickerViewModel.onRequestSheetExpansion = { [weak self] in
            self?.presentLocationSheet()
        }
        locationPickerViewModel.onRequestSheetCollapse = { [weak self] in
            self?.dismissLocationSheet()
        }
    }

    var hasPendingAttachments: Bool {
        !pendingAssets.isEmpty || !pendingVoiceRecordings.isEmpty || pendingLocation != nil
    }

    var isPickerShown: Bool {
        pickerOverlay != .hidden
    }

    var selectedPickerTab: AttachmentPickerTab {
        switch pickerOverlay {
        case .hidden:
            config.availableAttachmentTabs.first ?? .photos
        case .attachmentPicker(let tab):
            tab
        }
    }

    var shouldShowRecordingGestureOverlay: Bool {
        guard config.isVoiceRecordingEnabled else { return false }
        if recordingState.isRecording { return true }
        guard recordingState == .initial else { return false }
        return !hasPendingAttachments
    }

    var showsRecordingOverlay: Bool {
        recordingState.isRecording || recordingState.isLockedOrStopped
    }

    // MARK: - Picker

    func toggleAttachmentPicker() {
        guard config.isAttachmentsEnabled else { return }

        switch pickerOverlay {
        case .hidden:
            guard let firstTab = config.availableAttachmentTabs.first else { return }
            pickerOverlay = .attachmentPicker(firstTab)
            if firstTab == .photos {
                askForPhotosPermission()
            }
        case .attachmentPicker:
            pickerOverlay = .hidden
            if !isLocationSheetPresented {
                locationPickerViewModel.onDisappear()
            }
        }
    }

    func setPickerTab(_ tab: AttachmentPickerTab) {
        guard config.availableAttachmentTabs.contains(tab) else { return }
        let previousTab = selectedPickerTab
        pickerOverlay = .attachmentPicker(tab)

        if previousTab == .location, tab != .location, !isLocationSheetPresented {
            locationPickerViewModel.onDisappear()
        }
        if tab == .photos {
            askForPhotosPermission()
        }
    }

    func presentLocationSheet() {
        isLocationSheetPresented = true
    }

    func dismissLocationSheet() {
        isLocationSheetPresented = false
    }

    func hidePicker() {
        pickerOverlay = .hidden
        if !isLocationSheetPresented {
            locationPickerViewModel.onDisappear()
        }
    }

    func updateKeyboardHeight(_ height: CGFloat) {
        keyboardHeight = height
        if height > 0 {
            popupHeight = height
        }
    }

    // MARK: - Assets

    func toggleMediaAsset(_ asset: AddedMediaAsset) {
        if let index = pendingAssets.firstIndex(where: { $0.id == asset.id }) {
            pendingAssets.remove(at: index)
        } else {
            addMediaAsset(asset)
        }
    }

    func addMediaAsset(_ asset: AddedMediaAsset) {
        guard canAddAsset else { return }
        pendingAssets.append(.media(asset))
    }

    func addImage(from data: Data, fileExtension: String = "jpg") {
        guard let image = UIImage(data: data) else { return }
        let fileURL = writeTemporaryFile(data: data, extension: fileExtension)
        let asset = AddedMediaAsset(url: fileURL, type: .image, image: image)
        if canAddAsset {
            addMediaAsset(asset)
        }
    }

    func addCameraImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        addImage(from: data, fileExtension: "jpg")
    }

    func cameraAssetAdded(_ asset: AddedMediaAsset) {
        guard canAddAsset, checkAttachmentSize(url: asset.url) else { return }
        addMediaAsset(asset)
        setPickerTab(.photos)
    }

    func addFileURLs(_ urls: [URL]) {
        for url in urls {
            guard canAddAsset, checkAttachmentSize(url: url) else { continue }
            pendingAssets.append(inputBarAsset(from: url))
        }
        filePickerShown = false
        if !urls.isEmpty {
            setPickerTab(.photos)
        }
    }

    func setLocation(_ location: InputBarLocation) {
        pendingLocation = location
        dismissLocationSheet()
        hidePicker()
    }

    func removeAttachment(id: String) {
        if pendingVoiceRecordings.contains(where: { $0.id == id }) {
            if let recording = pendingVoiceRecordings.first(where: { $0.id == id }),
               voicePlayback.isActive(url: recording.url) {
                voicePlayback.stop()
            }
            if pendingAudioRecording?.id == id {
                pendingAudioRecording = nil
                audioRecordingInfo = .initial
                if recordingState == .stopped {
                    recordingState = .initial
                }
            }
        }
        pendingAssets.removeAll { $0.id == id }
        pendingVoiceRecordings.removeAll { $0.id == id }
        if pendingLocation?.id == id {
            pendingLocation = nil
        }
    }

    func clearAll() {
        voicePlayback.stop()
        pendingAssets = []
        pendingVoiceRecordings = []
        pendingLocation = nil
        audioRecordingInfo = .initial
        pendingAudioRecording = nil
        recordingState = .initial
        recordingGestureLocation = .zero
        hidePicker()
    }

    func reset() {
        clearAll()
    }

    func isAssetSelected(id: String) -> Bool {
        pendingAssets.contains { asset in
            if case .media(let media) = asset {
                return media.id == id
            }
            return false
        }
    }

    func imageTapped(_ asset: AddedMediaAsset) {
        toggleMediaAsset(asset)
    }

    func askForPhotosPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            Task { @MainActor in
                switch status {
                case .authorized, .limited:
                    self.fetchPhotoLibraryAssets()
                case .denied, .restricted, .notDetermined:
                    self.photoLibraryAssets = PHFetchResult<PHAsset>()
                @unknown default:
                    break
                }
            }
        }
    }

    var selectedPhotoAssetIds: [String] {
        pendingAssets.compactMap { asset in
            if case .media(let media) = asset {
                return media.id
            }
            return nil
        }
    }

    // MARK: - Photo Library

    private func fetchPhotoLibraryAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = photoLibraryPredicate(for: config.gallerySupportedTypes)
        let assets = PHAsset.fetchAssets(with: fetchOptions)
        if let current = photoLibraryAssets, Self.haveSamePhotoLibraryContent(current, assets) {
            return
        }
        photoLibraryAssets = assets
    }

    private static func haveSamePhotoLibraryContent(
        _ lhs: PHFetchResult<PHAsset>,
        _ rhs: PHFetchResult<PHAsset>
    ) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return lhs.firstObject?.localIdentifier == rhs.firstObject?.localIdentifier
            && lhs.lastObject?.localIdentifier == rhs.lastObject?.localIdentifier
    }

    private func photoLibraryPredicate(for supportedTypes: GallerySupportedTypes) -> NSPredicate? {
        switch supportedTypes {
        case .images:
            return NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        case .videos:
            return NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        case .imagesAndVideo:
            return NSPredicate(
                format: "mediaType == %d OR mediaType == %d",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaType.video.rawValue
            )
        }
    }

    // MARK: - Private

    private var canAddAsset: Bool {
        if let max = config.maxGalleryAssetsCount {
            return pendingAssets.count < max
        }
        return true
    }

    private func inputBarAsset(from url: URL) -> InputBarAsset {
        _ = url.startAccessingSecurityScopedResource()
        let ext = url.pathExtension.lowercased()
        let imageTypes = ["jpg", "jpeg", "png", "heic", "gif", "webp"]
        let videoTypes = ["mov", "mp4", "m4v"]

        if imageTypes.contains(ext),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return .media(AddedMediaAsset(url: url, type: .image, image: image))
        }

        if videoTypes.contains(ext) {
            let avAsset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: avAsset)
            generator.appliesPreferredTrackTransform = true
            let thumbnail: UIImage = {
                if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
                    return UIImage(cgImage: cgImage)
                }
                return UIImage(systemName: "video.fill") ?? UIImage()
            }()
            let duration = CMTimeGetSeconds(avAsset.duration)
            return .media(AddedMediaAsset(
                url: url,
                type: .video,
                image: thumbnail,
                duration: duration.isFinite ? duration : nil
            ))
        }

        return .file(url)
    }

    private func checkAttachmentSize(url: URL) -> Bool {
        _ = url.startAccessingSecurityScopedResource()
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return true
        }
        let canAdd = size <= config.maxAttachmentSize
        attachmentSizeExceeded = !canAdd
        return canAdd
    }

    private func writeTemporaryFile(data: Data, extension ext: String) -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
        try? data.write(to: fileURL)
        return fileURL
    }
}
