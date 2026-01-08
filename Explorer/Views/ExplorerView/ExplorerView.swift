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
  typealias Activity = ExplorerViewModel.Activity

  @Injected(\.appCoordinator) var appCoordinator: AppCoordinator
  @Injected(\.explorerSource) var source: ExplorerSource
  @Injected(\.explorerViewModel) var viewModel: ExplorerViewModel

  var body: some View {
    @Bindable var viewModel = viewModel

    ZStack {
      ExplorerMainView(appCoordinator: appCoordinator, source: source, viewModel: viewModel)

      if viewModel.loading {
        ProgressView()
          .controlSize(.extraLarge)
          .padding()
          .tint(.accent)
          .background(Color.gray.opacity(0.5))
          .border(Color.yellow, width: 2)
      }
    }
  }
}

extension ExplorerView {
  struct ExplorerHeaderView: View {
    var body: some View {

      VStack(spacing: 10) {
        Text("Explorer")
          .font(.system(size: 42, weight: .bold, design: .serif))
          .foregroundColor(.accent)

        Text("Where will you explore today?")
          .font(.headline)
          .foregroundColor(.secondary)
          .padding(.bottom)
      }
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

  struct ExplorerMainView: View {
    @State private var textValue: String = ""
    @Bindable var appCoordinator: AppCoordinator
    let source: ExplorerSource
    @Bindable var viewModel: ExplorerViewModel

    var body: some View {
      NavigationSplitView(preferredCompactColumn: $appCoordinator.splitViewColum) {
        VStack {
          ExplorerHeaderView()

          ExplorerMapView(item: viewModel.mkMapItem) {
            Task {
              await source.searchCurrentLocation()
            }
          }

          ButtonWithImage(text: "Search City, State, or Zip", textValue: $textValue, systemName: "magnifyingglass") {
            print("pushed search value=\(textValue)")
            //await source.searchCityStateOrZip(text: textValue)
          }
          .padding(.top)

          Spacer()
        }
        .safeAreaPadding([.leading, .trailing])
      } detail: {
        ExplorerDetailView(
          activities: $viewModel.activities,
          location: "City"
        )
      }
//      .onChange(of: viewModel.splitViewColum) { oldVal, newVal in
//          if newVal == .sidebar {
//              print("ljw User navigated back to sidebar")
//          }
//      }
      .alert(viewModel.errorDescription, isPresented: $viewModel.haveError, presenting: viewModel) {  viewModel in
        Button("OK") {}
      } message: { error in
        Text(viewModel.errorRecoverySuggestion)
      }
    }
  }
}

#Preview {
  ExplorerView()
}


//struct CustomCircleStyle: ProgressViewStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        let fraction = configuration.fractionCompleted ?? 0
//
//        ZStack {
//            Circle()
//                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
//
//            Circle()
//                .trim(from: 0, to: CGFloat(fraction))
//                .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
//                .rotationEffect(.degrees(-90))
//                .animation(.linear, value: fraction)
//
//            Text("\(Int(fraction * 100))%")
//        }
//        .frame(width: 100, height: 100)
//    }
//}

//// Usage
//ProgressView(value: 0.6)
//    .progressViewStyle(CustomCircleStyle())
