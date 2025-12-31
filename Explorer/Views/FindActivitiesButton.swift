//
//  FindActivitiesButton.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/21/25.
//

import SwiftUI

struct FindActivitiesButton: View {
  @State private var isPerformingTask = false

  private var action: (() async -> ())?
  private var text: String

  init(text: String, action: (() -> ())? = nil) {
    self.action = action
    self.text = text
  }

  var body: some View {
    Button {
      Task {
        isPerformingTask = true
        await action?()
        try await Task.sleep(nanoseconds: 3_000_000_000)
        isPerformingTask = false
      }
    } label: {
      if isPerformingTask {
        ProgressView()
      } else {
        Label {
          Text(text)
            .font(.title3)
            .padding(10)
        } icon: {
          GPSPinView()
        }
        .padding(10)
      }
    }
    .buttonStyle(.glassProminent)
    .disabled(isPerformingTask)
  }
}

#Preview {
  FindActivitiesButton(text: "Find Nearby Activities")
}
