//
//  PostRecord.swift
//  world
//
//  本地存储的帖子记录模型
//

import Foundation

/// 保存到本地的帖子记录，图片只存储相册中的 localIdentifier
struct PostRecord: Codable, Identifiable {
    let id: UUID
    let content: String
    /// 本地相册中照片的 PHAsset localIdentifier 列表
    let imageLocalIdentifiers: [String]
    let latitude: Double
    let longitude: Double
    let createdAt: Date

    init(
        id: UUID = UUID(),
        content: String,
        imageLocalIdentifiers: [String],
        latitude: Double,
        longitude: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.imageLocalIdentifiers = imageLocalIdentifiers
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
}
