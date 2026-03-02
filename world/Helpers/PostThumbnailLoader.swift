//
//  PostThumbnailLoader.swift
//  world
//
//  从相册按 localIdentifier 加载帖子缩略图
//

import UIKit
import Photos

enum PostThumbnailLoader {
    private static let thumbnailSize = CGSize(width: 88, height: 88)

    /// 根据相册 localIdentifier 异步加载缩略图
    static func loadThumbnail(localIdentifier: String) async -> UIImage? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = assets.firstObject else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
