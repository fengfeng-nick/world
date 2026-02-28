//
//  ProfileView.swift
//  world
//
//  个人中心页面（独立页面，无底部菜单栏）
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            Text("个人中心")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("这里是您的个人中心")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.fill.quaternary)
        .navigationTitle("个人中心")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
}
