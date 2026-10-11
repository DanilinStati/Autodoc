import ImageIO
import UIKit

actor ImageLoader {
    private let session: URLSession
    private var inFlight: [CacheKey: Task<UIImage, Error>] = [:]
    private nonisolated(unsafe) let memoryCache = NSCache<CacheKey, UIImage>()

    init(
        memoryLimitBytes: Int = 120 * 1024 * 1024,
        diskCapacityBytes: Int = 300 * 1024 * 1024
    ) {
        session = Self.makeSession(diskCapacityBytes: diskCapacityBytes)
        memoryCache.totalCostLimit = memoryLimitBytes
    }

    nonisolated func cachedImage(for url: URL, maxPixelSize: CGFloat) -> UIImage? {
        memoryCache.object(forKey: CacheKey(url: url, maxPixelSize: maxPixelSize))
    }

    func image(for url: URL, maxPixelSize: CGFloat) async throws -> UIImage {
        let key = CacheKey(url: url, maxPixelSize: maxPixelSize)

        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        if let running = inFlight[key] {
            return try await running.value
        }

        let task = makeLoadTask(url: url, maxPixelSize: maxPixelSize)
        inFlight[key] = task
        defer {
            inFlight[key] = nil
        }

        let image = try await task.value
        memoryCache.setObject(image, forKey: key, cost: image.memoryCost)
        return image
    }

    nonisolated func prefetch(_ url: URL, maxPixelSize: CGFloat) {
        guard cachedImage(for: url, maxPixelSize: maxPixelSize) == nil else {
            return
        }

        Task(priority: .utility) {
            _ = try? await self.image(for: url, maxPixelSize: maxPixelSize)
        }
    }

    private func makeLoadTask(url: URL, maxPixelSize: CGFloat) -> Task<UIImage, Error> {
        let session = self.session
        return Task.detached(priority: .userInitiated) {
            try await Self.fetchAndDownsample(url: url, maxPixelSize: maxPixelSize, session: session)
        }
    }

    private nonisolated static func makeSession(diskCapacityBytes: Int) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = makeDiskCache(capacity: diskCapacityBytes)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: configuration)
    }

    private nonisolated static func makeDiskCache(capacity: Int) -> URLCache {
        let directory = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appending(path: "Images", directoryHint: .isDirectory)
        return URLCache(memoryCapacity: 0, diskCapacity: capacity, directory: directory)
    }

    private nonisolated static func fetchAndDownsample(
        url: URL,
        maxPixelSize: CGFloat,
        session: URLSession
    ) async throws -> UIImage {
        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NetworkError.httpStatus(http.statusCode)
        }

        guard let image = downsample(data, maxPixelSize: maxPixelSize) else {
            throw NetworkError.decoding
        }

        return image
    }

    private nonisolated static func downsample(_ data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary

        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixelSize),
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

extension ImageLoader {
    nonisolated final class CacheKey: NSObject, Sendable {
        let url: URL
        let maxPixelSize: Int

        init(url: URL, maxPixelSize: CGFloat) {
            self.url = url
            self.maxPixelSize = Int(maxPixelSize.rounded(.up))
        }

        override var hash: Int {
            var hasher = Hasher()
            hasher.combine(url)
            hasher.combine(maxPixelSize)
            return hasher.finalize()
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? CacheKey else {
                return false
            }

            return url == other.url && maxPixelSize == other.maxPixelSize
        }
    }
}

private extension UIImage {
    nonisolated var memoryCost: Int {
        guard let cgImage else {
            return 1
        }

        return cgImage.bytesPerRow * cgImage.height
    }
}
