//
//  ExplorerViewModel.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/31/25.
//

import Foundation
import FactoryKit
import MapKit
import os
import SwiftUI

@MainActor
@Observable
class ExplorerViewModel {
  struct Activity: Hashable, Identifiable {
    let id = UUID()
    let address: String
    let category: String
    let city: String
    let description: String
    let distance: Double
    let imageName: String
    let name: String
    let rating: Double
    let reviews: Int
    let somethingInteresting: String
    let state: String
  }

  @ObservationIgnored
  @Injected(\.explorerSource) var source: ExplorerSource

  var activities = [Activity]()
  private(set) var errorDescription = ""
  private(set) var errorRecoverySuggestion = ""
  var haveError = false
  private(set) var loading = false
  private let logger = Logger(subsystem: "com.moofus.explorer", category: "ddd")
  private(set) var mkMapItem: MKMapItem?
  private var addressToLocationCache = [String: CLLocation]()

  init() {
    print("ljw \(Date()) \(#file):\(#function):\(#line)")
    Task { await handleSource() }
  }
}

// MARK: - Private Methods
extension ExplorerViewModel {

  // Returns the coordinate of the most relevant result
  private func getDistance(from activity: AIManager.Activity) async throws -> Double {
    let activityLocation: CLLocation
    if let addressToLocation = addressToLocationCache[activity.address] {
      activityLocation = addressToLocation
    } else {
      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = activity.address
      request.resultTypes = .address
      let search = MKLocalSearch(request: request)
      let response = try await search.start()
      guard let coordinate = response.mapItems.first?.placemark.coordinate else {
        return activity.distance
      }
      activityLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      addressToLocationCache[activity.address] = activityLocation
    }
    let locationToSearch = await source.locationToSearch
    let meters = activityLocation.distance(from: locationToSearch)
    let distanceInMeters = Measurement(value: meters, unit: UnitLength.meters)
    let distanceInMiles = distanceInMeters.converted(to: UnitLength.miles)
    return distanceInMiles.value
  }

  private func handleArchitecture(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("Street") {
      return ["building.columns.fill", "road.lanes.curved.right"]
    }
    fatalError()
  }

  private func handleArt(_ activity: AIManager.Activity) -> [String] {
    if activity.name.contains("Museum") {
      return ["building.columns.fill", "photo.artframe"]
    }
    fatalError()
  }

  private func handleArts(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("NightLife") {
      return handleArtsNightLife(activity)
    }
    fatalError()
  }

  private func handleArtsNightLife(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("murals") {
      return ["photo.fill", "figure.dance.circle.fill"]
    }
    fatalError()
  }

