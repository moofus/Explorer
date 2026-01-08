//
//  ExplorerSource.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/31/25.
//

import Foundation

import FactoryKit
import MapKit

final actor ExplorerSource {
  enum SourceError: Error {
    case cityState(String)
    case location(description: String?, recoverySuggestion: String?)
    case unknown(String)
  }

  enum State {
    case error(SourceError)
    case initial
    case loaded([AIManager.Activity])
    case loading(MKMapItem?)
  }

  @Injected(\.aiManager) var aiManager: AIManager
  @Injected(\.locationManager) var locationManager: LocationManager

  private let continuation: AsyncStream<State>.Continuation
  let stream: AsyncStream<State>

  init() {
    print("ljw \(Date()) \(#file):\(#function):\(#line)")
    (stream, continuation) = AsyncStream.makeStream(of: State.self)
    Task.detached { [weak self] in
      guard let self else { return }
      async let aiWait: Void = handleAIManager()
      async let locationWait: () = handleLocationManager()
      _ = await(aiWait, locationWait)
    }
  }
}

// MARK: - Private Location Methods
extension ExplorerSource {
  private func handle(error: LocalizedError) async {
    let error = SourceError.location(
      description: error.errorDescription,
      recoverySuggestion: error.recoverySuggestion
    )
    continuation.yield(.error(error))
  }

  private func handleAIManager() async {
    print("------------------------------")
    for await activity in aiManager.stream {
//      print("activity=\(activity)")
      continuation.yield(.loaded(activity))
    }
    print("ljw end ------------------------------")
  }
  /// Given the CLLocation get the city and state
  /// - Parameter location: the location used to get the city and state
  /// - Returns: the "city, state"
  private func handle(location: CLLocation) async {
    if let request = MKReverseGeocodingRequest(location: location) {
      do {
        let mapItems = try await request.mapItems
        print("mapItems.count=\(mapItems.count)")
        if let item = mapItems.first {
          print(item)
          print("city=\(item.addressRepresentations?.cityName ?? "home")")
          print("cityWithContext=\(item.addressRepresentations?.cityWithContext ?? "City, State")")
          print("regionName=\(item.addressRepresentations?.regionName ?? "Country")")
          print("region=\(item.addressRepresentations?.region ?? "Country")")
          if let cityState = item.addressRepresentations?.cityWithContext {
            do {
              continuation.yield(.loading(item))
              try await aiManager.findActivities(cityState: cityState)
            } catch {
              print(error)
              if let error = error as? AIManager.Error {
                let error = SourceError.location(
                  description: error.errorDescription,
                  recoverySuggestion: error.recoverySuggestion
                )
                continuation.yield(.error(error))
              } else {
                assertionFailure("unknown error=\(error)")
                continuation.yield(.error(.unknown(error.localizedDescription)))
              }
            }
            return
          }
        }
      } catch {
        print("Error MKReverseGeocodingRequest: \(error)")
        assertionFailure("unknown error=\(error)")
        continuation.yield(.error(.unknown(error.localizedDescription)))
      }
    }
    let error = SourceError.location(description: "Can't get location", recoverySuggestion: nil)
    continuation.yield(.error(error))
  }

  private func handleLocationManager() async {
    for await response in locationManager.stream {
      print(response) // ljw add warnings for print statements

      switch response {
      case .error(let error):
        await handle(error: error)
      case .location(let location):
        await handle(location: location)
      }
    }
  }
}

// MARK: - Public Methods
extension ExplorerSource {
  /// This methods verifies if the city, state exist
  /// If the spelling is a little off, it will correct the spelling and return the correct city, state
  /// - Parameter address: The city and state separated by a comma or a zipcode
  /// - Returns: The city and state separated by a comma, which may not be exactly what was entered
//  func getCityState(from address: String) async throws -> String {
//    // Create the request with the address string
//    // example addressString "Oakland, CA", to verify that "Oakland, CA" exist
//    let request = MKGeocodingRequest(addressString: address)
//    let usRegion = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Approx center of US
//        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 60) // Wide span for US
//    )
//    request?.region = usRegion
//
//    // Execute the request
//    let mapItem = (try await request?.mapItems.first)!
//
//    // Extract the coordinate from the first result
//    print(mapItem)
//    print("city=\(mapItem.addressRepresentations?.cityName ?? "home")")
//    print("cityWithContext=\(mapItem.addressRepresentations?.cityWithContext ?? "City, State")")
//    print("regionName=\(mapItem.addressRepresentations?.regionName ?? "Country")")
//    print("region=\(mapItem.addressRepresentations?.region ?? "Country")")
//    guard let region = mapItem.addressRepresentations?.region else {
//      print("no region")
//      throw SourceError.cityState("no region")
//    }
//    guard region == "US" else {
//      print("bad region")
//      throw SourceError.cityState("bad region")
//    }
//    return "\(mapItem.addressRepresentations?.cityWithContext ?? "City, State")"
//  }

  func searchCurrentLocation() async {
    print("ljw \(Date()) \(#file):\(#function):\(#line)")
    continuation.yield(.loading(nil))
    await locationManager.start(maxCount: 1)
  }
}
