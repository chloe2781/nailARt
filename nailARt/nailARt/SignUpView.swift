//
//  SignUpView.swift
//  nailARt
//
//  Created by Chloe Nguyen on 2/14/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpView: UIViewController {

    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    
    @IBAction func signUpButton(_ sender: Any) {
        let username = usernameText.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailText.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordText.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let firestore = Firestore.firestore()
//        let usernameRef = firestore.collection("usernames").document(username)
        
        firestore.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                let alert = UIAlertController(title: "Error", message: "Failed to check username: \(error.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                let alert = UIAlertController(title: "Error", message: "Username already taken", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(alert, animated: true)
            }

            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    let alert = UIAlertController(title: "Error", message: "Registration Failed: \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
                
                guard let userId = result?.user.uid else {
                    let alert = UIAlertController(title: "Error", message: "Failed to retrieve user ID", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    self.present(alert, animated: true)
                    return
                }
                
                // Generate new user_id
                firestore.collection("users").order(by: "user_id", descending: true).limit(to: 1).getDocuments { snapshot, error in
                    guard let snapshot = snapshot, let document = snapshot.documents.first, let lastUserId = document.data()["user_id"] as? String else {
                        let alert = UIAlertController(title: "Error", message: "Failed to generate user ID", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                        self.present(alert, animated: true)
                        return
                    }
                    
                    let newUserIndex = Int(lastUserId.dropFirst(1))! + 1
                    let newUserID = "u\(newUserIndex)"
                    
                    // Create user document in Firestore
                    let userData = [
                        "email": email,
                        "user_id": newUserID,
                        "username": username,
                        "profile_pic": "",
                        "follow": [],
                        "saved": []
                    ] as [String : Any]
                    
                    firestore.collection("users").document(userId).setData(userData) { error in
                        if let error = error {
                            let alert = UIAlertController(title: "Error", message: "Failed to save user data: \(error.localizedDescription)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                            self.present(alert, animated: true)
                        }
                        self.performSegue(withIdentifier: "homeAfterSignUp", sender: self)
                    }
                }
            }
        }
    }
    
    @IBAction func loginButton(_ sender: Any) {
        self.performSegue(withIdentifier: "login", sender: self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light

        // Do any additional setup after loading the view.
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
