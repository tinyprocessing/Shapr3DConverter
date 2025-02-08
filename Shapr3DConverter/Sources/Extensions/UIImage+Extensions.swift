import UIKit

extension UIImage {
    func applyBlurEffect() -> UIImage? {
        let context = CIContext(options: nil)
        guard let inputImage = CIImage(image: self),
              let filter = CIFilter(name: "CIGaussianBlur")
        else { return nil }

        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(5.0, forKey: kCIInputRadiusKey)

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: inputImage.extent)
        else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsImageRenderer(size: size).image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }
}
