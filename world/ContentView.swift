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

    var body: some View {
        Group {
            ZStack(alignment: .bottomTrailing) {
                if locationManager.coordinate != nil {
                    Map(position: $cameraPosition) {
                        UserAnnotation()
                    }
                    .ignoresSafeArea(.all)
                } else if locationManager.errorMessage != nil {
                    Map(position: $cameraPosition)
                        .ignoresSafeArea(.all)
                    VStack {
                        Text(locationManager.errorMessage ?? "")
                            .font(.caption)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        Spacer()
                    }
                    .padding(.top, 50)
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
                
                Button {
                    moveToUserLocation()
                } label: {
                    Circle().fill(.ultraThinMaterial).frame(width: 50,height: 50)
                        .overlay(
                            Image(systemName: "location.fill")
                        )
                        .shadow(radius: 6)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            locationManager.requestLocation()
            Task {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    moveToUserLocation()
                }
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

#Preview {
    ContentView()
}
