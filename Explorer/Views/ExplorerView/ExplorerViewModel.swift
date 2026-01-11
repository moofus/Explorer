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
  var inputError = false
  var isProcessing = false
  private(set) var loading = false
  private let logger = Logger(subsystem: "com.moofus.explorer", category: "ExplorerViewModel")
  private(set) var mkMapItem: MKMapItem?
  private var addressToLocationCache = [String: CLLocation]()

  init() {
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


// ljw
  private func handleAquarium(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("aquarium") {
      return ["fish.fill"]
    }
    fatalError()
  }

  private func handleArchitecture(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("street") {
      return ["building.columns.fill", "road.lanes.curved.right"]
    }
    if activity.category.contains("walking") {
      return handleArchitectureWalking(activity)
    }
    fatalError()
  }

  private func handleArchitectureWalking(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("views") {
      return ["building.columns.fill", "figure.walk", "binoculars.fill"]
    }
    if activity.category.contains("walking") {
      return handleArchitectureWalking(activity)
    }
    fatalError()
  }

  private func handleArt(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("architecture") {
      return handleArtCulture(activity)
    }
    if activity.category.contains("culture") {
      return handleArtCulture(activity)
    }
    if activity.description.contains("museum") {
      return ["photo.artframe", "building.columns.fill"]
    }
    fatalError()
  }

  private func handleArtArchitecture(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("garden") {
      return ["leaf.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleArts(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("nightLife") {
      return handleArtsNightLife(activity)
    }
    fatalError()
  }

  private func handleBeach(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("nightlife") {
      return ["beach.umbrella.fill", "figure.dance.circle.fill"]
    }
    fatalError()
  }
  
  private func handleBridge(_ activity: AIManager.Activity) -> [String] {
    if activity.name.contains("bridge") {
      return ["binoculars.fill"]
    }
    fatalError()
  }

  private func handleArtCulture(_ activity: AIManager.Activity) -> [String] {
    if activity.name.contains("district") {
      return ["storefront.fill", "fork.knife"]
    }
    if activity.description.contains("garden") {
      return ["leaf.fill", "figure.walk"]
    }
    if activity.description.contains("museums") {
      return ["photo.artframe", "building.2.fill"]
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
    if activity.description.contains("chinatown") {
      return ["chineseyuanrenminbisign.circle.fill", "storefront.fill", "fork.knife"]
    }
    if activity.description.contains("ferry") {
      return ["ferry.fill", "figure.walk"]
    }
    if activity.description.contains("museums") {
      return ["building.2.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleDriving(_ activity: AIManager.Activity) -> [String] {
    fatalError()
  }

  private func handleEntertainment(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("musicals") || activity.name.contains("theater")  {
      return ["theatermasks.fill", "person.2.badge.plus.fill"]
    }
    if activity.description.contains("theaters") || activity.description.contains("theatre") {
      return ["theatermasks.fill", "person.2.badge.plus.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleFood(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("shopping") {
      return ["fork.knife", "storefront.fill"]
    }
    fatalError()
  }

  private func handleHistor(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("landmark") {
      return handleHistorLandmark(activity)
    }
    if activity.category.contains("music") {
      return ["music.pages.fill", "music.note.house.fill"]
    }
    if activity.category.contains("tour") {
      return ["building.columns.fill", "figure.walk"]
    }
    if activity.description.contains("culture") {
      return handleHistoryCulture(activity)
    }
    fatalError()
  }

  private func handleHistoryCulture(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("exhibits") {
      return ["building.columns.fill", "photo.artframe"]
    }
    if activity.description.contains("walk") {
      return ["building.columns.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleHistorLandmark(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["building.columns.fill", "binoculars.fill"]
    }
    fatalError()
  }

  private func handleHiking(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["figure.hiking.circle.fill", "binoculars.fill"]
    }
    fatalError()
  }

  private func handleGarden(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("garden") {
      return ["figure.hiking.circle.fill", "binoculars.fill"]
    }
    fatalError()
  }

  private func handleIconic(_ activity: AIManager.Activity) -> [String] {
    if activity.name.contains("street") {
      return ["road.lanes.curved.right"]
    }
    if activity.name.contains("views") {
      return ["binoculars.fill"]
    }
    if activity.description.contains("bridge") {
      return ["binoculars.fill"]
    }
    fatalError()
  }

  private func handleLandmark(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["binoculars.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleLandmarksWalk(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["building.columns.fill", "figure.walk", "binoculars.fill"]
    }
    fatalError()
  }

  private func handleMuseum(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("art") {
      return ["building.columns.fill", "photo.artframe"]
    }
    if activity.description.contains("museum") {
      return ["building.columns.fill"]
    }
    if activity.description.contains("science") {
      return ["building.columns.fill", "atom"]
    }
    fatalError()
  }

  private func handleNeighborhood(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("theaters") {
      return ["theatermasks.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleNature(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("garden") || activity.category.contains("gardens") {
      return ["leaf.fill", "figure.walk"]
    }
    if activity.category.contains("hike") || activity.description.contains("hike") {
      return ["leaf.fill", "figure.hiking.circle.fill"]
    }
    if activity.category.contains("recreation") {
      return handleNatureRecreation(activity)
    }
    if activity.category.contains("walk") {
      return ["leaf.fill", "figure.walk"]
    }
    if activity.description.contains("museums") {
      return ["leaf.fill", "building.columns.fill", "figure.walk"]
    }
    if activity.description.contains("park") {
      return handleNaturePark(activity)
    }
    if activity.description.contains("wildlife") {
      return ["leaf.fill", "tree.fill"]
    }
    fatalError()
  }

  private func handleNaturePark(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("beaches") {
      return ["leaf.fill", "tree.fill", "beach.umbrella.fill"]
    }
    if activity.description.contains("garden") {
      return ["leaf.fill", "tree.fill"]
    }
   if activity.description.contains("museums") {
      return ["leaf.fill", "building.columns.fill", "figure.walk"]
    }
    if activity.description.contains("walking") {
      return ["leaf.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleNatureRecreation(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("lakes") {
      return ["leaf.fill", "tree.fill", "figure.walk", "water.waves"]
    }
    fatalError()
  }

  private func handleOutdoor(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("recreation") || activity.description.contains("recreation") {
      return ["mountain.2.fill", "figure.walk"]
    }
     if activity.description.contains("stroll") ||
        activity.description.contains("walking") ||
        activity.description.contains("walk") {
      return handleOutdoorWalk(activity)
    }
    if activity.description.contains("hike") {
      return handleOutdoorHike(activity)
    }
    if activity.description.contains("picnic") {
      return handleOutdoorPicnic(activity)
    }
    if activity.description.contains("swimming") {
      return ["figure.open.water.swim"]
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

  private func handleOutdoorPicnic(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("parks") {
      return ["beach.umbrella.fill", "tree.fill", "figure.walk"]
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
    if activity.description.contains("parks") {
      return ["figure.walk", "tree.fill"]
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
    if activity.description.contains("lake") {
      return ["leaf.fill", "water.waves"]
    }
    if activity.description.contains("museums") {
      return handleParkMuseums(activity)
    }
    if activity.description.contains("park") {
      return ["leaf.fill", "tree.fill"]
    }
    fatalError()
  }

  private func handleParkGardens(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("art") {
      return ["leaf.fill", "photo.artframe", "tree.fill"]
    }
    if activity.description.contains("lakes") {
      return ["leaf.fill", "water.waves", "tree.fill"]
    }
    if activity.description.contains("museums") {
      return ["leaf.fill", "building.2.fill", "tree.fill"]
    }
    if activity.description.contains("walking") {
      return ["leaf.fill", "figure.walk", "tree.fill"]
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
    if activity.description.contains("drive") {
      return ["photo.fill", "car.fill"] // photo
    }
    fatalError()
  }

  private func handleScenic(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("drive") {
      return ["binoculars.fill", "car.fill"]
    }
    if activity.description.contains("views") {
      return ["binoculars.fill", "figure.walk"]
    }
    if activity.category.contains("walk") {
      return ["binoculars.fill", "figure.walk"]
    }
    fatalError()
  }

  private func handleScience(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("education") {
      return ["atom", "graduationcap.fill"]
    }
    if activity.category.contains("interactive") {
      return ["atom", "book.fill"]
    }
    if activity.category.contains("learning") {
      return ["atom", "book.fill"]
    }
    if activity.category.contains("museum") {
      return ["atom", "building.columns.fill"]
    }
    fatalError()
  }

  private func handleShopping(_ activity: AIManager.Activity) -> [String] {
    if activity.category.contains("dining") {
      return ["storefront.fill", "fork.knife"]
    }
    if activity.description.contains("food") {
      return ["storefront.fill", "fork.knife"]
    }
    if activity.description.contains("market") {
      return ["storefront.fill", "fork.knife.circle.fill"]
    }
    if activity.description.contains("theaters") {
      return ["storefront.fill", "theatermasks.fill"]
    }
    fatalError()
  }

  private func handleSightseeing(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("ferry") {
      return ["binoculars.fill", "ferry.fill"]
    }
    if activity.description.contains("stroll") || activity.description.contains("walk") || activity.category.contains("walk") {
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
    if activity.description.contains("drive") {
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

  private func handlePublicSpace(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("park") {
      return handlePublicSpacePark(activity)
    }
    fatalError()
  }

  private func handlePublicSpacePark(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("views") {
      return ["leaf.fill", "tree.fill",  "binoculars.fill"]
    }
    fatalError()
  }

  private func handleTransportation(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("cable car") {
      return ["cablecar.fill"]
    }
    fatalError()
  }

  private func handleRecreational(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("walking") {
      return handleRecreationalWalking(activity)
    }
    fatalError()
  }

  private func handleRecreationalWalking(_ activity: AIManager.Activity) -> [String] {
    if activity.description.contains("lakes") {
      return ["figure.walk", "binoculars.fill", "water.waves"]
    }
    if activity.description.contains("views") {
      return ["figure.walk", "binoculars.fill"]
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
    let activity = activity.lowercased()

    if activity.name.contains("alcatraz") {
      return ["ferry.fill", "figure.walk"]
    }
    if activity.name.contains("cable cars") {
      return ["cablecar.fill"]
    }
    if activity.name.contains("empire state building") {
      return ["binoculars.fill"]
    }
    if activity.name.contains("statue of liberty") {
      return ["ferry.fill", "figure.walk"]
    }
    if activity.name.contains("times square") {
      return ["theatermasks.fill", "storefront.fill", "person.2.badge.plus.fill" ]
    }
    if activity.name.contains("9/11 memorial") {
      return ["building.columns.fill", "mappin.circle"]
    }

    if activity.category.contains("aquarium") {
      return handleAquarium(activity)
    }
    if activity.category.contains("architecture") {
      return handleArchitecture(activity)
    }
    if activity.category.contains("art") {
      return handleArt(activity)
    }
    if activity.category.contains("arts") {
      return handleArts(activity)
    }
    if activity.category.contains("beach") {
      return handleBeach(activity)
    }
    if activity.category.contains("bridge") {
      return handleBridge(activity)
    }
    if activity.category.contains("cultural") || activity.category.contains("culture") {
      return handleCultural(activity)
    }
    if activity.category.contains("driving") {
      return handleDriving(activity)
    }
    if activity.category.contains("entertainment") {
      return handleEntertainment(activity)
    }
    if activity.category.contains("food") {
      return handleFood(activity)
    }
    if activity.category.contains("garden") {
      return handleHiking(activity)
    }
    if activity.category.contains("hiking") {
      return handleHiking(activity)
    }
    if activity.category.contains("histor") {
      return handleHistor(activity)
    }
    if activity.category.contains("iconic") {
      return handleIconic(activity)
    }
    if activity.category.contains("landmark") || activity.category.contains("landmarks") {
      return handleLandmark(activity)
    }
    if activity.category.contains("museum") {
      return handleMuseum(activity)
    }
    if activity.category.contains("neighborhood") {
      return handleNeighborhood(activity)
    }
    if activity.category.contains("nature") {
      return handleNature(activity)
    }
    if activity.category.contains("outdoor") {
      return handleOutdoor(activity)
    }
    if activity.category.contains("park") {
      return handlePark(activity)
    }
    if activity.category.contains("photography") {
      return handlePhotography(activity)
    }
    if activity.category.contains("public space") {
      return handlePublicSpace(activity)
    }
    if activity.category.contains("public transit") {
      return handleTransportation(activity)
    }
    if activity.category.contains("recreational") {
      return handleRecreational(activity)
    }
    if activity.category.contains("scenic") {
      return handleScenic(activity)
    }
    if activity.category.contains("science") {
      return handleScience(activity)
    }
    if activity.category.contains("shopping") {
      return handleShopping(activity)
    }
    if activity.category.contains("sightseeing") {
      return handleSightseeing(activity)
    }
    if activity.category.contains("tour") {
      return handleTour(activity)
    }
    if activity.category.contains("transportation") {
      return handleTransportation(activity)
    }
    if activity.category.contains("walk") {
      return handleWalk(activity)
    }
    fatalError()
  }

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
    for await message in source.stream {
      loading = false

      switch message {
      case .badInput:
        inputError = true
        isProcessing = false
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
        isProcessing = false
      case .initial:
        mkMapItem = nil
      case .loaded:
        print("loaded")
        mkMapItem = nil
        isProcessing = false
        print("loaded activities count=\(self.activities.count) \(activities.count)")

      case .loading(let mkMapItem, let activities):
        print("loading")
        self.mkMapItem = mkMapItem
        self.activities = await convert(activities: activities)
        self.loading = true
      }
    }
  }
}
/* keys
 art      = photo.artframe
 gardens  = tree.fill
 lakes    = water.waves
 museums  = building.2.fill
 theaters = theatermasks.fill
 theatre  = theatermasks.fill
 views    = binoculars.fill

 */
