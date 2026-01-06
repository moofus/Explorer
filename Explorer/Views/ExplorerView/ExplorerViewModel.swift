//
//  ExplorerViewModel.swift
//  Explorer
//
//  Created by Lamar Williams III on 12/31/25.
//

import Foundation
import FactoryKit
import MapKit

@MainActor
@Observable
class ExplorerViewModel {
  @ObservationIgnored
  @Injected(\.explorerSource) var source: ExplorerSource

  private(set) var errorDescription = ""
  private(set) var errorRecoverySuggestion = ""
  var haveError = false
  private(set) var loading = false
  private(set) var mkMapItem: MKMapItem?

  init() {
    print("ljw \(Date()) \(#file):\(#function):\(#line)")
    Task { await handleSource() }
  }
}

// MARK: - Private Methods
extension ExplorerViewModel {

  private func categoryToImageName(category: String) -> String {
    switch category {

      // Culture & Arts
    case "Art", "Arts and Culture": "palette.fill"
    case "Art Gallery", "Galleries": "photo.fill.on.rectangle.fill" // frame.3.fill
    case "Concert Halls": "music.note.house.fill"
    case "Architecture", "History and Culture", "Landmark", "Scenic": "mappin.circle.fill"
    case "Museums": "building.2.fill"
    case "Performing Arts": "theatermasks"
    case "Theaters", "Theater": "theatermasks.fill"

      // Cultural
    case "Culture", "Cultural Experience", "Cultural Neighborhood": "globe"
    case "Cultural", "Cultural Landmark": "building.columns.fill"
    case "History", "Historical Site": "house.and.flag.fill"

      // Entertainment
    case "Entertainment": "popcorn.fill"

      // Family Activities
    case "Animal Park": "pawprint.fill"
    case "Amusement Parks", "Recreation": "figure.walk" // ferris.wheel.fill
    case "Science", "Science Museum": "atom"
    case "Island Tour", "Tour": "figure.walk"
    case "Zoos", "Zoo": "pawprint.fill"

      // Food & Dining
    case "Food", "Restaurants": "fork.knife.circle.fill" // fork.knife

      // Outdoor & Nature
    case "Beaches", "Beach": "beach.umbrella.fill" // water.waves.and.sun.fill
    case "Biking": "bicycle"
    case "Gardens", "Garden": "leaf.fill"
    case "Hiking", "Nature Reserve", "Outdoor", "Nature & Hiking": "figure.hiking.circle.fill" // mountains.2.fill
    case "Nature", "Parks", "Park", "Zoological Park": "tree.fill"
    case "Outdoor Activity", "Outdoor Recreation": "figure.hiking.circle.fill" // mountains.2.fill
    case "Sightseeing": "bus.fill"

      // Services & Other
    case "Public Transit": "bus.fill"
          case "Transportation": "car.fill"

      // Shopping & Fashion
    case "Markets", "Market": "carrot.fill"
    case "Neighborhood", "Shopping/Dining", "Shopping & Dining", "Shopping and Dining": "bag.fill" // ljw rotate dinning



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
      fatalError() // ljw
      // "mappin.circle.fill"
    }
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
      case .loaded(let activies):
        print("loaded items")
        print(activies)
        for activity in activies {
          print("category=\(activity.category) image=\(categoryToImageName(category: activity.category))")
        }
      case .loading(let mkMapItem):
        print("loading")
        self.mkMapItem = mkMapItem
        loading = true
      }
    }
  }
}
