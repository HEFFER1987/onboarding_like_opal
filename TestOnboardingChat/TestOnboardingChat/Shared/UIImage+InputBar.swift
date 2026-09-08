//
//  UIImage+InputBar.swift
//  TestOnboardingChat
//

import UIKit

extension UIImage {
    func saveAsJpgToTemporaryUrl() throws -> URL? {
        guard let imageData = jpegData(compressionQuality: 1.0) else { return nil }
        let imageName = "\(UUID().uuidString).jpg"
        let photoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(imageName)
        try imageData.write(to: photoURL)
        return photoURL
    }
}
