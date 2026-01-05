//
//  ExplorerMapView.swift
//  Explorer
//
//  Created by Lamar Williams III on 1/4/26.
//


import FactoryKit
import MapKit
import SwiftUI

struct ExplorerMapView: View {
  let item: MKMapItem?
  var body: some View {
    Map() {
      if let item {
        Marker(item: item)
      }
    }
    .aspectRatio(1.0, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 30))
    .mapControlVisibility(.hidden)
  }
}
