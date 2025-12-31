//
//  ExplorerView.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/31/25.
//

//
//  ExplorerView.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/21/25.
//

import FactoryKit
import MapKit
import SwiftUI

struct ExplorerView: View {
  @Injected(\.explorerSource) var source: ExplorerSource
  @Injected(\.explorerViewModel) var viewModel: ExplorerViewModel

  @State var item: MKMapItem?

  var body: some View {
    @Bindable var viewModel = viewModel

    NavigationSplitView {
      VStack {
        HeaderView()
        ZStack {
          Map() {
            if let item {
              Marker(item: item)
            }
          }
          .aspectRatio(1.0, contentMode: .fit)
          .clipShape(RoundedRectangle(cornerRadius: 30))
          .mapControlVisibility(.hidden)
          FindActivitiesButton(text: "Search Current Location") {
            Task {
              await source.findActivities()
            }
          }
        }

        ButtonWithImage(text: "Search City, State, or Zip", systemName: "magnifyingglass") {
          print("pushed search")
        }
        .padding(.top)

        Spacer()
      }      .safeAreaPadding([.leading, .trailing])
    } detail: {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Detail")
        .navigationTitle("Explorer")
    }
    .alert(viewModel.errorDescription, isPresented: $viewModel.haveError, presenting: viewModel) {  viewModel in
      Button("OK") {}
    } message: { error in
      Text(viewModel.errorRecoverySuggestion)
    }
  }

  struct HeaderView: View {
    var body: some View {
      Text("Where will you explore today?")
        .font(.title2)
//        .fontWeight(.semibold)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Text("Explorer")
              .font(.system(size: 40))
              .bold()
              .foregroundColor(.accent)
              .fixedSize()
          }
          .sharedBackgroundVisibility(.hidden)

          ToolbarItem {
            Button {
              print("pushed profile")
            } label: {
              Image(systemName: "person.fill")
                .foregroundStyle(.accent)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

#Preview {
  ExplorerView()
}
