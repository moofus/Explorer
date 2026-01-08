//
//  AppCoordinator.swift
//  Explorer
//
//  Created by Lamar Williams III on 1/8/26.
//

import Foundation
import SwiftUI

@Observable
class AppCoordinator {
  typealias Activity = ExplorerViewModel.Activity

  enum Route: Hashable {
    case content
    case detail
    case sidebar
  }

  init() {
    self.splitViewColum = NavigationSplitViewColumn.sidebar
  }

  var splitViewColum: NavigationSplitViewColumn

  func navigate(to route: Route) {
    switch route {
    case .content: splitViewColum = .content
    case .detail: splitViewColum = .detail
    case .sidebar: splitViewColum = .sidebar
    }
  }
}
