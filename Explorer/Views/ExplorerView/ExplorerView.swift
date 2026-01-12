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
  @Injected(\.explorerViewModel) var viewModel: ExplorerViewModel

  var body: some View {
    @Bindable var viewModel = viewModel

    let _ = print("ljw loading=\(viewModel.loading) \(Date()) \(#file):\(#function):\(#line)")

    ZStack {
      ExplorerMainView(appCoordinator: appCoordinator, viewModel: viewModel)

      if viewModel.loading, appCoordinator.splitViewColum == .sidebar {
        Label("Using Apple Intelligent", image: "sparkles")
//        ProgressView()
//          .controlSize(.extraLarge)
//          .padding()
//          .tint(.accent)
//          .background(Color.gray.opacity(0.5))
//          .border(Color.yellow, width: 2)
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
    @Injected(\.explorerSource) var source: ExplorerSource
    @Bindable var appCoordinator: AppCoordinator
    @State private var searchText: String = ""
    @Bindable var viewModel: ExplorerViewModel

    var body: some View {
      NavigationSplitView(preferredCompactColumn: $appCoordinator.splitViewColum) {
        VStack {
          ExplorerHeaderView()

          ExplorerMapView(displayButton: !viewModel.isProcessing, item: viewModel.mkMapItem) {
            Task {
              viewModel.isProcessing = true
              await source.searchCurrentLocation()
            }
          }

          Spacer()
        }
        .searchable(text: $searchText, prompt: "Search City, State, or Zip")
        .onSubmit(of: .search) {
          if searchText.validateTwoStringsSeparatedByComma() {
            Task {
              viewModel.isProcessing = true
              await source.searchCityState(searchText)
            }
          } else {
            viewModel.inputError = true
          }
        }
        .safeAreaPadding([.leading, .trailing])
      } content: {
        ZStack {
//          Text("Please preform a search")
          ExplorerDetailView(
            activities: $viewModel.activities,
            location: "City"
          )
        }
      } detail: {
        Text("DetailView")
      }
      .disabled(viewModel.isProcessing)
      .alert("\"City, State\" is invalid!", isPresented: $viewModel.inputError) {
        Button("OK") {}
      }
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
