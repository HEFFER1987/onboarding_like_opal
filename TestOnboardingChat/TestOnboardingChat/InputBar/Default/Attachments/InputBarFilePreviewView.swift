//
//  InputBarFilePreviewView.swift
//  TestOnboardingChat
//

import QuickLook
import SwiftUI

struct InputBarFilePreviewView: View {
    let url: URL

    var body: some View {
        InputBarQuickLookPreview(url: url)
            .ignoresSafeArea()
    }
}

private struct InputBarQuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        context.coordinator.startAccessingResource()
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: QLPreviewController, coordinator: Coordinator) {
        coordinator.stopAccessingResource()
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        private var isAccessingSecurityScopedResource = false

        init(url: URL) {
            self.url = url
        }

        func startAccessingResource() {
            isAccessingSecurityScopedResource = url.startAccessingSecurityScopedResource()
        }

        func stopAccessingResource() {
            if isAccessingSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
                isAccessingSecurityScopedResource = false
            }
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            url as NSURL
        }
    }
}
