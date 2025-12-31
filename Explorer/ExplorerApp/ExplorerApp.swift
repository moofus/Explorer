//
//  ExplorerApp.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/31/25.
//

import FactoryKit
import SwiftUI

@main
struct ExplorerApp: App {
  var body: some Scene {
    WindowGroup {
      ExplorerView()
      //          LocationManagerView()
    }
  }

}

extension Container {
  var locationManager: Factory<LocationManager> {
    self { LocationManager() }.singleton
  }
  var explorerSource: Factory<ExplorerSource> {
    self { ExplorerSource() }.singleton
  }
  @MainActor var explorerViewModel: Factory<ExplorerViewModel> {
    self { @MainActor in ExplorerViewModel() }
  }
}
