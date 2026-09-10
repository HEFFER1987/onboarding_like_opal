//
//  InputBarModels.swift
//  TestOnboardingChat
//

import CoreLocation
import SwiftUI
import UIKit

enum AttachmentPickerTab: String, CaseIterable, Sendable {
    case photos
    case camera
    case files
    case location
}

enum PickerOverlayState: Equatable, Sendable {
    case hidden
    case attachmentPicker(AttachmentPickerTab)
}

enum InputBarAssetType: Sendable {
    case image
    case video
}

/// A photo or video added to the composer from the gallery, camera, or file picker.
struct AddedMediaAsset: Identifiable, Equatable, Sendable {
    let id: String
    let url: URL
    let type: InputBarAssetType
    let image: UIImage
    let duration: TimeInterval?

    init(
        id: String = UUID().uuidString,
        url: URL,
        type: InputBarAssetType,
        image: UIImage,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.url = url
        self.type = type
        self.image = image
        self.duration = duration
    }

    static func == (lhs: AddedMediaAsset, rhs: AddedMediaAsset) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents either a media asset (image/video) or a file URL in the composer tray.
enum InputBarAsset: Identifiable, Equatable, Sendable {
    case media(AddedMediaAsset)
    case file(URL)

    var id: String {
        switch self {
        case .media(let asset):
            asset.id
        case .file(let url):
            url.absoluteString
        }
    }

    static func == (lhs: InputBarAsset, rhs: InputBarAsset) -> Bool {
        lhs.id == rhs.id
    }
}

struct InputBarVoiceRecording: Identifiable, Equatable, Sendable {
    var id: String { url.absoluteString }
    let url: URL
    let duration: TimeInterval
    let waveform: [Float]
}

struct InputBarLocation: Identifiable, Equatable, Sendable {
    let id: String
    let latitude: Double
    let longitude: Double
    let label: String?

    init(
        id: String = UUID().uuidString,
        latitude: Double,
        longitude: Double,
        label: String? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.label = label
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct InputBarFeatureConfig: Sendable {
    var isAttachmentsEnabled: Bool = true
    var isGalleryImagesEnabled: Bool = true
    var isGalleryVideosEnabled: Bool = true
    var isCameraEnabled: Bool = true
    var isFileAttachmentEnabled: Bool = true
    var isLocationAttachmentEnabled: Bool = true
    var isVoiceRecordingEnabled: Bool = true
    var isVoiceRecordingAutoSendEnabled: Bool = false
    var maxGalleryAssetsCount: Int? = 10
    var maxAttachmentSize: Int64 = 100 * 1024 * 1024

    static let `default` = InputBarFeatureConfig()

    var isGalleryTabEnabled: Bool {
        isGalleryImagesEnabled || isGalleryVideosEnabled
    }

    var gallerySupportedTypes: GallerySupportedTypes {
        switch (isGalleryImagesEnabled, isGalleryVideosEnabled) {
        case (true, true):
            .imagesAndVideo
        case (true, false):
            .images
        case (false, true):
            .videos
        case (false, false):
            .imagesAndVideo
        }
    }

    var availableAttachmentTabs: [AttachmentPickerTab] {
        var tabs: [AttachmentPickerTab] = []
        if isGalleryTabEnabled {
            tabs.append(.photos)
        }
        if isCameraEnabled {
            tabs.append(.camera)
        }
        if isFileAttachmentEnabled {
            tabs.append(.files)
        }
        if isLocationAttachmentEnabled {
            tabs.append(.location)
        }
        return tabs
    }

    var isAttachmentButtonVisible: Bool {
        isAttachmentsEnabled && !availableAttachmentTabs.isEmpty
    }
}

enum GallerySupportedTypes: Sendable {
    case imagesAndVideo
    case images
    case videos
}

struct AudioRecordingInfo: Equatable, Sendable {
    var waveform: [Float]
    var duration: TimeInterval

    static let initial = AudioRecordingInfo(waveform: [], duration: 0)

    mutating func update(with entry: Float, duration: TimeInterval) {
        waveform.append(entry)
        self.duration = duration
    }

    mutating func updateDuration(_ duration: TimeInterval) {
        self.duration = duration
    }
}
