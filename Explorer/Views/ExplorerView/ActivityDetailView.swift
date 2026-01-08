//
//  ActivityDetailView.swift
//  Explorer
//
//  Created by Lamar Williams III on 1/7/26.
//


import FactoryKit
import MapKit
import SwiftUI

struct ActivityDetailView: View {
  let activity: ExplorerViewModel.Activity
    let themeColor = Color(red: 255/255, green: 129/255, blue: 66/255)
    @State private var isFavorite = false

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.99).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image
                    VStack {
                      Image(systemName: activity.imageName)
                            .font(.system(size: 80))
                            .foregroundColor(themeColor)
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 1, green: 0.9, blue: 0.8))

                    VStack(alignment: .leading, spacing: 20) {
                        // Title and Favorite
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(activity.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)

                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.orange)
                                        Text("\(String(format: "%.1f", activity.rating))")
                                            .font(.system(size: 14, weight: .semibold))
                                    }

                                    Text("(\(activity.reviews) reviews)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            Button(action: { isFavorite.toggle() }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 24))
                                    .foregroundColor(isFavorite ? themeColor : .gray)
                            }
                        }

                        // Info Cards
                        VStack(spacing: 12) {
                            InfoRow(icon: "location.fill", title: "Address", value: activity.address)
                            InfoRow(icon: "mappin.circle.fill", title: "Distance", value: "\(String(format: "%.1f", activity.distance)) miles away")
                            InfoRow(icon: "tag.fill", title: "Category", value: activity.category)
                        }

                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: { }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(themeColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button(action: { }) {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text("Get Directions")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.white)
                                .foregroundColor(themeColor)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeColor, lineWidth: 1.5)
                                )
                            }
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)

                            Text("Check out this amazing place in your area. Great for families, friends, and solo adventurers. Visit us to experience something new and exciting!")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineSpacing(2)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View { // ljw
    let icon: String
    let title: String
    let value: String
    let themeColor = Color(red: 255/255, green: 129/255, blue: 66/255)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }
}
