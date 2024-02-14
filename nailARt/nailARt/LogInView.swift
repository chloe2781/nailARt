//
//  LogInView.swift
//  nailARt
//
//  Created by Chloe Nguyen on 1/29/24.
//

import Foundation
import UIKit

class LogInView: UIViewController {

    @IBAction func logInButton(_ sender: Any) {
        self.performSegue(withIdentifier: "home", sender: self)
    }
    
    @IBAction func signUpButton(_ sender: Any) {
        self.performSegue(withIdentifier: "signup", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}
