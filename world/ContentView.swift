//
//  ContentView.swift
//  world
//
//  Created by nick on 2026/2/27.
//

import SwiftUI
import MapKit

struct ContentView: View {

    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
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
                    showCamera: $showCamera,
                    onPhotoTaken: { image in
                        capturedImage = image
                        // 可在此处理拍照后的逻辑，如上传、保存等
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
            }
            .ignoresSafeArea(.all)
        } else if locationManager.errorMessage != nil {
            Map(position: $cameraPosition)
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
}

#Preview {
    ContentView()
}
