//
//  ExplorerViewModel.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/31/25.
//

import Foundation
import FactoryKit
import MapKit

@MainActor
@Observable
class ExplorerViewModel {
  @ObservationIgnored
  @Injected(\.explorerSource) var source: ExplorerSource

  private(set) var errorDescription = ""
  private(set) var errorRecoverySuggestion = ""
  var haveError = false
  var loading = false
  var mkMapItem: MKMapItem?

  init() {
    print("ljw \(Date()) \(#file):\(#function):\(#line)")
    Task { await handleSource() }
  }

  private func handleSource() async {
     for await state in source.stream {
      switch state {
      case .error(let error):
        if case let .location(description, recoverySuggestion) = error {
          errorDescription = description ?? "Error"
          errorRecoverySuggestion = recoverySuggestion ?? "Try again later."
        } else {
          // unknown error
          errorDescription = error.localizedDescription
          errorRecoverySuggestion = ""
        }
        haveError = true
        loading = false
      case .initial:
        loading = false
        break
      case .loaded(let list):
        loading = false
        print("loaded list")
        print(list)

      case .loading(let mkMapItem):
        print("loading")
        self.mkMapItem = mkMapItem
        loading = true
      }
    }
  }
}