  private func handleCultural(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("Chinatown") {
      return ["chineseyuanrenminbisign.circle.fill", "storefront.fill", "fork.knife"]
    }
    if activity.description.contains("ferry") {
      return ["ferry.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleDriving(_ activity: AIManager.Activity) -> [String] {
    fatalError()
  }

  private func handleFood(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("Shopping") {
      return ["fork.knife", "storefront.fill"]
    }
    fatalError()
  }

  private func handleHistory(_ activity: AIManager.Activity) -> [String] {
    if activity.name.contains("Alcatraz") {
      return ["ferry.fill", "figure.walk"]
    }
    if activity.name.contains("Cable Cars") {
      return ["cablecar.fill"]
    }
    if activity.category.contains("Culture") {
      return handleHistoryCulture(activity)
    }
    if activity.category.contains("Landmark") {
      return handleHistorLandmark(activity)
    }
    fatalError()
  }

  private func handleIconic(_ activity: AIManager.Activity) -> [String] {
    if activity.name.contains("Street") {
      return ["road.lanes.curved.right"]
    }
    fatalError()
  }

  private func handleHistoryCulture(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("Walk") {
      return ["building.2.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleHistorLandmark(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["building.2.fill", "binoculars.fill"]
    }
    fatalError()
  }

  private func handleHiking(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["figure.hiking.circle.fill", "binoculars.fill"]
    }
    fatalError()
  }

  private func handleLandmarks(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["binoculars.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleLandmarksWalk(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["building.2.fill", "figure.walk", "binoculars.fill"]
    }
    fatalError()
  }

  private func handleMuseum(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("science") {
      return ["building.columns.fill", "atom"]
    }
    fatalError()
  }

  private func handleNature(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("Gardens") {
      return ["leaf.fill", "figure.walk"]
    }
    if activity.category.contains("Hike") {
      return ["leaf.fill", "figure.hiking.circle.fill"]
    }
    if activity.description.contains("museums") {
      return ["leaf.fill", "building.2.fill", "figure.walk"]
    }
    if activity.category.contains("Park") {
      return handleNaturePark(activity)
    }
    if activity.category.contains("Walk") {
      return ["leaf.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleNaturePark(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("museums") {
      return ["leaf.fill", "building.2.fill", "figure.walk"]
    }
    if activity.description.contains("walking") {
      return ["leaf.fill", "figure.walk", ]
    }
    fatalError()
  }

  private func handleOutdoor(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("Recreation") {
      return ["mountain.2.fill", "figure.walk"]
    }
    if activity.description.contains("Stroll") ||
        activity.description.contains("walking") ||
        activity.description.contains("Walk") {
      return handleOutdoorWalk(activity)
    }
    if activity.description.contains("Hike") {
      return handleOutdoorHike(activity)
    }
    if activity.description.contains("views") {
      return handleOutdoorViews(activity)
    }
    fatalError()
  }

  private func handleOutdoorHike(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["figure.hiking.circle.fill", "binoculars.fill"]
    }
    fatalError()
  }

  private func handleOutdoorViews(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("trails") {
      return ["figure.hiking.circle.fill", "binoculars.fill"]
    }
    fatalError()
  }

  private func handleOutdoorWalk(_ activity: AIManager.Activity) -> [String] {
     if activity.description.contains("bike") || activity.description.contains("biking") {
      return handleOutdoorWalkBike(activity)
    }
    if activity.description.contains("views") {
      return handleOutdoorWalkViews(activity)
    }
    fatalError()
  }

  private func handleOutdoorWalkBike(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["figure.walk", "bicycle", "binoculars.fill"] // bicycle.circle.fill
    }
    fatalError()
  }

  private func handleOutdoorWalkViews(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["figure.walk", "binoculars.fill"]
    }
    fatalError()
  }

  private func handlePark(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("gardens") {
      return handleParkGardens(activity)
    }
    if activity.description.contains("museums") {
      return handleParkMuseums(activity)
    }
    fatalError()
  }

  private func handleParkGardens(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("museums") {
      return ["leaf.fill", "building.2.fill"]
    }
    fatalError()
  }

