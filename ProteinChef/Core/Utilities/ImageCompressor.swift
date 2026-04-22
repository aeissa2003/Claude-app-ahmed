import UIKit

enum ImageCompressor {
    /// Resize the longest edge to `maxEdge` and encode as JPEG at the given quality.
    /// Returns nil if the image cannot be encoded (shouldn't happen for normal photos).
    static func jpegData(from image: UIImage, maxEdge: CGFloat = 1600, quality: CGFloat = 0.75) -> Data? {
        let scaled = downscale(image, maxEdge: maxEdge)
        return scaled.jpegData(compressionQuality: quality)
    }

    static func downscale(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let longEdge = max(image.size.width, image.size.height)
        guard longEdge > maxEdge else { return image }
        let scale = maxEdge / longEdge
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
