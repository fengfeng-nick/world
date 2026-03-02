//
//  AddPostView.swift
//  world
//
//  新建帖子页面：拍照、输入内容、显示定位、保存
//

import SwiftUI
import UIKit
import Photos
import CoreLocation
import MapKit

struct AddPostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postStorage: PostStorageService
    @ObservedObject var locationManager: LocationManager

    @State private var textContent = ""
    @State private var capturedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSaveAlert = false
    @State private var addressString: String?
    @State private var isGeocoding = false
    @State private var previewStartingIndex: Int?
    @State private var keyboardHeight: CGFloat = 0

    /// 用于 onChange 的 Equatable 键（CLLocationCoordinate2D 不遵循 Equatable）
    private var coordinateKey: String {
        guard let c = locationManager.coordinate else { return "" }
        return "\(c.latitude),\(c.longitude)"
    }

    private var locationDescription: String {
        if let address = addressString, !address.isEmpty {
            return address
        }
        if isGeocoding {
            return "正在获取地址…"
        }
        if locationManager.errorMessage != nil {
            return "定位未授权"
        }
        if locationManager.coordinate != nil {
            return "正在获取地址…"
        }
        return "正在获取位置…"
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // 文本输入
                    textInputSection
                        .id("contentInput")

                    // 图片区域
                    if !capturedImages.isEmpty {
                        imageSection
                    } else {
                        addPhotoButton
                    }

                    // 定位区域
                    locationSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, keyboardHeight + 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemBackground))
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = frame.height
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("contentInput", anchor: .center)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }
        }
        .navigationTitle("新建")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("发布") {
                    savePost()
                }
                .font(.system(size: 16, weight: .bold))
                .disabled(isSaving || (textContent.isEmpty && capturedImages.isEmpty))
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .regular))
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker(
                onImagePicked: { image in
                    capturedImages.append(image)
                    showCamera = false
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea(.all)
        }
        .fullScreenCover(isPresented: Binding(
            get: { previewStartingIndex != nil },
            set: { if !$0 { previewStartingIndex = nil } }
        )) {
            if let index = previewStartingIndex, !capturedImages.isEmpty {
                ImagePreviewView(
                    images: capturedImages,
                    initialIndex: min(index, capturedImages.count - 1),
                    onDismiss: { previewStartingIndex = nil }
                )
            }
        }
        .onAppear {
            if let coord = locationManager.coordinate, addressString == nil {
                reverseGeocode(coord)
            }
        }
        .onChange(of: coordinateKey) { _, _ in
            if let coord = locationManager.coordinate {
                reverseGeocode(coord)
            } else {
                addressString = nil
            }
        }
        .alert("保存失败", isPresented: $showSaveAlert) {
            Button("确定") { showSaveAlert = false }
        } message: {
            Text(saveError ?? "未知错误")
        }
    }

    @ViewBuilder
    private var locationSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(locationManager.coordinate != nil ? Color.accentColor : Color.secondary)

            Text(locationDescription)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(locationManager.coordinate != nil ? Color.primary : Color.secondary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    @ViewBuilder
    private var addPhotoButton: some View {
        Button {
            showCamera = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "camera")
                    .font(.system(size: 20, weight: .medium))
                Text("添加照片")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(Color.primary)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                            .onTapGesture {
                                previewStartingIndex = index
                            }
                        
                        Button {
                            let idx = index
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                capturedImages.removeSubrange(idx..<(idx + 1))
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6), in: Circle())
                                .environment(\.colorScheme, .dark)
                        }
                        .padding(8)
                    }
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }

                Button {
                    showCamera = true
                } label: {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(uiColor: .systemGray4), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                        .frame(width: 140, height: 180)
                        .background(Color(uiColor: .systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .light))
                                Text("继续添加")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, -24)
    }

    @ViewBuilder
    private var textInputSection: some View {
        TextField("此时此刻的想法...", text: $textContent, axis: .vertical)
            .font(.system(size: 20, weight: .regular))
            .lineSpacing(8)
            .textFieldStyle(.plain)
            .frame(minHeight: 140, alignment: .topLeading)
    }

    private func savePost() {
        isSaving = true

        Task {
            do {
                let imageIdentifiers = try await saveImagesToPhotoLibrary(capturedImages)

                await MainActor.run {
                    guard let coordinate = locationManager.coordinate else {
                        saveError = "请允许定位权限以保存位置"
                        showSaveAlert = true
                        isSaving = false
                        return
                    }

                    let record = PostRecord(
                        content: textContent,
                        imageLocalIdentifiers: imageIdentifiers,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )

                    postStorage.savePost(record)
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    saveError = error.localizedDescription
                    showSaveAlert = true
                    isSaving = false
                }
            }
        }
    }

    /// 将图片保存到本地相册，返回 PHAsset 的 localIdentifier 列表
    private func saveImagesToPhotoLibrary(_ images: [UIImage]) async throws -> [String] {
        guard !images.isEmpty else { return [] }

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

        guard status == .authorized || status == .limited else {
            throw NSError(
                domain: "AddPostView",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "请在设置中允许访问相册以保存照片"]
            )
        }

        var resultIdentifiers: [String] = []

        for image in images {
            let id = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                var placeholder: PHObjectPlaceholder?
                var hasResumed = false
                let lock = NSLock()
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    placeholder = request.placeholderForCreatedAsset
                } completionHandler: { success, error in
                    lock.lock()
                    defer { lock.unlock() }
                    guard !hasResumed else { return }
                    hasResumed = true
                    if success, let localId = placeholder?.localIdentifier {
                        continuation.resume(returning: localId)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: NSError(
                            domain: "AddPostView",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "保存照片失败"]
                        ))
                    }
                }
            }
            resultIdentifiers.append(id)
        }

        return resultIdentifiers
    }

    /// 逆地理编码：将坐标转换为实际地址（使用 CoreLocation CLGeocoder）
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let fallback = String(format: "%.6f°, %.6f°", coordinate.latitude, coordinate.longitude)

        Task {
            do {
                let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
                await MainActor.run {
                    isGeocoding = false
                    if let place = placemarks.first {
                        addressString = formatAddress(from: place) ?? fallback
                    } else {
                        addressString = fallback
                    }
                }
            } catch {
                await MainActor.run {
                    isGeocoding = false
                    addressString = fallback
                }
            }
        }
    }

    /// 从 CLPlacemark 拼出可读地址
    private func formatAddress(from place: CLPlacemark) -> String? {
        var parts: [String] = []
        if let name = place.name, !name.isEmpty { parts.append(name) }
        if let thoroughfare = place.thoroughfare, !thoroughfare.isEmpty { parts.append(thoroughfare) }
        if let locality = place.locality, !locality.isEmpty { parts.append(locality) }
        if let administrativeArea = place.administrativeArea, !administrativeArea.isEmpty { parts.append(administrativeArea) }
        if let country = place.country, !country.isEmpty { parts.append(country) }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

// MARK: - 图片预览（居中显示，左右滑动切换）

private struct ImagePreviewView: View {
    let images: [UIImage]
    let initialIndex: Int
    let onDismiss: () -> Void

    @State private var currentIndex: Int

    init(images: [UIImage], initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.images = images
        self.initialIndex = min(initialIndex, max(0, images.count - 1))
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: min(initialIndex, max(0, images.count - 1)))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    GeometryReader { geo in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .onAppear {
                currentIndex = initialIndex
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            .padding()
        }
        .onTapGesture {
            onDismiss()
        }
    }
}