  private func handleParkMuseums(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["leaf.fill", "building.2.fill", "binoculars.fill"]
    }
    fatalError()
  }

  private func handlePhotography(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("Drive") {
      return ["photo.fill", "car.fill"] // photo
    }
    fatalError()
  }

  private func handleScenic(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("Drive") {
      return ["binoculars.fill", "car.fill"]
    }
    if activity.description.contains("views") {
      return ["binoculars.fill", "figure.walk"]
    }
    if activity.category.contains("Walk") {
      return ["binoculars.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleScience(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("Education") {
      return ["atom", "graduationcap.fill"]
    }
    if activity.category.contains("Learning") {
      return ["atom", "book.fill"]
    }
    if activity.category.contains("Museum") {
      return ["atom", "building.columns.fill"]
    }
    fatalError()
  }

  private func handleShopping(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("Dining") {
      return ["storefront.fill", "fork.knife"]
    }
    fatalError()
  }

  private func handleSightseeing(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("ferry") {
      return ["binoculars.fill", "ferry.fill"]
    }
    if activity.description.contains("Stroll") || activity.description.contains("walk") || activity.category.contains("Walk") {
      return handleSightseeingWalk(activity)
    }
    if activity.description.contains("views") {
      return ["binoculars.fill"]
    }
    if activity.description.contains("bridge") {
      return ["binoculars.fill"]
    }
    fatalError()
  }

  private func handleSightseeingWalk(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("bike") {
      return ["binoculars.fill", "figure.walk", "bicycle"] // bicycle.circle.fill
    }
    if activity.description.contains("Drive") {
      return ["binoculars.fill", "figure.walk", "car.fill"] // bicycle.circle.fill
    }
    if activity.description.contains("views") {
      return ["binoculars.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleTour(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("ferry") {
      return ["ferry.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleTransportation(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("cable car") {
      return ["cablecar.fill"]
    }
    fatalError()
  }

  private func handleWalk(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return handleWalkViews(activity)
    }
    fatalError()
  }

  private func handleWalkViews(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("biking") {
      return ["figure.walk", "binoculars.fill", "bicycle"]
    }
    fatalError()
  }

  private func imageNames(from activity: AIManager.Activity) -> [String] {
    print("------------------------------")
    print(activity)
    if activity.category.contains("Architecture") {
      return handleArchitecture(activity)
    }
    if activity.category.contains("Art") {
      return handleArt(activity)
    }
    if activity.category.contains("Arts") {
      return handleArts(activity)
    }
    if activity.category.contains("Cultural") || activity.category.contains("Culture") {
      return handleCultural(activity)
    }
    if activity.category.contains("Driving") {
      return handleDriving(activity)
    }
    if activity.category.contains("Food") {
      return handleFood(activity)
    }
    if activity.category.contains("Hiking") {
      return handleHiking(activity)
    }
    if activity.category.contains("Histor") {
      return handleHistory(activity)
    }
    if activity.category.contains("History") {
      return handleHistory(activity)
    }
    if activity.category.contains("Iconic") {
      return handleIconic(activity)
    }
    if activity.category.contains("Landmarks") {
      return handleLandmarks(activity)
    }
    if activity.category.contains("Museum") {
      return handleMuseum(activity)
    }
    if activity.category.contains("Nature") {
      return handleNature(activity)
    }
    if activity.category.contains("Outdoor") {
      return handleOutdoor(activity)
    }
    if activity.category.contains("Park") {
      return handlePark(activity)
    }
    if activity.category.contains("Public Transit") {
      return handleTransportation(activity)
    }
    if activity.category.contains("Photography") {
      return handlePhotography(activity)
    }
    if activity.category.contains("Scenic") {
      return handleScenic(activity)
    }
    if activity.category.contains("Science") {
      return handleScience(activity)
    }
    if activity.category.contains("Shopping") {
      return handleShopping(activity)
    }
    if activity.category.contains("Sightseeing") {
      return handleSightseeing(activity)
    }
    if activity.category.contains("Tour") {
      return handleTour(activity)
    }
    if activity.category.contains("Transportation") {
      return handleTransportation(activity)
    }
    if activity.category.contains("Walk") {
      return handleWalk(activity)
    }
    fatalError()
  }

//  private func imageName(from category: String) -> String {
//    return switch category {
//      // Culture
//      //Discover the largest Chinatown outside of Asia, filled with shops, restaurants, and cultural landmarks.
//      //Explore one of the oldest and largest Chinatowns in North America.
//      //Chinatown is famous for its vibrant street life, delicious"
//    case "Culture/History": "chineseyuanrenminbisign.circle.fill" // storefront.fill" "fork.knife" cart.fill
//
//      //Explore the vibrant neighborhoods filled with shops, restaurants, and cultural landmarks.
//      //Chinatown San Francisco's Chinatown is one of the oldest and largest Chinatowns in North America."
//    case "Cultural Experience": "chineseyuanrenminbisign.circle.fill" // storefront.fill" "fork.knife" fork.knife.circle.fill cart.fill
//
//      //Explore the cultural hub known for the 1960s counterculture movement.
//    case "History/Culture": "house.and.flag.fill"
//
//      //Former federal prison known for its escape attempts and cinematic history.
//    case "History & Culture": "lock.fill"
//
//      //Haight-Ashbury was the epicenter of the 1960s counterculture movement, with its iconic red-bricked streets and historic sites like the Avalon Ballroom.
//    case "History/Music": "house.and.flag.fill" // "music.note.house.fill"
//      //Explore the historic district known as the birthplace of the 1960s counterculture movement, filled with vintage shops and cafes.
//    case "Music and History": "music.note.house.fill" // music.mic
//
//
//      // Culture & Arts
//      //A leading museum featuring works by modern and contemporary artists.
//    case "Art": "paintpalette.fill" // rotate building.columns photo.artframe
//      //Explore this vibrant neighborhood known for its eclectic art scene, murals, and diverse dining options.
//      //Visit the Mission District The Mission District is home to one of the largest murals
//    case "Arts/Culture": "paintpalette.fill" // rotate building.columns photo.artframe
//
//      //Explore vibrant murals, eclectic shops, and diverse dining options in this lively neighborhood."
//    case "Art & Cuisine": "paintpalette.fill" // rotate "fork.knife" fork.knife.circle.fill
//
//      //Discover street art, unique shops, and vibrant cultural events in this eclectic neighborhood.
//    case "Arts & Culture": "paintpalette.fill" // rotate storefront.fill
//      //Discover the oldest and largest Chinatown in North America, filled with unique shops and authentic dining.
//    case "Culture & Cuisine", "Culture and Cuisine": "chineseyuanrenminbisign.circle.fill" // storefront.fill" "fork.knife" cart.fill
//
//      //Take a ferry to Alcatraz Island to explore the former federal prison known for its infamous inmates.
//      //Alcatraz Island Tour Alcatraz is one of the most photographed islands in the world and offers a unique glimpse into America's criminal history.
//    case "Historical": "ferry.fill"
//
//      //Walk through the historic district known for its role in the 1960s counterculture movement, with vintage shops and cafes.
//    case "Historical & Cultural": "bag.fill" // rotate "fork.knife", "figure.walk"
//      //A preserved maritime area with historic ships and exhibits.
//    case "Maritime History": "sailboat.fill" // rotate
//      //An interactive science museum perfect for families, featuring hands-on exhibits and engaging displays.
//    case "Museum": "building.columns.fill" // rotate "paintpalette.fill"
//
//      //Take a ferry to explore the historic former prison known for its intriguing past.
//    case "Historical Tour": "ferry.fill" // ljw switch "figure.walk" "house.and.flag.fill"
//
//      // Culture & Arts
//      //Explore this eclectic neighborhood known for its murals, cafes, and vibrant arts scene.
//    case "Arts and Culture": "paintpalette.fill" // rotate "building.2.fill"
//
//      //    // Discover vibrant murals, eclectic shops, and a thriving food scene.
//      //    case "Art and Cuisine": "fork.knife"
//      //A vibrant neighborhood with a rich Chinese cultural heritage, famous for its food and shops."
//    case "Cultural District": "fork.knife" // rotate storefront.fill
//
//
//      // Family Activities
//      //Famous for its steep, winding road, it's a must-see for photography enthusiasts
//    case "Architecture and Travel": "binoculars.fill" // rotate "camera.viewfinder", car.fill
//      //Enjoy serene walking paths surrounded by beautiful native plants and gardens.
//      //Take a ferry or boat tour to explore this charming town across the Golden Gate Bridge.
//    case "Boat Tour": "ferry.fill"
//    case "Botanical Garden": "leaf.fill" // rotate "figure.walk.motion"
//      //A must-see suspension bridge offering breathtaking views.
//    case "Iconic Landmark": "camera.viewfinder" // rotate "binoculars.fill"
//
//    //Experience a classic San Francisco ride on one of the iconic cable cars."
//    case "City Tour": "cablecar.fill"
//
//      //Take a ferry to Alcatraz Island to explore the historic former prison known for its infamous inmates and intriguing history.
//      //Tour Alcatraz Island Alcatraz is one of the most famous and least toured prisons in the world.
//    case "History": "ferry.fill" // "binoculars.fill" "figure.walk"
//
//      //Stroll across the world-famous suspension bridge with breathtaking views.
//      //Walk down this famous crooked street with steep, winding turns.
//    case "Iconic Views": "binoculars.fill" // rotate "camera.viewfinder"
//
//    case "Landmark": "figure.walk" // rotate
//
//      //Iconic suspension bridge offering stunning views of the bay and city.
//      //Walk Across the Golden Gate Bridge The bridge is known for its Art Deco International
//    case "Landmark Views": "binoculars.fill" // "figure.walk" "camera.viewfinder"
//
//      //Park is a large urban park in San Francisco, known for its beautiful gardens, museums, and cultural institutions.
//    case "Park Golden Gate": "tree.fill"
//      //Visit Coit Tower for panoramic views of San Francisco and its Golden Gate Bridge.
//    case "Scenic Viewpoint": "camera.viewfinder" // rotate "binoculars.fill"
//      //Explore the iconic pier, enjoy fresh seafood, and watch sea lions lounging on the docks.
//    case "Seafood Dining": "fork.knife.circle.fill" // fork.knife
//      //Visit this interactive science museum with hands-on exhibits and engaging displays."
//    case "Science/Education": "atom"
//      //Engage with interactive exhibits and hands-on science and technology displays.
//    case "Science & Education": "atom"
//
//    //Interactive museum focusing on science and human perception.
//    case "Science/Exhibit": "atom" // "building.2.fill"
//
//
//      //Engage with interactive exhibits and hands-on science displays perfect for all ages.
//    case "Science Museum": "atom" // rotate
//      //Enjoy stunning views of the Golden Gate Bridge and the bay while walking or biking across this iconic structure.
//    case "Walking Tour": "figure.walk" // rotate bicycle "camera.viewfinder" // "binoculars.fill"
//      //    //Engage with interactive exhibits that explore science, art, and human perception.
//      //Enjoy scenic views of the San Francisco Bay and Alcatraz.
//    case "Water Activities": "binoculars.fill" // rotate camera.viewfinder
//
//      //    case "Science and Education", "Science & Education": "atom"
//      //Explore this lively waterfront area known for its seafood, shops, and sea lions lounging on Pier 39.
//    case "Shopping": "storefront.fill" // rotate cart.fill
//
//
//      // Food & Dining
//      //Explore the vibrant waterfront with seafood restaurants and shops."
//    case "Dining and Shopping": "fork.knife.circle.fill" // fork.knife "storefront.fill"
//
//
//      // Outdoor & Nature
//      //Enjoy a scenic hike with breathtaking views of the Pacific Ocean and the city skyline.
//    case "Hiking": "figure.hiking.circle.fill" // rotate tree.fill mountains.2.fill
//      //Hike through a lush redwood forest, a natural wonder unlike any other.
//
//    case "Nature and Hiking": "figure.hiking.circle.fill" // rotate tree.fill
//      //Stroll along the scenic paths with stunning views of the bridge and the bay.
//
//      //Discover towering redwoods and lush forest trails in this serene national monument.
//      //Muir Woods National Monument Muir Woods is home to some of the tallest
//    case "Nature Preserve": "figure.hiking.circle.fill" // rotate tree.fill
//
//    case "Outdoor Walk": "figure.hiking.circle.fill" // rotate mountains.2.fill "figure.walk"
//
//      //Hike through a lush redwood forest with towering trees and breathtaking views.
//    case "Nature & Hiking": "figure.hiking.circle.fill" // rotate tree.fill
//
//      //This expansive area offers stunning coastal views, hiking trails, and scenic vistas along the Pacific Ocean.
//      //Hike up to Twin Peaks for panoramic views of the city and surrounding areas.    case "Outdoor Activities": "figure.hiking.circle.fill" // mountains.2.fill "tent.2.fill"
//    case "Nature and Views": "figure.hiking.circle.fill" // "binoculars.fill"
//
//      //Visit the historic observation tower for panoramic views of the city.
//      //Coit Tower Coit Tower is famous for its murals painted by local artists, including a famous depiction of Lady Justice.
//    case "Sightseeing": "binoculars.fill"
//
//
//
//      //Visit this historic observation tower for panoramic views of the city and Golden Gate Bridge.
//    case "Historical Landmark": "house.and.flag.fill" // ljw switch "figure.walk"
//      //Visit this Beaux-Arts structure that was originally built for the 1915 Panama-Pacific International Exposition.
//    case "Historic Sites": "house.and.flag.fill" // ljw switch "figure.walk"
//
//      // Services & Other
//      //Experience the historic charm of San Francisco by riding one of its iconic cable cars.
//    case "Iconic Ride": "cablecar.fill"
//
//      //    //Experience the historic charm of San Francisco by riding one of its iconic cable cars.
//    case "Public Transit","Public Transport": "cablecar.fill"
//
//      // Shopping & Fashion
//      //Explore this vibrant waterfront area filled with shops, restaurants, and attractions like Pier 39 and sea lions.
//    case "Shopping and Dining": "storefront.fill" // rotate "fork.knife.circle.fill"  "bag.fill"
//
//      //A bustling waterfront area with seafood restaurants, shops, and attractions like Pier 39.
//    case "Shopping & Dining": "fork.knife.circle.fill" // rotate "storefront.fill", "bag.fill" // ljw rotate dinning
//      //    //District A bustling area filled with shops, restaurants, and attractions like Pier 39 and the sea lions.
//      //Explore this vibrant waterfront area with shops, restaurants, and street performers.
//    case "Shopping/Dining": "fork.knife" // rotate storefront.fill
//
//      //    case "Shopping and Dining", "Shopping & Dining": "bag.fill" // ljw rotate dinning
//      //    case "Shopping and Dining District", "Shopping & Dining District":  "bag.fill" // ljw rotate dinning
//
//
//
//      ////////////////////////////////////////////////////////////////////
//      // Culture & Arts
//      //    case "Art Gallery", "Galleries": "photo.fill.on.rectangle.fill" // frame.3.fill
//      //    case "Concert Halls": "music.note.house.fill"
//      //    case "Architecture", "Geographical Landmark", "History and Culture", "Landmark", "Scenic": "mappin.circle.fill"
//      //    case "Museums": "building.2.fill" // rotate "paintpalette.fill"
//    case "Performing Arts": "theatermasks"
//    case "Theaters", "Theater": "theatermasks.fill"
//
//      // Cultural
//    case "Culture", "Cultural Neighborhood": "globe"
//    case "Cultural", "Cultural Landmark", "Landmarks": "building.columns.fill"
//    case "Cultural and Arts", "Cultural & Arts": "paintpalette.fill" // rotate "building.2.fill"
//    case "Cultural Exploration": "fork.knife.circle.fill" // rotate "building.columns.fill"
//    case "Culture and Heritage", "Culture & Heritage": "map.fill" //  map.fill + building.2.fill or theatermasks + figure.walk
//    case "Cultural Tour": "map.fill" //  map.fill + building.2.fill or theatermasks + figure.walk
//    case "Culture/Food", "Food & Culture": "fork.knife"
//    case "Historic Landmark", "Historic Site", "Historical Site", "Island": "house.and.flag.fill"
//    case "Historic District", "Iconic Street": "house.and.flag.fill" // ljw switch "figure.walk"
//
//      // Entertainment
//    case "Entertainment": "popcorn.fill"
//
//      // Family Activities
//    case "Animal Park": "pawprint.fill"
//    case "Amusement Parks", "Recreation": "figure.walk" // ferris.wheel.fill
//    case "Beach Day": "beach.umbrella.fill"
//    case "Historic Tour", "Island Tour", "Tour": "figure.walk"
//    case "Science", "Science and Innovation", "Science & Innovation", "Science and Learning", "Science & Learning": "atom"
//    case "Sightseeing Walk", "Walk": "figure.walk.motion"
//    case "Zoos", "Zoo": "pawprint.fill"
//
//      // Food & Dining
//    case "Food", "Food Tour", "Restaurants": "fork.knife.circle.fill" // fork.knife
//
//      // Outdoor & Nature
//    case "Beaches", "Beach": "beach.umbrella.fill" // water.waves.and.sun.fill
//    case "Biking": "bicycle"
//    case "Boating & Dining": "sailboat.fill"
//    case "Gardens", "Garden": "leaf.fill"
//    case "Nature Reserve", "Outdoor": "figure.hiking.circle.fill" // mountains.2.fill
//    case "Nature", "Nature and Parks", "Nature & Parks", "Nature and Recreation", "Nature & Recreation": "tree.fill"
//    case "Parks", "Park", "Zoological Park": "tree.fill"
//    case "Nature Tour", "Nature Walk": "figure.walk.motion"
//    case "Outdoor Adventure", "Outdoor Activity", "Outdoor Recreation": "figure.hiking.circle.fill" // mountains.2.fill
//    case "Scenic Walk": "figure.walk"
//    case "Scenic Views": "camera.viewfinder"
//    case "Viewpoint": "binoculars.fill"
//
//      // Services & Other
//    case "Scenic Drive": "car.fill"
//    case "Transportation": "car.fill"
//
//      // Shopping & Fashion
//    case "Markets", "Market": "carrot.fill"
//    case "Neighborhood": "bag.fill" // ljw rotate dinning
//
//
//
//      //////////////////////////////////////// ljw
//      // Food & Dining
//      //    case "Restaurants":
//      //       "fork.knife"
//      //    case "Cafes":
//      //       "cup.and.saucer.fill"
//      //    case "Bars":
//      //       "wineglass.fill"
//      //    case "Bakeries":
//      //       "birthday.cake"
//      //    case "Food Trucks":
//      //       "truck.box.fill" // caravan.fill
//      //    case "Pizza":
//      //       "fork.knife"
//      //
//      //      // Outdoor & Nature
//      //    case "Camping":
//      //       "tent.2.fill"
//      //
//      //      // Culture & Arts
//      //    case "Concert Halls":
//      //       "music.note.house.fill"
//      //    case "Libraries":
//      //       "books.vertical.fill"
//      //    case "Art Exhibits":
//      //       "paintpalette.fill"
//      //
//      //      // Entertainment
//      //    case "Entertainment":
//      //       "popcorn.fill"
//      //    case "Movies":
//      //       "movieclapper.fill" // film.stack or film.fill
//      //    case "Comedy Clubs":
//      //       "person.wave.2.fill"
//      //    case "Theme Parks":
//      //       "ticket.fill"
//      //    case "Bowling":
//      //       "figure.bowling.circle.fill" // or circle.circle.fill
//      //    case "Arcade Games":
//      //       "gamecontroller.fill"
//      //    case "Escape Rooms":
//      //       "lock.fill"
//      //    case "Karaoke":
//      //       "music.mic"
//      //
//      //      // Sports & Recreation
//      //    case "Gyms":
//      //       "dumbbell.fill"
//      //    case "Yoga":
//      //       "figure.yoga.circle.fill" // moon.yoga
//      //    case "Swimming":
//      //       "figure.pool.swim"
//      //    case "Sports":
//      //       "figure.basketball"
//      //    case "Tennis":
//      //       "figure.tennis.circle.fill" // tennis.racket
//      //    case "Golf":
//      //       "figure.golf" // flag.circle.fill
//      //    case "Skateparks":
//      //       "skateboard.fill"
//      //
//      //      // Shopping & Fashion
//      //    case "Shopping":
//      //       "bag.fill"
//      //    case "Malls":
//      //       "building.2.fill"
//      //    case "Boutiques":
//      //       "handbag.fill"
//      //    case "Bookstores":
//      //       "books.vertical.fill"
//      //    case "Antique Shops":
//      //       "hourglass"
//      //
//      //      // Nightlife
//      //    case "Nightlife":
//      //       "moon.stars.fill"
//      //    case "Clubs":
//      //       "music.note.list"
//      //    case "Lounges":
//      //       "sofa.fill"
//      //    case "Pubs":
//      //       "mug.fill" // beer.mug.fill
//      //    case "Dance Clubs":
//      //       "figure.socialdance.circle.fill" // figure.dance
//      //      // Wellness & Health
//      //    case "Spas":
//      //       "sparkles"
//      //    case "Massage":
//      //       "carseat.right.massage.fill" // hand.massaged
//      //    case "Beauty Salons":
//      //       "comb.fill"
//      //    case "Health Clinics":
//      //       "cross.fill"
//      //
//      //      // Family Activities
//      //    case "Playgrounds":
//      //       "figure.play"
//      //    case "Aquariums":
//      //       "fish.fill"
//      //    case "Children's Activities":
//      //       "figure.child"
//      //
//      //      // Education
//      //    case "Schools":
//      //       "long.text.page.and.pencil" // building.with.badge.and.wrench.fill
//      //    case "Colleges":
//      //       "graduationcap.fill"
//      //    case "Workshops":
//      //       "hammer.circle.fill"
//      //    case "Classes":
//      //       "book.fill"
//      //
//      //      // Services & Other
//      //    case "Hotels":
//      //       "building.fill"
//      //    case "Photography":
//      //       "camera.fill"
//      //    case "Events":
//      //       "calendar.circle.fill"
//      //    case "Tours":
//      //       "binoculars.fill"
//      //    case "Adventure":
//      //       "airplane"
//    default:
//      fatalError("category=\(category)") // ljw
//      // "mappin.circle.fill"
//    }
//  }

  private func convert(activities: [AIManager.Activity]) async -> [Activity] {
    var result = [Activity]()
    for activity in activities {
      let distance: Double
      do {
        distance = try await getDistance(from: activity)
      } catch {
        logger.error("\(error.localizedDescription)")
        //        assertionFailure() // ljw
        distance = activity.distance
      }
      let imageName = imageNames(from: activity).first!

      result.append(
        Activity(
          address: activity.address,
          category: activity.category,
          city: activity.city,
          description: activity.description,
          distance: distance,
          imageName: imageName,
          name: activity.name,
          rating: 3.9,
          reviews: 45,
          somethingInteresting: activity.somethingInteresting,
          state: activity.state
        )
      )
    }
    return result
  }

  private func handleSource() async {
    for await state in source.stream {
      loading = false

      switch state {
      case .error(let error):
        if case let .location(description, recoverySuggestion) = error {
          errorDescription = description ?? "Error"
          errorRecoverySuggestion = recoverySuggestion ?? "Try again later."
        } else {
          // unknown error
          print("ljw \(Date()) \(#file):\(#function):\(#line)")
          errorDescription = error.localizedDescription
          errorRecoverySuggestion = ""
        }
        haveError = true
      case .initial:
        self.mkMapItem = nil
      case .loaded(let activities):
        //        print(activities)
        print("loaded")
        self.activities = await convert(activities: activities)
        self.mkMapItem = nil

        print("loaded activities count=\(self.activities.count) \(activities.count)")

      case .loading(let mkMapItem):
        print("loading")
        self.mkMapItem = mkMapItem
        loading = true
      }
    }
  }
}
