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
  enum FindKind: String, CaseIterable, Identifiable {
    case explore
    case todo

    var id: Self { self }
  }

  @Injected(\.explorerSource) var source: ExplorerSource
  @Injected(\.explorerViewModel) var viewModel: ExplorerViewModel

  @State private var item: MKMapItem?
  @State private var findKind = FindKind.explore

  var body: some View {
    @Bindable var viewModel = viewModel

    NavigationSplitView {
      VStack {
        HeaderView()

        MyMapView(item: item)
        .overlay {
          FindActivitiesButton(text: "Search Current Location") {
            Task {
              await source.searchCurrentLocation()
            }
          }
        }

        ButtonWithImage(text: "Search City, State, or Zip", systemName: "magnifyingglass") {
          print("pushed search")
        }
        .padding(.top)

        Spacer()
      }
      .safeAreaPadding([.leading, .trailing])
    } detail: {
      DetailView()
    }
    .alert(viewModel.errorDescription, isPresented: $viewModel.haveError, presenting: viewModel) {  viewModel in
      Button("OK") {}
    } message: { error in
      Text(viewModel.errorRecoverySuggestion)
    }
  }
}

struct DetailView: View {
  var body: some View {
    Image(systemName: "globe")
      .imageScale(.large)
      .foregroundStyle(.tint)
    Text("Detail")
      .navigationTitle("Explorer")
  }
}

struct HeaderView: View {
  var body: some View {

    VStack(spacing: 10) {
      Text("Moofuslist")
        .font(.system(size: 42, weight: .bold, design: .serif))
        .foregroundColor(.accent)

      Text("Where will you explore today?")
        .font(.headline)
        .foregroundColor(.secondary)
        .padding(.bottom)
    }
    //        .padding(.top, 60)
    .toolbar {
      ToolbarItem {
        Button {
          print("pushed profile")
        } label: {
          Image(systemName: "person.fill")
            .foregroundStyle(.accent)
        }
      }
    }
    .toolbarTitleDisplayMode(.inline)
  }
}

struct MyMapView: View {
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

#Preview {
  ExplorerView()
}
