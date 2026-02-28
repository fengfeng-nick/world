//
//  FloatingTabBar.swift
//  world
//
//  底部悬浮菜单栏组件
//

import SwiftUI

/// 底部悬浮菜单栏，包含首页、新建、个人中心导航
struct FloatingTabBar: View {
    /// 点击 ➕ 新建时的回调（跳转到新建页面）
    var onAddTap: (() -> Void)?

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
            
            // 中间新建按钮
            CameraButton {
                onAddTap?()
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
            onAddTap: {},
            onProfileTap: {}
        )
    }
}
