//
//  ViewController.swift
//  pokejace
//
//  Created by Brandon Chong on 2/23/19.
//  Copyright © 2019 Brandon Chong. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class ViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UISearchBarDelegate, UICollectionViewDataSource {
    
    struct Pokemon : Codable, Hashable {
        let id: Int
        let name: String
        let hasImage: Bool
        var caught: Bool
        var shinyExists: Bool
        var caughtShiny: Bool
        var haveLucky: Bool
        var havePerfect: Bool
    }
    
    var data = [Pokemon]()
    var pokemonNames = [String]()
    var longPressPokemonID = [Int]()
    
    var filteredData: [Pokemon]!
    
    func parsePokemonListJSON(appDelegate: AppDelegate, managedContext: NSManagedObjectContext) {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/?offset=0&limit=493") else {return}
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let dataResponse = data,
                error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return }
            do{
                //here dataResponse received from a network request
                let jsonResponse = try JSONSerialization.jsonObject(with:
                    dataResponse, options: [])
                //print(jsonResponse) //Response result
                
                guard let jsonArray = jsonResponse as? [String: Any] else {
                    return
                }
                guard let pokemonList = jsonArray["results"] as? [[String: Any]] else {
                    return
                }
                for i in 0 ..< pokemonList.count {
                    let pokemon = Pokemon(id: (i + 1), name: (pokemonList[i]["name"] as! String).replacingOccurrences(of: "-", with: " ", options: .literal, range: nil).capitalized, hasImage: (UIImage(named: String(i + 1)) != nil), caught: false, shinyExists: false, caughtShiny: false, haveLucky: false, havePerfect: false)
                    self.data.append(pokemon)
                }
                // Meltan
                self.data.append(Pokemon(id: 808, name: "Meltan", hasImage: true, caught: false, shinyExists: true, caughtShiny: false, haveLucky: false, havePerfect: false))
                // Melmetal
                self.data.append(Pokemon(id: 809, name: "Melmetal", hasImage: true, caught: false, shinyExists: true, caughtShiny: false, haveLucky: false, havePerfect: false))
                DispatchQueue.main.async {
                    self.myCollectionView.reloadData()
                }
            } catch let parsingError {
                print("Error", parsingError)
            }
        }
        task.resume()
        
        // Get Shiny List
        guard let myURL = URL(string: "https://pokemongo.gamepress.gg/pokemon-go-shinies-list") else {
            print("Error: Doesn't seem to be a valid URL")
            return
        }
        do {
            let myHTMLString = try String(contentsOf: myURL, encoding: .ascii)
            let regex = try NSRegularExpression(pattern: "<td headers=\"view-field-pokemon-go-shiny-image-table-column\" class=\"views-field views-field-field-pokemon-go-shiny-image views-align-center\"> <a href=\"/pokemon/\\d+")
            let result = regex.matches(in: myHTMLString, range: NSMakeRange(0, myHTMLString.utf16.count))
            let mapped = result.map {
                String(myHTMLString[Range($0.range, in: myHTMLString)!])
            }
            let mapped2 = mapped.map {
                $0.replacingOccurrences(
                    of: "[^+0-9]",
                    with: "",
                    options: .regularExpression
                )
            }
            var mapped3 = mapped2.map {
                Int($0)!
            }
            for i in 0 ..< mapped3.count - 2 {
                if (mapped3[i] < 808) {
                    self.data[mapped3[i] - 1].shinyExists = true
                }
            }
            self.data = self.data.filter({ $0.hasImage })
            pokemonNames = self.data.map({ $0.name })
            
            let pokemonMOEntity = NSEntityDescription.entity(forEntityName: "PokemonMO", in: managedContext)!
            for item in self.data {
                let pokemonMO = NSManagedObject(entity: pokemonMOEntity, insertInto: managedContext)
                    pokemonMO.setValue(item.id, forKeyPath: "id")
                    pokemonMO.setValue(item.name, forKeyPath: "name")
                    pokemonMO.setValue(item.hasImage, forKeyPath: "hasImage")
                    pokemonMO.setValue(item.caught, forKeyPath: "caught")
                    pokemonMO.setValue(item.shinyExists, forKeyPath: "shinyExists")
                    pokemonMO.setValue(item.caughtShiny, forKeyPath: "caughtShiny")
                    pokemonMO.setValue(item.haveLucky, forKeyPath: "haveLucky")
                    pokemonMO.setValue(item.havePerfect, forKeyPath: "havePerfect")
            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            self.filteredData = self.data
            self.myCollectionView.reloadData()
        } catch let error {
            print("Error: \(error)")
        }
    }
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search here!"
        searchBar.searchBarStyle = UISearchBar.Style.minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let myCollectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        let coll = UICollectionView(frame: .zero, collectionViewLayout: layout)
            coll.translatesAutoresizingMaskIntoConstraints = false
            coll.backgroundColor = .white
        return coll
    }()
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var items = [UIBarButtonItem]()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
        items.append(flexSpace)
        items.append(doneBtn)
        //items.append( UIBarButtonItem(barButtonSystemItem: "Shiny", target: self, action: nil) )
        toolbar.setItems(items, animated: false)
            toolbar.sizeToFit()
        
        self.searchBar.inputAccessoryView = toolbar
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "PokemonMO")
            fetchReq.sortDescriptors = [NSSortDescriptor.init(key: "id", ascending: true)]
            fetchReq.returnsObjectsAsFaults = false
        let fetchRes = try! managedContext.fetch(fetchReq)
        print(fetchRes.count)
        if (fetchRes.count == 0) {
            self.parsePokemonListJSON(appDelegate: appDelegate, managedContext: managedContext)
        } else {
            for data in fetchRes as! [NSManagedObject] {
                //print(data.value(forKey: "name") as! String)
                if (data.value(forKey: "hasImage") as! Bool) {
                    self.data.append(Pokemon(id: data.value(forKey: "id") as! Int, name: data.value(forKey: "name") as! String, hasImage: true, caught: data.value(forKey: "caught") as! Bool, shinyExists: data.value(forKey: "shinyExists") as! Bool, caughtShiny: data.value(forKey: "caughtShiny") as! Bool, haveLucky: data.value(forKey: "haveLucky") as! Bool, havePerfect: data.value(forKey: "havePerfect") as! Bool))
                }
            }
        }
        self.filteredData = self.data
        pokemonNames = self.data.map({ $0.name })
        
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(longPressGR:)))
        longPressGR.minimumPressDuration = 0.5
        longPressGR.delaysTouchesBegan = true
        self.myCollectionView.addGestureRecognizer(longPressGR)
        
        view.backgroundColor = .white
        self.navigationItem.title = "Poké Jacé"
        myCollectionView.dataSource = self
        myCollectionView.delegate = self
        searchBar.delegate = self
        myCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollCell")
        view.addSubview(searchBar)
        view.addSubview(myCollectionView)
        autoLayoutSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.filteredData = self.data
        self.myCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //print(filteredData.count)
        return self.filteredData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollCell", for: indexPath)
        for view in cell.subviews {
            view.removeFromSuperview()
        }
        let pokemonImageView = UIImageView(image: UIImage(named: String(filteredData[indexPath.row].id)))
        if (pokemonImageView.image == nil) {
            cell.backgroundColor = .gray
            return cell
        }
        if (longPressPokemonID.contains(self.filteredData[indexPath.row].id)) {
            cell.backgroundColor = .lightGray
        }
        pokemonImageView.frame = CGRect(x: 0, y: 0, width: cell.bounds.size.width, height: cell.bounds.size.height)
        if (!filteredData[indexPath.row].caught) {
            pokemonImageView.image = pokemonImageView.image?.withRenderingMode(.alwaysTemplate)
            pokemonImageView.tintColor = .gray
        }
        pokemonImageView.contentMode = .scaleAspectFit
        var iconsToDisplay = [CGImage?]()
        if (filteredData[indexPath.row].caughtShiny) {
            iconsToDisplay.append(UIImage(named: "shiny_icon")?.cgImage)
        }
        if (filteredData[indexPath.row].haveLucky) {
            iconsToDisplay.append(UIImage(named: "lucky_icon")?.cgImage)
        }
        if (filteredData[indexPath.row].havePerfect) {
            iconsToDisplay.append(UIImage(named: "perfect_icon")?.cgImage)
        }
        for i in 0 ..< iconsToDisplay.count {
            let heightCalc = Double((Int(cell.bounds.size.height) - (20 * iconsToDisplay.count))) + (9 * Double((i * 2)))
            let shinyIconLayer = CALayer()
                shinyIconLayer.frame = CGRect(origin: CGPoint(x: cell.bounds.size.width - 20, y: CGFloat(heightCalc)), size: CGSize(width: 20, height: 20))
                shinyIconLayer.contents = iconsToDisplay[i]
            pokemonImageView.layer.addSublayer(shinyIconLayer)
        }
        cell.addSubview(pokemonImageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if longPressPokemonID.isEmpty {
            if let cell = collectionView.cellForItem(at: indexPath) {
                //cell.backgroundColor = .green
                //self.present(InfoViewController(), animated: true, completion: nil)
                let infoViewController: InfoViewController = InfoViewController(nibName: nil, bundle: nil)
                    infoViewController.filteredIndex = indexPath.row
                    infoViewController.pokemonName = self.filteredData[indexPath.row].name
                    infoViewController.pokemonNames = self.pokemonNames
                    //infoViewController.filteredData = self.filteredData
                    infoViewController.delegate = self
                self.navigationController?.pushViewController(infoViewController, animated: true)
            }
        } else {
            longPressAction(indexPath: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = collectionView.bounds.width / 6.0
        let yourHeight = yourWidth
        
        return CGSize(width: yourWidth, height: yourHeight)
    }
    
    @objc func handleLongPress(longPressGR: UILongPressGestureRecognizer) {
        if longPressGR.state != .ended {
            let point = longPressGR.location(in: self.myCollectionView)
            let indexPath = self.myCollectionView.indexPathForItem(at: point)
            if let indexPath = indexPath {
                longPressAction(indexPath: indexPath)
            }
            return
        }
    }
    
    func longPressAction(indexPath: IndexPath) {
        let cell = self.myCollectionView.cellForItem(at: indexPath)
        if !longPressPokemonID.contains(self.filteredData[indexPath.row].id) {
            longPressPokemonID.append(self.filteredData[indexPath.row].id)
            cell?.backgroundColor = .lightGray
        } else {
            longPressPokemonID = longPressPokemonID.filter{ $0 != self.filteredData[indexPath.row].id }
            cell?.backgroundColor = .none
        }
        print(longPressPokemonID)
    }
    
    /**
     # Search functionality:
     ### Reserved keywords:
     - "all"       = all pokemon
     - "all shiny" = available shinies
     - "shiny"     = user's caught shinies
     - "!shiny"    = existing but not caught shinies
     - "lucky"     = user's luckies
     - "!lucky"    = user's non luckies
     - "perfect"   = user's 100% IV
     - "!perfect"  = user's non 100% IV
     - "complete"  = user's pokemon that are shiny, lucky, and perfect
     - "!complete" = user's pokemon that are not shiny, lucky, and perfect
     
     ### Planned keywords:
     - (pokemon types)
     */
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = searchText.isEmpty || searchText.lowercased() == "all" ? data : data.filter { (Pokemon) -> Bool in
            let keywords: [String: Bool] = ["caught": Pokemon.caught, "!caught": !Pokemon.caught, "all shiny": Pokemon.shinyExists, "shiny": Pokemon.caughtShiny, "!shiny": Pokemon.shinyExists && !Pokemon.caughtShiny, "lucky": Pokemon.haveLucky, "!lucky": !Pokemon.haveLucky, "perfect": Pokemon.havePerfect, "!perfect": !Pokemon.havePerfect, "complete": (Pokemon.shinyExists ? Pokemon.caughtShiny : true) && Pokemon.haveLucky && Pokemon.havePerfect, "!complete": (Pokemon.shinyExists ? !Pokemon.caughtShiny : true) || !Pokemon.haveLucky || !Pokemon.havePerfect]
            let searchTextFiltered = searchText.replacingOccurrences(of: " &", with: "&", options: .literal, range: nil)
                    .replacingOccurrences(of: "& ", with: "&", options: .literal, range: nil)
                    .replacingOccurrences(of: " +", with: "+", options: .literal, range: nil)
                    .replacingOccurrences(of: "+ ", with: "+", options: .literal, range: nil)
            let separatorSet = CharacterSet(charactersIn: "+")
            let splitString = searchTextFiltered.components(separatedBy: separatorSet)
            var searchQuery = false
            for query in splitString {
                var queryBuilder = true
                if (query.contains("&")) {
                    let andSplitString = query.split(separator: "&")
                    for andQuery in andSplitString {
                        if (Array(keywords.keys).contains(String(andQuery))) {
                            queryBuilder = queryBuilder && keywords[String(andQuery)]!
                        } else {
                            queryBuilder = queryBuilder && Pokemon.name.range(of: andQuery, options: .caseInsensitive, range: nil, locale: nil) != nil
                        }
                    }
                } else {
                    if (Array(keywords.keys).contains(String(query))) {
                        queryBuilder = queryBuilder && keywords[String(query)]!
                    } else {
                        queryBuilder = queryBuilder && Pokemon.name.range(of: query, options: .caseInsensitive, range: nil, locale: nil) != nil
                    }
                }
                searchQuery = searchQuery || queryBuilder
            }
            return searchQuery
        }
        myCollectionView.reloadData()
    }

    func autoLayoutSetup() {
        searchBar.heightAnchor.constraint(equalToConstant: 75).isActive = true
        searchBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        myCollectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor).isActive = true
        myCollectionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        myCollectionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        myCollectionView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
}

