//
//  ImageCache.swift
//  Test
//
//  Created by Артём on 27.06.2025.
//

import UIKit
import ImageIO

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
    static let avatarCache = NSCache<NSString, UIImage>()
    static let ratingCache = NSCache<NSNumber, UIImage>()
}

// Даунсэмплинг изображения, т.е. уменьшение его размеров до уже заданных значений перед отображением
func downsample(data: Data, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
    let options = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithData(data as CFData, options) else { return nil }
    let maxDimension = max(pointSize.width, pointSize.height) * scale
    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimension
    ] as CFDictionary
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else { return nil }
    return UIImage(cgImage: cgImage)
}

func loadImage(urlString: String, into imageView: UIImageView, activity: UIActivityIndicatorView, targetSize: CGSize = CGSize(width: 55, height: 66)) {
    guard let url = URL(string: urlString), !urlString.isEmpty else {
        imageView.image = nil
        activity.stopAnimating()
        return
    }
    if let cached = ImageCache.shared.object(forKey: urlString as NSString) {
        imageView.image = cached
        activity.stopAnimating()
        return
    }
    activity.startAnimating()
    URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async {
            activity.stopAnimating()
            if let data = data, let image = downsample(data: data, to: targetSize) {
                ImageCache.shared.setObject(image, forKey: urlString as NSString)
                imageView.image = image
            }
        }
    }.resume()
}

func loadAvatar(named name: String, into imageView: UIImageView) {
    if let cached = ImageCache.avatarCache.object(forKey: name as NSString) {
        imageView.image = cached
        return
    }
    if let image = UIImage(named: name) {
        ImageCache.avatarCache.setObject(image, forKey: name as NSString)
        imageView.image = image
    } else {
        imageView.image = nil
    }
}

func cachedRatingImage(for rating: Int, renderer: RatingRenderer) -> UIImage {
    if let cached = ImageCache.ratingCache.object(forKey: NSNumber(value: rating)) {
        return cached
    }
    let image = renderer.ratingImage(rating)
    ImageCache.ratingCache.setObject(image, forKey: NSNumber(value: rating))
    return image
}

func loadImageWithFallback(photo: PhotoURL, imageView: UIImageView, activity: UIActivityIndicatorView, targetSize: CGSize = CGSize(width: 55, height: 66)) {
    // Можно добавить fallback на другой url, если нужно
    loadImage(urlString: photo.google, into: imageView, activity: activity, targetSize: targetSize)
}
