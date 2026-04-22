import PhotosUI
import SwiftUI
import UIKit

/// Shows a confirmation dialog offering camera or library, then hands a UIImage to `onPick`.
/// Usage:
///     .photoPicker(isPresented: $show, onPick: { image in ... })
struct PhotoPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onPick: (UIImage) -> Void

    @State private var showCamera = false
    @State private var photosItem: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Add photo", isPresented: $isPresented, titleVisibility: .visible) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take photo") { showCamera = true }
                }
                Button("Choose from library") { showLibrary() }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    showCamera = false
                    if let image { onPick(image) }
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $libraryPresented, selection: $photosItem, matching: .images)
            .onChange(of: photosItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        onPick(image)
                    }
                    photosItem = nil
                }
            }
    }

    @State private var libraryPresented = false
    private func showLibrary() { libraryPresented = true }
}

extension View {
    func photoPicker(isPresented: Binding<Bool>, onPick: @escaping (UIImage) -> Void) -> some View {
        modifier(PhotoPickerModifier(isPresented: isPresented, onPick: onPick))
    }
}

private struct CameraView: UIViewControllerRepresentable {
    let onFinish: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (UIImage?) -> Void
        init(onFinish: @escaping (UIImage?) -> Void) { self.onFinish = onFinish }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            onFinish(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish(nil)
        }
    }
}
