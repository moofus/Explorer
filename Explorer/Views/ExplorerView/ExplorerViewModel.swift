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
    return switch category {

      // Culture & Arts
    case "Art Gallery", "Galleries": "photo.fill.on.rectangle.fill" // frame.3.fill
    case "Concert Halls": "music.note.house.fill"
    case "Museums": "building.2.fill"
    case "Performing Arts": "theatermasks"
    case "Theaters", "Theater": "theatermasks.fill"

      // Family Activities
    case "Amusement Parks", "Recreation": "figure.walk" // ferris.wheel.fill
    case "Zoos", "Zoo": "pawprint.fill"

      // Outdoor & Nature
    case "Beaches", "Beach": "beach.umbrella.fill" // water.waves.and.sun.fill
    case "Biking": "bicycle"
    case "Gardens", "Garden": "leaf.fill"
    case "Hiking", "Outdoor": "figure.hiking.circle.fill" // mountains.2.fill
    case "Nature", "Parks", "Park", "Zoological Park": "tree.fill"
    case "Outdoor Activity", "Outdoor Recreation": "figure.hiking.circle.fill" // mountains.2.fill

      // Services & Other
    case "Public Transit": "bus.fill"

      // Shopping & Fashion
    case "Markets", "Market": "carrot.fill"
    case "Shopping/Dining": "bag.fill"

      // Family Activities
    case "Animal Park": "pawprint.fill"

      // Entertainment
    case "Entertainment": "popcorn.fill"

      // Cultural
    case "Cultural Experience": "globe"
    case "Historical Site": "house.and.flag.fill"


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
//    case "Transportation":
//       "car.fill"
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
      //"mappin.circle.fill"
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
      case .loaded(let list):
        print("loaded list")
        print(list)
      case .loading(let mkMapItem):
        print("loading")
        self.mkMapItem = mkMapItem
        loading = true
      }
    }
  }
}

/*
 [Explorer.AIManager.Item(name: "Oakland Museum of California", address: "1800 Broadway, Oakland, CA 94612", city: "Oakland", state: "CA", category: "Museum", description: "An interactive museum that focuses on California\'s history, art, and culture.", somethingInteresting: "It offers a wide array of exhibits on California\'s diverse cultural heritage."), Explorer.AIManager.Item(name: "Hiking at Mount Diablo Regional Park", address: "1234 Mount Diablo Rd, Concord, CA 94520", city: "Concord", state: "CA", category: "Outdoor Activity", description: "Enjoy scenic trails with views of the San Francisco Bay and the East Bay.", somethingInteresting: "The trails are perfect for both beginners and experienced hikers, with breathtaking panoramic views."), Explorer.AIManager.Item(name: "Explore Jack London Square", address: "Jack London Square, Oakland, CA 94612", city: "Oakland", state: "CA", category: "Shopping/Dining", description: "A vibrant waterfront area with shops, restaurants, and entertainment options.", somethingInteresting: "Known for its lively atmosphere and annual events, it\'s a great place to experience local culture."), Explorer.AIManager.Item(name: "Visit the Oakland Zoo", address: "2200 Telegraph Ave, Oakland, CA 94609", city: "Oakland", state: "CA", category: "Animal Park", description: "A family-friendly zoo home to a wide variety of animals and interactive exhibits.", somethingInteresting: "The zoo is committed to conservation and education, offering behind-the-scenes tours."), Explorer.AIManager.Item(name: "Catch a Show at Fox Theatre", address: "2021 Broadway, Oakland, CA 94612", city: "Oakland", state: "CA", category: "Entertainment", description: "A historic theater showcasing Broadway shows, concerts, and other performances.", somethingInteresting: "Opened in 1927, it\'s one of the oldest continuously operating theaters in the West."), Explorer.AIManager.Item(name: "Stroll Through Chinatown", address: "1600 Telegraph Ave, Oakland, CA 94609", city: "Oakland", state: "CA", category: "Cultural Experience", description: "Explore a vibrant neighborhood filled with authentic Asian cuisine and shopping.", somethingInteresting: "It\'s one of the oldest Chinatowns in the United States, offering a taste of East Asian culture."), Explorer.AIManager.Item(name: "Bike the East Bay Bike Path", address: "Various points in East Bay", city: "Various", state: "CA", category: "Biking", description: "A network of bike paths perfect for leisurely rides or more challenging routes.", somethingInteresting: "The path offers stunning views of the bay and surrounding landscapes, making it ideal for outdoor enthusiasts."),
Explorer.AIManager.Item(name: "Visit the Oakland Botanical Garden", address: "1000 Quail Hill Rd, Oakland, CA 94610", city: "Oakland", state: "CA", category: "Garden", description: "A serene garden featuring diverse plant collections and beautiful landscapes.", somethingInteresting: "It\'s a peaceful retreat with themed gardens, perfect for nature lovers."),
Explorer.AIManager.Item(name: "Discover the Oakland Art Museum", address: "1800 Broadway, Oakland, CA 94612", city: "Oakland", state: "CA", category: "Art Gallery", description: "Showcases contemporary and historical art from local and international artists.", somethingInteresting: "The museum frequently hosts rotating exhibits and community art programs.")]
 */
