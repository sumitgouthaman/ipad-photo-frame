import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    
    func load(url: URL, targetSize: CGSize) {
        cancellable = Future<UIImage?, Never> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                let image = self.downsample(imageAt: url, to: targetSize)
                DispatchQueue.main.async {
                    promise(.success(image))
                }
            }
        }
        .assign(to: \.image, on: self)
    }
    
    func cancel() {
        cancellable?.cancel()
    }
    
    private func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
}

struct ThumbnailView: View {
    let url: URL
    let size: CGFloat
    
    @StateObject private var loader = ImageLoader()
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            loader.load(url: url, targetSize: CGSize(width: size, height: size))
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
