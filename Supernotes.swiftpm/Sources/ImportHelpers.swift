import SwiftUI
import PhotosUI
import PDFKit
import VisionKit
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

/// Turns imported media (images / PDFs) into notebook pages by saving each as a
/// page background asset. Returns the created pages.
enum PageImporter {
    static func pages(fromImages images: [UIImage]) -> [NotePage] {
        images.compactMap { image in
            guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
            let file = NoteStore.shared.saveAsset(data, ext: "jpg")
            let ar = image.size.width / max(image.size.height, 1)
            let orientation: PaperOrientation = ar >= 1 ? .landscape : .portrait
            let template = PaperTemplate(style: .blank, orientation: orientation, size: .a4, background: .white)
            return NotePage(template: template, backgroundImageFile: file)
        }
    }

    static func pages(fromPDF url: URL) -> [NotePage] {
        var result: [NotePage] = []
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        guard let doc = PDFDocument(url: url) else { return [] }
        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0
            let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            let img = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: size))
                ctx.cgContext.translateBy(x: 0, y: size.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            if let data = img.jpegData(compressionQuality: 0.85) {
                let file = NoteStore.shared.saveAsset(data, ext: "jpg")
                let orientation: PaperOrientation = bounds.width >= bounds.height ? .landscape : .portrait
                let template = PaperTemplate(style: .blank, orientation: orientation, size: .a4)
                result.append(NotePage(template: template, backgroundImageFile: file))
            }
        }
        return result
    }
}

// MARK: - Photos picker

struct PhotoImportPicker: UIViewControllerRepresentable {
    var onComplete: ([UIImage]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0 // multiple
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onComplete: ([UIImage]) -> Void
        init(onComplete: @escaping ([UIImage]) -> Void) { self.onComplete = onComplete }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            let providers = results.map { $0.itemProvider }
            var images: [UIImage] = []
            let group = DispatchGroup()
            for provider in providers where provider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { obj, _ in
                    if let img = obj as? UIImage { images.append(img) }
                    group.leave()
                }
            }
            group.notify(queue: .main) { self.onComplete(images) }
        }
    }
}

// MARK: - Files picker (PDF + images)

struct FileImportPicker: UIViewControllerRepresentable {
    var onComplete: ([NotePage]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onComplete: ([NotePage]) -> Void
        init(onComplete: @escaping ([NotePage]) -> Void) { self.onComplete = onComplete }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            var pages: [NotePage] = []
            for url in urls {
                if url.pathExtension.lowercased() == "pdf" {
                    pages.append(contentsOf: PageImporter.pages(fromPDF: url))
                } else if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                    pages.append(contentsOf: PageImporter.pages(fromImages: [img]))
                }
            }
            onComplete(pages)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onComplete([])
        }
    }
}

// MARK: - Camera

struct CameraPicker: UIViewControllerRepresentable {
    var onComplete: ([UIImage]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onComplete: ([UIImage]) -> Void
        init(onComplete: @escaping ([UIImage]) -> Void) { self.onComplete = onComplete }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let img = info[.originalImage] as? UIImage { onComplete([img]) } else { onComplete([]) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true); onComplete([])
        }
    }
}

// MARK: - Document scanner (VisionKit)

struct DocumentScanner: UIViewControllerRepresentable {
    var onComplete: ([UIImage]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: ([UIImage]) -> Void
        init(onComplete: @escaping ([UIImage]) -> Void) { self.onComplete = onComplete }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount { images.append(scan.imageOfPage(at: i)) }
            controller.dismiss(animated: true)
            onComplete(images)
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true); onComplete([])
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true); onComplete([])
        }
    }
}
