//
//  ViewController.swift
//  pokejace
//
//  Created by Brandon Chong on 2/23/19.
//  Copyright © 2019 Brandon Chong. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UISearchBarDelegate, UICollectionViewDataSource {
    
    struct Pokemon: Codable {
        let name: String
        var caught: Bool
        var shinyExists: Bool
        var caughtShiny: Bool
        var haveLucky: Bool
        var havePerfect: Bool
    }
    
    var data = [Pokemon]()
    
    var filteredData: [Pokemon]!
    
    func parsePokemonListJSON () {
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
                    let pokemon = Pokemon(name: pokemonList[i]["name"] as! String, caught: false, shinyExists: false, caughtShiny: false, haveLucky: false, havePerfect: false)
                    self.data.append(pokemon)
                }
                self.filteredData = self.data
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
            for i in 0 ..< mapped3.count {
                if (mapped3[i] < 808) {
                    self.data[mapped3[i] - 1].shinyExists = true
                    if (Int.random(in: 0 ..< 3) == 0) {
                        self.data[mapped3[i] - 1].caughtShiny = true
                    }
                }
            }
            self.filteredData = self.data
            self.myCollectionView.reloadData()
        } catch let error {
            print("Error: \(error)")
        }
    }
    
    private let infoView: UIScrollView = {
        let view = UIScrollView()
        //view.backgroundColor = .gray
        return view
    }()
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.parsePokemonListJSON()
        self.filteredData = self.data
        view.backgroundColor = .white

        myCollectionView.dataSource = self
        myCollectionView.delegate = self
        searchBar.delegate = self
        myCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollCell")
        view.addSubview(searchBar)
        view.addSubview(myCollectionView)
        autoLayoutSetup()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //print(filteredData.count)
        return filteredData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollCell", for: indexPath)
        for view in cell.subviews {
            view.removeFromSuperview()
        }
        let textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: cell.bounds.size.width, height: cell.bounds.size.height))
        textLabel.text = filteredData[indexPath.row].name
        textLabel.textColor = filteredData[indexPath.row].shinyExists ? (filteredData[indexPath.row].caughtShiny ? .red : .blue) : .gray
        textLabel.textAlignment = .center
        cell.addSubview(textLabel)
        //cell.backgroundColor = .gray
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath){
            cell.backgroundColor = .green
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath){
            cell.backgroundColor = .white
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = collectionView.bounds.width / 6.0
        let yourHeight = yourWidth
        
        return CGSize(width: yourWidth, height: yourHeight)
    }
    
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = searchText.isEmpty || searchText.lowercased() == "all" ? data : data.filter { (Pokemon) -> Bool in
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
            let keywords: [String: Bool] = ["all shiny": Pokemon.shinyExists, "shiny": Pokemon.caughtShiny, "!shiny": Pokemon.shinyExists && !Pokemon.caughtShiny, "lucky": Pokemon.haveLucky, "!lucky": !Pokemon.haveLucky, "perfect": Pokemon.havePerfect, "!perfect": !Pokemon.havePerfect, "complete": (Pokemon.shinyExists ? Pokemon.caughtShiny : true) && Pokemon.haveLucky && Pokemon.havePerfect, "!complete": (Pokemon.shinyExists ? !Pokemon.caughtShiny : true) || !Pokemon.haveLucky || !Pokemon.havePerfect]
            let searchTextFiltered = searchText.replacingOccurrences(of: " &", with: "&", options: .literal, range: nil).replacingOccurrences(of: "& ", with: "&", options: .literal, range: nil)
            let separatorSet = CharacterSet(charactersIn: " ")
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

