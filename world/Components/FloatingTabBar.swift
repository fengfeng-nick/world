//
//  FloatingTabBar.swift
//  world
//
//  底部悬浮菜单栏组件
//

import SwiftUI

/// 底部悬浮菜单栏，包含首页、拍照、个人中心导航
struct FloatingTabBar: View {
    /// 是否显示相机
    @Binding var showCamera: Bool
    
    /// 拍照完成回调，返回拍摄的图片
    var onPhotoTaken: ((UIImage) -> Void)?
    
    /// 点击个人中心时的回调（用于跳转到独立页面）
    var onProfileTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 0) {
            // 首页
            TabButton(
                icon: "house.fill",
                title: "首页",
                isSelected: true
            ) {
                // 首页为根页面，无需切换
            }
            
            Spacer()
            
            // 中间拍照按钮
            CameraButton {
                showCamera = true
            }
            
            Spacer()
            
            // 个人中心（跳转到独立页面）
            TabButton(
                icon: "person.fill",
                title: "个人中心",
                isSelected: false
            ) {
                onProfileTap?()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .sheet(isPresented: $showCamera) {
            CameraImagePicker(onImagePicked: { image in
                onPhotoTaken?(image)
                showCamera = false
            }, onCancel: {
                showCamera = false
            })
        }
    }
}

// MARK: - Tab 按钮

private struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 拍照按钮

private struct CameraButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: .accentColor.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .offset(y: -12)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        FloatingTabBar(
            showCamera: .constant(false),
            onProfileTap: {}
        )
    }
}
