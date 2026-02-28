//
//  PostStorageService.swift
//  world
//
//  App 本地存储服务
//

import Foundation
import Combine

@MainActor
final class PostStorageService: ObservableObject {
    private let postsKey = "world_saved_posts"

    /// 加载所有已保存的帖子
    func loadPosts() -> [PostRecord] {
        guard let data = UserDefaults.standard.data(forKey: postsKey) else {
            return []
        }
        return (try? JSONDecoder().decode([PostRecord].self, from: data)) ?? []
    }

    /// 保存新帖子
    func savePost(_ post: PostRecord) {
        var posts = loadPosts()
        posts.insert(post, at: 0)
        savePosts(posts)
    }

    private func savePosts(_ posts: [PostRecord]) {
        guard let data = try? JSONEncoder().encode(posts) else { return }
        UserDefaults.standard.set(data, forKey: postsKey)
    }
}
