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

    /// 已保存的帖子列表，供地图等界面展示
    @Published private(set) var posts: [PostRecord] = []

    init() {
        posts = loadPostsFromStorage()
    }

    /// 加载所有已保存的帖子（从存储读取）
    private func loadPostsFromStorage() -> [PostRecord] {
        guard let data = UserDefaults.standard.data(forKey: postsKey) else {
            return []
        }
        return (try? JSONDecoder().decode([PostRecord].self, from: data)) ?? []
    }

    /// 保存新帖子
    func savePost(_ post: PostRecord) {
        var list = loadPostsFromStorage()
        list.insert(post, at: 0)
        savePosts(list)
        posts = list
    }

    private func savePosts(_ posts: [PostRecord]) {
        guard let data = try? JSONEncoder().encode(posts) else { return }
        UserDefaults.standard.set(data, forKey: postsKey)
    }
}
