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
    case initial
    case error(SourceError)
  }

  @Injected(\.aiManager) var aiManager: AIManager
  @Injected(\.locationManager) var locationManager: LocationManager

  private let continuation: AsyncStream<State>.Continuation
  let stream: AsyncStream<State>

  init() {
    print("ljw \(Date()) \(#file):\(#function):\(#line)")
    (stream, continuation) = AsyncStream.makeStream(of: State.self)
    Task {
      await handleLocationManager()
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
  
  /// Given the CLLocation get the city and state
  /// - Parameter location: the location used to get the city and state
  /// - Returns: the "city, state"
  private func handle(location: CLLocation) async {
    if let request = MKReverseGeocodingRequest(location: location) {
      do {
        print("isLoading=\(request.isLoading)")
        let mapItems = try await request.mapItems
        print("isLoading=\(request.isLoading)")
        print("mapItems.count=\(mapItems.count)")
        if let item = mapItems.first {
          print(item)
          print("city=\(item.addressRepresentations?.cityName ?? "home")")
          print("cityWithContext=\(item.addressRepresentations?.cityWithContext ?? "City, State")")
          print("regionName=\(item.addressRepresentations?.regionName ?? "Country")")
          print("region=\(item.addressRepresentations?.region ?? "Country")")
          if let cityState = item.addressRepresentations?.cityWithContext {
            do {
              let instructions = """
                              Your job is to find activities to do and places to go in Oakland California.
                              
                              Always include a short description, and something interesting about the activity or place.
                              """

              let list = try await aiManager.getItems()
            } catch {
              print(error)
              if let error = error as? AIManager.Error {
                let error = SourceError.location(
                  description: error.errorDescription,
                  recoverySuggestion: error.recoverySuggestion
                )
                continuation.yield(.error(error))
              }
              else {
                assertionFailure("unknown error=\(error)")
                continuation.yield(.error(.unknown(error.localizedDescription)))
              }
            }
          }
        }
      } catch {
        print("Error MKReverseGeocodingRequest: \(error)")
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
  /*private*/ func getCityState(from address: String) async throws -> String {
    // Create the request with the address string
    // example addressString "Oakland, CA", to verify that "Oakland, CA" exist
    let request = MKGeocodingRequest(addressString: address)
    let usRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Approx center of US
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 60) // Wide span for US
    )
    request?.region = usRegion

    // Execute the request
    let mapItem = (try await request?.mapItems.first)!

    // Extract the coordinate from the first result
    print(mapItem)
    print("city=\(mapItem.addressRepresentations?.cityName ?? "home")")
    print("cityWithContext=\(mapItem.addressRepresentations?.cityWithContext ?? "City, State")")
    print("regionName=\(mapItem.addressRepresentations?.regionName ?? "Country")")
    print("region=\(mapItem.addressRepresentations?.region ?? "Country")")
    guard let region = mapItem.addressRepresentations?.region else {
      print("no region")
      throw SourceError.cityState("no region")
    }
    guard region == "US" else {
      print("bad region")
      throw SourceError.cityState("bad region")
    }
    return "\(mapItem.addressRepresentations?.cityWithContext ?? "City, State")"

  }

  func searchCurrentLocation() async {
    print("ljw \(Date()) \(#file):\(#function):\(#line)")
    await locationManager.start(maxCount: 1)
  }
}
/*
 <MKMapItem: 0x116771f40> {
 address = "6825 Elverton Dr, Oakland, CA  94611, United States";
 isCurrentLocation = 0;
 name = "6825 Elverton Dr";
 placemark = "6825 Elverton Dr, 6825 Elverton Dr, Oakland, CA  94611, United States @ <+37.84662530,-122.20234210> +/- 0.00m, region CLCircularRegion (identifier:'<+37.84662530,-122.20234210> radius 70.59', center:<+37.84662530,-122.20234210>, radius:70.59m)";
 timeZone = "America/Los_Angeles (PST) offset -28800";
 }
 item.city=Oakland
 item.cityWithContext=Optional("Oakland, CA")
 item.regionName=Optional("United States")
 item.region=Optional(US)

 */

