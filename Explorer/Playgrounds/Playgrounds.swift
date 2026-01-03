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
import CoreLocation
import Foundation

#Playground {
//      let instructions = """
//          Your job is to find activities to do and places to go in Oakland, CA.
//
//          Always include a short description, and something interesting about the activity or place.
//          """
//
//  let aiManager = AIManager(instructions: instructions)
//  do {
//    let items = try await aiManager.getItems(cityState: "Oakland, CA")
//    print("items=")
//    print(items)
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
