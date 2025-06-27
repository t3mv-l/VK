//
//  ImageCache.swift
//  Test
//
//  Created by Артём on 27.06.2025.
//

import UIKit

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
    static let avatarCache = NSCache<NSString, UIImage>()
    static let ratingCache = NSCache<NSNumber, UIImage>()
}

func loadImage(urlString: String, into imageView: UIImageView, activity: UIActivityIndicatorView) {
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
            if let data = data, let image = UIImage(data: data) {
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

func loadImageWithFallback(photo: PhotoURL, imageView: UIImageView, activity: UIActivityIndicatorView) {
    loadImage(urlString: photo.google, into: imageView, activity: activity)
}
