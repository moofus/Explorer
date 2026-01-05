//
//  ButtonWithImage.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/23/25.
//

import SwiftUI

struct ButtonWithImage: View {
  var text: String
  @Binding var textValue: String
  var systemName: String

   var action: (() -> ())?

  init(text: String, textValue: Binding<String>, systemName: String, action: (() -> Void)? = nil) {
    self.text = text
    self._textValue = textValue
    self.systemName = systemName
    self.action = action
  }

  var body: some View {
    Button {
      action?()
      print("ljw action")
    } label: {
      HStack {
        Image(systemName: systemName)
        TextField(text, text: $textValue)
          .onSubmit {
            action?()
          }
      }
      .font(.title3)
      .padding(.all, 10)
      .fixedSize()
    }
    .buttonStyle(.glass)
  }
}

#Preview {
  @Previewable @State var textValue: String = "testing"
  ButtonWithImage(text: "Search City, State or Zip...", textValue: $textValue, systemName: "magnifyingglass")
}
