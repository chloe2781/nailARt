//
//  ProfileViewController.swift
//  nailARt
//
//  Created by Chloe Nguyen on 3/7/24.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var menuBar: UIView!
    @IBOutlet weak var username: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        menuBar.layer.cornerRadius = 25
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
