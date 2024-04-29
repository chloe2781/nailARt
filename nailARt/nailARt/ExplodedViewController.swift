//
//  ExplodedViewController.swift
//  nailARt
//
//  Created by Chloe Nguyen on 4/28/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import UIKit

class ExplodedViewController: UIViewController {

    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var detailImageView: UIImageView!
    @IBOutlet weak var savesLabel: UILabel!
    
    var postImage: UIImageView?
    var postSaves: UILabel?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.overrideUserInterfaceStyle = .light
        
        background.layer.cornerRadius = 37
        background.layer.shadowColor = UIColor.black.cgColor
        background.layer.shadowOpacity = 0.25
        background.layer.shadowOffset = CGSize(width: 8, height: 9)
        background.layer.shadowRadius = 5

        // Do any additional setup after loading the view.
        detailImageView.image = postImage?.image
        savesLabel.text = postSaves?.text
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
