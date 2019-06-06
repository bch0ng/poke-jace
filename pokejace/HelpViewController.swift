//
//  HelpViewController.swift
//  pokejace
//
//  Created by Brandon Chong on 6/6/19.
//  Copyright © 2019 Brandon Chong. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController
{
    struct Section {
        var name: String
        var items: [String]
        var collapsed: Bool
        
        init(name: String, items: [String], collapsed: Bool = false) {
            self.name = name
            self.items = items
            self.collapsed = collapsed
        }
    }
    
    var sections = [
        Section(name: "Mac", items: ["MacBook", "MacBook Air"]),
        Section(name: "iPad", items: ["iPad Pro", "iPad Air 2"]),
        Section(name: "iPhone", items: ["iPhone 7", "iPhone 6"])
    ]
}
