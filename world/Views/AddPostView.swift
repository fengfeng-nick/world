//
//  AddPostView.swift
//  world
//
//  新建帖子页面：拍照、输入内容、显示定位、保存
//

import SwiftUI
import Photos
import CoreLocation
import MapKit

struct AddPostView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    @StateObject private var postStorage = PostStorageService()

    @State private var textContent = ""
    @State private var capturedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSaveAlert = false
    @State private var addressString: String?
    @State private var isGeocoding = false

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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 图片区域
                imageSection

                // 文本输入
                textInputSection

                // 定位区域（放在内容后面，无背景）
                locationSection

                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(.fill.quaternary)
        .navigationTitle("新建")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    savePost()
                }
                .disabled(isSaving || (textContent.isEmpty && capturedImages.isEmpty))
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraImagePicker(
                onImagePicked: { image in
                    capturedImages.append(image)
                    showCamera = false
                },
                onCancel: { showCamera = false }
            )
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
        HStack(spacing: 12) {
            Image(systemName: locationManager.coordinate != nil ? "location.fill" : "location")
                .font(.title2)
                .foregroundStyle(locationManager.coordinate != nil ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("当前位置")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(locationDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("照片")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    capturedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .shadow(radius: 2)
                                }
                                .offset(x: 6, y: -6)
                            }
                    }

                    Button {
                        showCamera = true
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容")
                .font(.headline)

            TextField("输入一些内容…", text: $textContent, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .frame(minHeight: 100, alignment: .topLeading)
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                .lineLimit(5...10)
        }
    }

    private func savePost() {
        isSaving = true

        Task {
            do {
                let imageIdentifiers = try await saveImagesToPhotoLibrary(capturedImages)

                guard let coordinate = locationManager.coordinate else {
                    await MainActor.run {
                        saveError = "请允许定位权限以保存位置"
                        showSaveAlert = true
                        isSaving = false
                    }
                    return
                }

                let record = PostRecord(
                    content: textContent,
                    imageLocalIdentifiers: imageIdentifiers,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )

                postStorage.savePost(record)

                await MainActor.run {
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

        let status = await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }

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
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    placeholder = request.placeholderForCreatedAsset
                } completionHandler: { success, error in
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

    /// 逆地理编码：将坐标转换为实际地址（使用 MapKit MKReverseGeocodingRequest）
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        Task {
            do {
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    await MainActor.run {
                        isGeocoding = false
                        addressString = String(format: "%.6f°, %.6f°", coordinate.latitude, coordinate.longitude)
                    }
                    return
                }
                let mapItems = try await request.mapItems
                await MainActor.run {
                    isGeocoding = false
                    if let mapItem = mapItems.first,
                       let addr = mapItem.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true) {
                        addressString = addr
                    } else {
                        addressString = String(format: "%.6f°, %.6f°", coordinate.latitude, coordinate.longitude)
                    }
                }
            } catch {
                await MainActor.run {
                    isGeocoding = false
                    addressString = String(format: "%.6f°, %.6f°", coordinate.latitude, coordinate.longitude)
                }
            }
        }
    }
}
