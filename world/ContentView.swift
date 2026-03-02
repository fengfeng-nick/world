//
//  ContentView.swift
//  world
//
//  Created by nick on 2026/2/27.
//

import SwiftUI
import MapKit

struct ContentView: View {

    @EnvironmentObject var postStorage: PostStorageService
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                // 主内容区域
                ZStack(alignment: .bottomTrailing) {
                    mapContent
                    
                    if locationManager.coordinate != nil {
                        Button {
                            moveToUserLocation()
                        } label: {
                            Circle().fill(.ultraThinMaterial).frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "location.fill")
                                )
                                .shadow(radius: 6)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 120)
                    }
                }
                
                // 底部悬浮菜单栏
                FloatingTabBar(
                    onAddTap: {
                        navigationPath.append(NavigationRoute.addPost)
                    },
                    onProfileTap: {
                        navigationPath.append(NavigationRoute.profile)
                    }
                )
            }
            .navigationDestination(for: NavigationRoute.self) { route in
                switch route {
                case .profile:
                    ProfileView()
                case .addPost:
                    AddPostView(locationManager: locationManager)
                }
            }
        }
        .onAppear {
            locationManager.requestLocation()
            delayMoveToUserLocation(delay: 1)
        }
        .onChange(of: locationManager.authorizationStatus) {
            if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                delayMoveToUserLocation(delay: 1)
            }
        }
    }
    
    @ViewBuilder
    private var mapContent: some View {
        if locationManager.coordinate != nil {
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(postStorage.posts) { post in
                    Annotation(
                        post.content.isEmpty ? "帖子" : String(post.content.prefix(20)),
                        coordinate: CLLocationCoordinate2D(latitude: post.latitude, longitude: post.longitude)
                    ) {
                        PostThumbnailView(post: post)
                    }
                }
            }
            .ignoresSafeArea(.all)
        } else if locationManager.errorMessage != nil {
            Map(position: $cameraPosition) {
                ForEach(postStorage.posts) { post in
                    Annotation(
                        post.content.isEmpty ? "帖子" : String(post.content.prefix(20)),
                        coordinate: CLLocationCoordinate2D(latitude: post.latitude, longitude: post.longitude)
                    ) {
                        PostThumbnailView(post: post)
                    }
                }
            }
            .ignoresSafeArea(.all)
        } else {
            VStack(spacing: 16) {
                ProgressView()
                Text("正在获取您的位置…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.fill.quaternary)
        }
    }
    
    private func delayMoveToUserLocation(delay: Int) {
        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                moveToUserLocation()
            }
        }
    }

    private func moveToUserLocation() {
        if let coordinate = locationManager.coordinate {
            withAnimation{
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.3)
                ))
            }
        } else {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.9, longitude: 116.4),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
}

// MARK: - 导航路由

private enum NavigationRoute: Hashable {
    case profile
    case addPost
}

// MARK: - 地图帖子缩略图（有图显示首图，无图显示钢笔图标）

private struct PostThumbnailView: View {
    let post: PostRecord
    @State private var thumbnailImage: UIImage?

    private let size: CGFloat = 44

    var body: some View {
        Group {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.gradient)
                    .overlay {
                        Image(systemName: "pencil")
                            .font(.system(size: size * 0.45, weight: .medium))
                            .foregroundStyle(.white)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.white.opacity(0.8), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        .task {
            guard let firstId = post.imageLocalIdentifiers.first else { return }
            thumbnailImage = await PostThumbnailLoader.loadThumbnail(localIdentifier: firstId)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PostStorageService())
}
