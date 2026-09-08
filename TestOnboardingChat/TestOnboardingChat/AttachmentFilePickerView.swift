//
//  AttachmentFilePickerView.swift
//  TestOnboardingChat
//

import SwiftUI
import UniformTypeIdentifiers

struct AttachmentFilePickerView: View {
    @Bindable var viewModel: ComposerViewModel

    var body: some View {
        FileOpenPromptView {
            viewModel.filePickerShown = true
        }
        .sheet(isPresented: $viewModel.filePickerShown) {
            DocumentPickerView { urls in
                viewModel.addFileURLs(urls)
            }
        }
        .onLoad {
            viewModel.filePickerShown = true
        }
    }
}

struct FileOpenPromptView: View {
    var onTap: () -> Void

    var body: some View {
        AttachmentPickerPromptView(
            image: Image(systemName: "doc.fill"),
            description: "Select files to attach to your message.",
            buttonText: "Browse Files",
            onTap: onTap
        )
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    var onFilesPicked: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFilesPicked: onFilesPicked)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onFilesPicked: ([URL]) -> Void

        init(onFilesPicked: @escaping ([URL]) -> Void) {
            self.onFilesPicked = onFilesPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            withAnimation {
                onFilesPicked(urls)
            }
        }
    }
}
