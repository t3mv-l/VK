//
//  ImageCache.swift
//  Test
//
//  Created by Артём on 27.06.2025.
//

import UIKit

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
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

func loadImageWithFallback(photo: PhotoURL, imageView: UIImageView, activity: UIActivityIndicatorView) {
    loadImage(urlString: photo.google, into: imageView, activity: activity)
}
