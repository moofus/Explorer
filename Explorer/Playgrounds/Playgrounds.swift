//
//  Playgrounds.swift
//  Explorer
//
//  Created by Lamar Williams III on 1/2/26.
//

#if DEBUG
import Foundation
import FoundationModels
import Playgrounds
import MapKit

#Playground {

//  let request = MKLocalSearch.Request()
//  request.naturalLanguageQuery = "6825 Elverton Drive, Oakland, CA"
//
//  // Limits the search to specific types if needed
//  request.resultTypes = .address
//
//  let search = MKLocalSearch(request: request)
//  let response = try await search.start()
//
//  // Returns the coordinate of the most relevant result
////  print(response.mapItems.first?.placemark.coordinate)
//  print(response.mapItems.first?.placemark.coordinate)



//  let request = MKGeocodingRequest(addressString: "6825 Elverton Drive, Oakland, CA")
//      let usRegion = MKCoordinateRegion( // use my location
// //       center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Approx center of US
  //        center: CLLocationCoordinate2D(latitude: 37.78583880, longitude: -122.20234210), // Union Square SF
  //        center: CLLocationCoordinate2D(latitude: 37.84663652, longitude: -122.20239821), // my home Oakland
//          span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 60) // Wide span for US
//      )
////      request?.region = usRegion
//
//      // Execute the request
//      let mapItem = (try await request?.mapItems.first)!
//  
//      // Extract the coordinate from the first result
//  print(mapItem.placemark.location)
//  print(mapItem)
  //    print("city=\(mapItem.addressRepresentations?.cityName ?? "home")")
  //    print("cityWithContext=\(mapItem.addressRepresentations?.cityWithContext ?? "City, State")")
  //    print("regionName=\(mapItem.addressRepresentations?.regionName ?? "Country")")
  //    print("region=\(mapItem.addressRepresentations?.region ?? "Country")")


  //  let aiManager = AIManager()
//  do {
//    try await aiManager.findActivities(cityState: "Oakland, CA")
//  } catch {
//    if let error = error as? AIManager.Error {
//      print("ljw error=\(error)")
//    } else {
//      print("unknown error")
//    }
//  }
//  let source = ExplorerSource()
//  Task {
//    do {
//      let cityState = try await source.getCityState(from: "99992")
//      print("cityState='\(cityState)'")
////      try await aiManager.getCoordinates(from: "junk, CA" )
//    } catch {
//      print("error=\(error)")
//    }
//  }


  //  let searchRequest = MKLocalSearch.Request()
  //  searchRequest.naturalLanguageQuery = "Starbucks near me"
  ////  searchRequest.naturalLanguageQuery = "94611"
  //  // Optional: Define a specific region to search within
  //  // searchRequest.region = mapView.region
  //
  //  Task {
  //    do {
  //      let response = try await MKLocalSearch(request: searchRequest).start()
  //      for item in response.mapItems {
  //        print("----------------------------------")
  //        print("Name: \(item.name ?? "")")
  //        print("Address.description: \(item.address?.description)")
  //        print("Address.fullAddress: \(item.address?.fullAddress)")
  //        print("Address.shortAddress: \(item.address?.shortAddress)")
  //        let coordinate = item.location.coordinate
  //        print("Location: \(coordinate.latitude), \(coordinate.longitude)")
  //      }
  //    } catch {
  //      print("Search failed: \(error.localizedDescription)")
  //    }
  //  }
  //  ----------------------------------
  //  Name: Starbucks
  //  Address.description: Optional("<MKAddress: 0x60000023a640> {\n    fullAddress = \"13808 E 14th St, San Leandro, CA  94578, United States\";\n    shortAddress = \"13808 E 14th St, San Leandro\";\n}")
  //  Address.fullAddress: Optional("13808 E 14th St, San Leandro, CA  94578, United States")
  //  Address.shortAddress: Optional("13808 E 14th St, San Leandro")
  //  Location: 37.7147697, -122.14176
  //  ----------------------------------


//  func determineCityStateExistence(city: String, state: String, completion: @escaping (Bool) -> Void) {
//      let geocoder = CLGeocoder()
//      let addressString = "\(city), \(state)"
//
//      geocoder.geocodeAddressString(addressString) { placemarks, error in
//          // Ensure UI updates are on the main thread if this is in a ViewController
//          DispatchQueue.main.async {
//              if let error = error {
//                  // Handle the error (e.g., network issues, service unavailable)
//                  print("Geocoding error: \(error.localizedDescription)")
//                  completion(false)
//                  return
//              }
//
//              // If placemarks array is not empty, it means a valid location was found.
//              if let placemarks = placemarks, !placemarks.isEmpty {
//                  // Optionally, you can perform extra checks to ensure the placemark
//                  // matches the *exact* city and state you are looking for,
//                  // as the geocoder might return a nearby, but slightly different, location.
//                  let firstPlacemark = placemarks[0]
//                  let foundCity = firstPlacemark.locality
//                  let foundState = firstPlacemark.administrativeArea // This is the state/province
//
//                  if foundCity == city && foundState == state {
//                     completion(true) // Exact match found
//                  } else {
//                     // A location was found, but the city/state combination might not be an exact match
//                     completion(false)
//                  }
//
//              } else {
//                  // No placemarks were found for the given address string.
//                  completion(false)
//              }
//          }
//      }
//  }

//  // How to use it:
//  determineCityStateExistence(city: "Piedmont", state: "CA") { exists in
//      if exists {
//          print("The city and state combination exists.")
//      } else {
//          print("The city and state combination does not exist or is invalid.")
//      }
//  }

}

#endif // DEBUG

