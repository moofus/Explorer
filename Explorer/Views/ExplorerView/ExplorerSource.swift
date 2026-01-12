//
//  ExplorerSource.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/31/25.
//

import Foundation
import FactoryKit
import MapKit
import os
import SwiftUI

final actor ExplorerSource {
  enum SourceError: Error {
    case location(description: String?, recoverySuggestion: String?)
    case unknown(String)
  }

  enum Message {
    case error(SourceError)
    case badInput
    case initial
    case loaded
    case loading(MKMapItem?, [AIManager.Activity])
    
  }

  @Injected(\.aiManager) var aiManager: AIManager
  @Injected(\.locationManager) var locationManager: LocationManager

  private let continuation: AsyncStream<Message>.Continuation
  private(set) var locationToSearch = CLLocation()
  private let logger = Logger(subsystem: "com.moofus.Explorer", category: "ExplorerSorce")
  let stream: AsyncStream<Message>

  init() {
    print("ljw \(Date()) \(#file):\(#function):\(#line)")
    (stream, continuation) = AsyncStream.makeStream(of: Message.self)
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
    for await message in aiManager.stream {
      switch message {
      case .begin:
        Task { @MainActor in
          @Injected(\.appCoordinator) var appCoordinator: AppCoordinator
          appCoordinator.navigate(to: .content)
        }
      case .end:
        continuation.yield(.loaded) // ljw handle activities.isEmpty
      case .error(_):
        fatalError()
      case .loading(let activities):
        continuation.yield(.loading(nil, activities)) // ljw handle activities.isEmpty
      }
    }
  }
  /// Given the CLLocation get the city and state
  /// - Parameter location: the location used to get the city and state
  /// - Returns: the "city, state"
  private func handle(location: CLLocation) async {
    self.locationToSearch = location
    if let request = MKReverseGeocodingRequest(location: location) { // ljw use cache
      do {
        let mapItems = try await request.mapItems
        print("mapItems.count=\(mapItems.count)")
        if let item = mapItems.first {
           if let cityState = item.addressRepresentations?.cityWithContext {
            do {
              continuation.yield(.loading(item, []))
              try await aiManager.findActivities(cityState: cityState)
            } catch {
              print("ljw \(Date()) \(#file):\(#function):\(#line)")
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
        } else {
          fatalError()
          // ljw handle
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
    for await message in locationManager.stream {
      print(message) // ljw add warnings for print statements

      switch message {
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


  func searchCityState(_ cityState: String) async {
    logger.info("cityState=\(cityState)")
    // Create the request with the address string
    // example addressString "Oakland, CA", to verify that "Oakland, CA" exist
    let request = MKGeocodingRequest(addressString: cityState)
//    let usRegion = MKCoordinateRegion(
//      center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Approx center of US
//      span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 60) // Wide span for US
//    )
//    request?.region = usRegion

    // Execute the request
    do {
      let mapItem = (try await request?.mapItems.first)!

//      guard let region = mapItem.addressRepresentations?.region else {
//        print("no region")
//        throw SourceError.cityState("no region")
//      }
//      guard region == "US" else {
//        print("bad region")
//        throw SourceError.cityState("bad region")
//      }
      await handle(location: mapItem.location)
    } catch {
      print("cityState=\(cityState)")
      print(error.localizedDescription)
      continuation.yield(.badInput)
    }
  }

  func searchCurrentLocation() async {
    print("ljw \(Date()) \(#file):\(#function):\(#line)")
    continuation.yield(.loading(nil, []))
    await locationManager.start(maxCount: 1)
  }
}
