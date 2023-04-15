//
//  MainTabBarViewController.swift
//  MessengerClone
//
//  Created by Beka Buturishvili on 15.04.23.
//

import UIKit

class MainTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let vc1 = UINavigationController(rootViewController: ConversationsViewController())
        let vc2 = UINavigationController(rootViewController: ProfileViewController())
        
        vc1.tabBarItem.image = UIImage(systemName: "message")
        vc2.tabBarItem.image = UIImage(systemName: "person.fill")
        
        tabBar.tintColor = .label
        
        setViewControllers([vc1,vc2], animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
