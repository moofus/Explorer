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
  private var addressToLocationCache = [String: CLLocation]()
  private var categories = [String: [String]]()
  private(set) var errorDescription = ""
  private(set) var errorRecoverySuggestion = ""
  var haveError = false
  var inputError = false
  var isProcessing = false
  private(set) var loading = false
  private let logger = Logger(subsystem: "com.moofus.explorer", category: "ExplorerViewModel")
  private(set) var mkMapItem: MKMapItem?
  private var names = [String: [String]]()

  init() {
    buildNames()
    buildCategories()

    Task { await handleSource() }
  }
}

// MARK: - Private Methods
extension ExplorerViewModel {
  private func buildCategories() {
    categories["art"] = ["photo.artframe"]
    categories["aquarium"] = ["fish.fill"]
    categories["beach"] = ["beach.umbrella.fill"]
    categories["musicals"] = ["music.note"]
    categories["bike"] = ["bicycle"]
    categories["biking"] = ["bicycle.circle.fill"]
    categories["boat"] = ["ferry"]
    categories["cable car"] = ["cablecar.fill"]
    categories["dining"] = ["fork.knife"]
    categories["exhibits"] = ["photo.artframe"]
    categories["district"] = ["storefront.fill"]
    categories["drive"] = ["car.fill"]
    categories["education"] = ["graduationcap.fill"]
    categories["entertainment"] = ["person.2.badge.plus.fill"]
    categories["ferry"] = ["ferry.fill"]
    categories["food"] = ["fork.knife.circle.fill"]
    categories["garden"] = ["leaf.fill"]
    categories["gardens"] = ["leaf.fill"]
    categories["graffiti"] = ["photo.artframe"]
    categories["hiking"] = ["figure.hiking.circle.fill"]
    categories["historic site"] = ["building.fill"]
    categories["iconic views"] = ["binoculars.fill"]
    categories["landmarks"] = ["building.columns.fill"]
    categories["lakes"] = ["water.waves"]
    categories["murals"] = ["paintpalette.fill"]
    categories["museum"] = ["building.fill"]
    categories["museums"] = ["building.2.fill"]
    categories["music"] = ["music.pages.fill","music.note.house.fill"]
    categories["musicals"] = ["music.note"]
    categories["nature"] = ["leaf.fill"]
    categories["nightlife"] = ["figure.dance.circle.fill"]
    categories["outdoor"] = ["sun.max.fill"]
    categories["outdoor walk"] = ["sun.max.fill","figure.walk.circle.fill"]
    categories["park"] = ["tree"]
    categories["parks"] = ["tree.fill"]
    categories["recreation"] = ["figure.walk"]
    categories["restaurants"] = ["fork.knife.circle.fill"]
    categories["scenic views"] = ["binoculars.fill"]
    categories["scenic walk"] = ["binoculars.fill","figure.walk.circle.fill"]
    categories["science"] = ["atom"]
    categories["shop"] = ["storefront.fill"]
    categories["shopping"] = ["storefront.fill"]
    categories["shops"] = ["storefront.fill"]
    categories["sightseeing"] = ["binoculars.fill"]
    categories["stroll"] = ["figure.walk"]
    categories["swimming"] = ["figure.open.water.swim"]
    categories["theater"] = ["theatermasks.fill"]
    categories["theatre"] = ["theatermasks.fill"]
    categories["tour"] = ["figure.walk.circle.fill"]
    categories["trails"] = ["figure.hiking.circle.fill"]
    categories["travel"] = ["airplane"]
    categories["views"] = ["binoculars.fill"]
    categories["walking"] = ["figure.walk.motion"]
    categories["waterfront"] = ["water.waves"]
    categories["zoo"] = ["pawprint.fill"]
  }

  private func buildNames() {
    names["alcatraz"] = ["ferry", "figure.walk"]
    names["bridge"] = ["figure.walk.circle.fill"]
    names["cable car"] = ["cablecar.fill"]
    names["cable cars"] = ["cablecar.fill"]
    names["chinatown"] = ["chineseyuanrenminbisign.circle.fill","fork.knife","storefront.fill"]
    names["coit tower"] = ["binoculars.fill"]
    names["empire state building"] = ["binoculars.fill"]
    names["haight-ashbury district"] = ["figure.walk.circle.fill","binoculars.fill"]
    names["little havana"] = ["storefront.fill", "fork.knife.circle.fill" ]
    names["museum"] = ["building.fill","figure.walk"]
    names["lombard street"] = ["road.lanes.curved.right"]
    names["sightseeing walk"] = ["binoculars.fill","figure.walk"]
    names["space"] = ["moon.stars.fill", "globe.americas.fill"]
    names["statue of liberty"] = ["ferry.fill", "figure.walk.circle.fill"]
    names["times square"] = ["theatermasks.fill", "storefront.fill", "person.2.badge.plus.fill"]
    names["9/11 memorial"] = ["building.columns.fill"]
  }

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

  private func convert(activities: [AIManager.Activity]) async -> [Activity] {
    var result = [Activity]()
    for activity in activities {
      let distance: Double
      do {
        distance = try await getDistance(from: activity)
      } catch {
        logger.error("\(error.localizedDescription)")
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

  private func imageNames(from activity: AIManager.Activity) -> [String] {
    print("------------------------------")
    let activity = activity.lowercased()
    print(activity)

    var result = process(name: activity.name)
    if !result.isEmpty {
      return result
    }

    result = process(input: activity.category, result: [])
    result = process(input: activity.description, result: result)

    if result.count < 1 {
      print(activity)
      fatalError()
    }
    return result
  }

  private func process(input: String, result: [String]) -> [String] {
    var resultStrings = [String]()
    for (key, imageStrings) in categories {
      if input.contains(key) {
        for imageString in imageStrings {
          if result.contains(imageString) { continue }
          resultStrings.append(imageString)
        }
      }
    }
    print("input=\(input) \(resultStrings)")
    return result + resultStrings
  }

  private func process(name input: String) -> [String] {
    for (key, imageStrings) in names {
      if input.contains(key) {
        print("key=\(key) \(imageStrings)")
        return imageStrings
      }
    }
    return []
  }
}
