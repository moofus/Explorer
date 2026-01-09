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
  @Injected(\.appCoordinator) var appCoordinator: AppCoordinator
  @ObservationIgnored
  @Injected(\.explorerSource) var source: ExplorerSource

  var activities = [Activity]()
  private(set) var errorDescription = ""
  private(set) var errorRecoverySuggestion = ""
  var haveError = false
  private(set) var loading = false
  private let logger = Logger(subsystem: "com.moofus.explorer", category: "ddd")
  private(set) var mkMapItem: MKMapItem?
  private var addressToLocation = [String: CLLocation]()

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
    if let addressToLocation = addressToLocation[activity.address] {
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
      addressToLocation[activity.address] = activityLocation
    }
    let locationToSearch = await source.locationToSearch
    let meters = activityLocation.distance(from: locationToSearch)
    let distanceInMeters = Measurement(value: meters, unit: UnitLength.meters)
    let distanceInMiles = distanceInMeters.converted(to: UnitLength.miles)
    return distanceInMiles.value
  }

  private func imageName(from category: String) -> String {
    return switch category {
      // Culture
    //Discover the largest Chinatown outside of Asia, filled with shops, restaurants, and cultural landmarks.
    case "Cultural Experience": "storefront.fill" // rotate fork.knife.circle.fill

    //Walk through the historic district known for its role in the 1960s counterculture movement, with vintage shops and cafes.
    case "Historical & Cultural": "bag.fill" // rotate "fork.knife", "figure.walk"
    //A preserved maritime area with historic ships and exhibits.
    case "Maritime History": "sailboat.fill" // rotate

    //Take a ferry to explore the historic former prison known for its intriguing past.
    case "Historical Tour": "ferry.fill" // ljw switch "figure.walk" "house.and.flag.fill"

      // Culture & Arts
    //Explore this eclectic neighborhood known for its murals, cafes, and vibrant arts scene.
    case "Arts and Culture": "paintpalette.fill" // rotate "building.2.fill"

//    // Discover vibrant murals, eclectic shops, and a thriving food scene.
//    case "Art and Cuisine", "Art & Cuisine": "fork.knife"
    //A vibrant neighborhood with a rich Chinese cultural heritage, famous for its food and shops."
    case "Cultural District": "fork.knife" // rotate storefront.fill
//    //Experience the oldest and largest Chinatown in North America with its vibrant markets, temples, and diverse cuisine."
//    case "Culture and Cuisine", "Culture & Cuisine": "fork.knife" // rotate

      // Family Activities
    //Famous for its steep, winding road, it's a must-see for photography enthusiasts
    case "Architecture and Travel": "binoculars.fill" // rotate "camera.viewfinder", car.fill
    //Enjoy serene walking paths surrounded by beautiful native plants and gardens.
    case "Botanical Garden": "leaf.fill" // rotate "figure.walk.motion"
    //Visit this interactive science museum with hands-on exhibits and engaging displays."
    case "Science/Education": "atom"
    //Engage with interactive exhibits and hands-on science and technology displays.
    case "Science & Education": "atom"
    //Engage with interactive exhibits and hands-on science displays perfect for all ages.
    case "Science Museum": "atom" // rotate
    //Enjoy stunning views of the Golden Gate Bridge and the bay while walking or biking across this iconic structure.
    case "Walking Tour": "figure.walk.motion" // rotate bicycle
      //    //Engage with interactive exhibits that explore science, art, and human perception.
//    case "Science and Education", "Science & Education": "atom"
      //Explore this lively waterfront area known for its seafood, shops, and sea lions lounging on Pier 39.
      case "Shopping": "storefront.fill" // rotate cart.fill
//    //Stroll or bike across the iconic suspension bridge offering breathtaking views of the bay and city.
//    case "Iconic Views": "binoculars.fill" // rotate "camera.viewfinder"

      // Outdoor & Nature
    //Enjoy a scenic hike with breathtaking views of the Pacific Ocean and the city skyline.
    case "Hiking": "figure.hiking.circle.fill" // rotate tree.fill mountains.2.fill
    //Stroll along the scenic paths with stunning views of the bridge and the bay.
    case "Outdoor Walk": "figure.hiking.circle.fill" // rotate mountains.2.fill "figure.walk"

//    //Hike through a lush redwood forest with towering trees and breathtaking views.
//    case "Nature and Hiking", "Nature & Hiking": "figure.hiking.circle.fill" // rotate tree.fill


    //Visit this historic observation tower for panoramic views of the city and Golden Gate Bridge.
    case "Historical Landmark": "house.and.flag.fill" // ljw switch "figure.walk"
    //Visit this Beaux-Arts structure that was originally built for the 1915 Panama-Pacific International Exposition.
    case "Historic Sites": "house.and.flag.fill" // ljw switch "figure.walk"

      // Services & Other
//    //Experience the historic charm of San Francisco by riding one of its iconic cable cars.
//    case "Public Transit", "Public Transport": "bus.fill"

      // Shopping & Fashion
    //Explore this vibrant waterfront area filled with shops, restaurants, and attractions like Pier 39 and sea lions.
    case "Shopping and Dining": "storefront.fill" // rotate "fork.knife.circle.fill"  "bag.fill"

    //A bustling waterfront area with seafood restaurants, shops, and attractions like Pier 39.
    case "Shopping & Dining": "fork.knife.circle.fill" // rotate "storefront.fill", "bag.fill" // ljw rotate dinning
//    //District A bustling area filled with shops, restaurants, and attractions like Pier 39 and the sea lions.
//    case "Shopping/Dining", "Shopping and Dining", "Shopping & Dining": "bag.fill" // ljw rotate dinning
//    case "Shopping and Dining District", "Shopping & Dining District":  "bag.fill" // ljw rotate dinning



      ////////////////////////////////////////////////////////////////////
      // Culture & Arts

//    case "Art", "Arts & Culture": "paintpalette.fill" // rotate "building.2.fill"
    case "Art Gallery", "Galleries": "photo.fill.on.rectangle.fill" // frame.3.fill
    case "Concert Halls": "music.note.house.fill"
    case "Architecture", "Geographical Landmark", "History and Culture", "History & Culture", "Landmark", "Scenic": "mappin.circle.fill"
    case "Museum", "Museums": "building.2.fill" // rotate "paintpalette.fill"
    case "Performing Arts": "theatermasks"
    case "Theaters", "Theater": "theatermasks.fill"

      // Cultural
    case "Culture", "Cultural Experience", "Cultural Neighborhood": "globe"
    case "Cultural", "Cultural Landmark", "Landmarks": "building.columns.fill"
    case "Cultural and Arts", "Cultural & Arts": "paintpalette.fill" // rotate "building.2.fill"
    case "Cultural Exploration": "fork.knife.circle.fill" // rotate "building.columns.fill"
    case "Culture and Heritage", "Culture & Heritage": "map.fill" //  map.fill + building.2.fill or theatermasks + figure.walk
    case "Cultural Tour": "map.fill" //  map.fill + building.2.fill or theatermasks + figure.walk
    case "Culture/Food", "Food & Culture": "fork.knife"
    case "History", "Historic Landmark", "Historic Site", "Historical Site", "Island": "house.and.flag.fill"
    case "Historical", "Historic District", "Iconic Street": "house.and.flag.fill" // ljw switch "figure.walk"

      // Entertainment
    case "Entertainment": "popcorn.fill"

      // Family Activities
    case "Animal Park": "pawprint.fill"
    case "Amusement Parks", "Recreation": "figure.walk" // ferris.wheel.fill
    case "Beach Day": "beach.umbrella.fill"
    case "Historic Tour", "Island Tour", "Tour": "figure.walk"
    case "Science", "Science and Innovation", "Science & Innovation", "Science and Learning", "Science & Learning", "Science Museum": "atom"
    case "Sightseeing Walk", "Walk": "figure.walk.motion"
    case "Zoos", "Zoo": "pawprint.fill"

      // Food & Dining
    case "Food", "Food Tour", "Restaurants": "fork.knife.circle.fill" // fork.knife

      // Outdoor & Nature
    case "Beaches", "Beach": "beach.umbrella.fill" // water.waves.and.sun.fill
    case "Biking": "bicycle"
    case "Boating & Dining": "sailboat.fill"
    case "Gardens", "Garden": "leaf.fill"
    case "Nature Reserve", "Outdoor": "figure.hiking.circle.fill" // mountains.2.fill
    case "Nature", "Nature and Parks", "Nature & Parks", "Nature and Recreation", "Nature & Recreation": "tree.fill"
    case "Parks", "Park", "Zoological Park": "tree.fill"
    case "Nature Tour", "Nature Walk": "figure.walk.motion"
    case "Outdoor Adventure", "Outdoor Activity", "Outdoor Recreation": "figure.hiking.circle.fill" // mountains.2.fill
    case "Outdoor Walk", "Scenic Walk": "figure.walk"
    case "Scenic Views": "camera.viewfinder"
    case "Sightseeing": "bus.fill"
    case "Viewpoint": "binoculars.fill"

      // Services & Other
    case "Scenic Drive": "car.fill"
    case "Transportation": "car.fill"

      // Shopping & Fashion
    case "Markets", "Market": "carrot.fill"
    case "Neighborhood": "bag.fill" // ljw rotate dinning



      //////////////////////////////////////// ljw
      // Food & Dining
//    case "Restaurants":
//       "fork.knife"
//    case "Cafes":
//       "cup.and.saucer.fill"
//    case "Bars":
//       "wineglass.fill"
//    case "Bakeries":
//       "birthday.cake"
//    case "Food Trucks":
//       "truck.box.fill" // caravan.fill
//    case "Pizza":
//       "fork.knife"
//
//      // Outdoor & Nature
//    case "Camping":
//       "tent.2.fill"
//
//      // Culture & Arts
//    case "Concert Halls":
//       "music.note.house.fill"
//    case "Libraries":
//       "books.vertical.fill"
//    case "Art Exhibits":
//       "paintpalette.fill"
//
//      // Entertainment
//    case "Entertainment":
//       "popcorn.fill"
//    case "Movies":
//       "movieclapper.fill" // film.stack or film.fill
//    case "Comedy Clubs":
//       "person.wave.2.fill"
//    case "Theme Parks":
//       "ticket.fill"
//    case "Bowling":
//       "figure.bowling.circle.fill" // or circle.circle.fill
//    case "Arcade Games":
//       "gamecontroller.fill"
//    case "Escape Rooms":
//       "lock.fill"
//    case "Karaoke":
//       "music.mic"
//
//      // Sports & Recreation
//    case "Gyms":
//       "dumbbell.fill"
//    case "Yoga":
//       "figure.yoga.circle.fill" // moon.yoga
//    case "Swimming":
//       "figure.pool.swim"
//    case "Sports":
//       "figure.basketball"
//    case "Tennis":
//       "figure.tennis.circle.fill" // tennis.racket
//    case "Golf":
//       "figure.golf" // flag.circle.fill
//    case "Skateparks":
//       "skateboard.fill"
//
//      // Shopping & Fashion
//    case "Shopping":
//       "bag.fill"
//    case "Malls":
//       "building.2.fill"
//    case "Boutiques":
//       "handbag.fill"
//    case "Bookstores":
//       "books.vertical.fill"
//    case "Antique Shops":
//       "hourglass"
//
//      // Nightlife
//    case "Nightlife":
//       "moon.stars.fill"
//    case "Clubs":
//       "music.note.list"
//    case "Lounges":
//       "sofa.fill"
//    case "Pubs":
//       "mug.fill" // beer.mug.fill
//    case "Dance Clubs":
//       "figure.socialdance.circle.fill" // figure.dance
//      // Wellness & Health
//    case "Spas":
//       "sparkles"
//    case "Massage":
//       "carseat.right.massage.fill" // hand.massaged
//    case "Beauty Salons":
//       "comb.fill"
//    case "Health Clinics":
//       "cross.fill"
//
//      // Family Activities
//    case "Playgrounds":
//       "figure.play"
//    case "Aquariums":
//       "fish.fill"
//    case "Children's Activities":
//       "figure.child"
//
//      // Education
//    case "Schools":
//       "long.text.page.and.pencil" // building.with.badge.and.wrench.fill
//    case "Colleges":
//       "graduationcap.fill"
//    case "Workshops":
//       "hammer.circle.fill"
//    case "Classes":
//       "book.fill"
//
//      // Services & Other
//    case "Hotels":
//       "building.fill"
//    case "Photography":
//       "camera.fill"
//    case "Events":
//       "calendar.circle.fill"
//    case "Tours":
//       "binoculars.fill"
//    case "Adventure":
//       "airplane"
    default:
      fatalError("category=\(category)") // ljw
      // "mappin.circle.fill"
    }
  }

  private func convert(activities: [AIManager.Activity]) async -> [Activity] {
    var result = [Activity]()
    for activity in activities {
      print("category: ", activity.category, activity.description)
      let distance: Double
      do {
        distance = try await getDistance(from: activity)
      } catch {
        logger.error("\(error.localizedDescription)")
        assertionFailure() // ljw
        distance = activity.distance
      }
      let imageName = imageName(from: activity.category)

      /*
       // 3. Calculate the distance (returns meters as a Double)
       let distanceInMeters = location1.distance(from: location2)

       print("Distance: \(distanceInMeters) meters")
       print("Distance: \(distanceInMeters / 1000) kilometers")

       */
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
        break
      case .loaded(let activities):
//        print(activities)
        self.activities = await convert(activities: activities)
        print("loaded activities count=\(self.activities.count) \(activities.count)")

        if !self.activities.isEmpty {
          appCoordinator.navigate(to: .detail)
        }

      case .loading(let mkMapItem):
        print("loading")
        self.mkMapItem = mkMapItem
        loading = true
      }
    }
  }
}
