//
//  FollowingViewController.swift
//  nailARt
//
//  Created by Chloe Nguyen on 4/27/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class CustomFollowingTableCell: UITableViewCell {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var username: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImage.layer.cornerRadius = 45
        userImage.layer.shadowColor = UIColor.black.cgColor
        userImage.layer.shadowOpacity = 0.15
        userImage.layer.shadowOffset = CGSize(width: 5, height: 5)
        userImage.layer.shadowRadius = 5
    }
}

struct Follow {
    let u_image: UIImageView
    let u_name: UILabel
}

class FollowingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var followTableView: UITableView!
    @IBAction func backToProfile(_ sender: Any) {
        self.performSegue(withIdentifier: "followingToProfile", sender: self)

    }
    
    var followDataArray: [Follow] = []
    
    var lastDocumentSnapshot: DocumentSnapshot?
    var isFetchingMore = false
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        activityIndicator = UIActivityIndicatorView(style: .medium)
        self.view.addSubview(activityIndicator)
        activityIndicator.center = self.view.center
        
        self.overrideUserInterfaceStyle = .light
        
        followTableView.delegate = self
        followTableView.dataSource = self
        
        followTableView.clipsToBounds = false
        followTableView.showsVerticalScrollIndicator = false
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        activityIndicator.startAnimating()
    }
    
    func loadData() {
        
        guard !isFetchingMore else { return }
        isFetchingMore = true
    
        Task {
            // loop here
            var continueLoading = true

            while continueLoading {
                await getDataForFollow()
                DispatchQueue.main.async {
                    self.followTableView.reloadData()
                }
                
                self.activityIndicator.stopAnimating()
                
                continueLoading = lastDocumentSnapshot != nil
            }
            
            DispatchQueue.main.async {
                self.isFetchingMore = false
                
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followDataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "myFollowCell", for: indexPath) as? CustomFollowingTableCell else {
            return UITableViewCell()
        }
        let followData = followDataArray[indexPath.row]
        cell.userImage.image = followData.u_image.image
        cell.username.text = followData.u_name.text
        
        return cell
    }

    func getDataForFollow() async {
        
//        guard let userEmail = Auth.auth().currentUser?.email else {
//            print("No user is currently signed in, or the user does not have an email.")
//            return
//        }
        
        var userId: String
        
//        if let uid = await fetchUserIdByEmail(userEmail) {
//            userId = uid
//            print("Found user_id: \(userId)")
//        } else {
//            userId = "u2"
//        }
        
        userId = "u2"
        
        guard let followIds = await fetchFollowRef(userId) else {
                print("Failed to fetch saved post IDs or no saved posts available.")
                return
            }
        if followIds.isEmpty {
            print("No saved posts for this user.")
            return
        }
        
        let usersRef = db.collection("users")
        var query = usersRef.whereField("user_id", in: followIds).limit(to: 1)
        if let lastSnapshot = lastDocumentSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }
        
        do {
            let querySnapshot = try await query.getDocuments()
            lastDocumentSnapshot = querySnapshot.documents.last
            
            if querySnapshot.documents.isEmpty {
                lastDocumentSnapshot = nil
                return
            }
            
            for document in querySnapshot.documents {
                let data = document.data()
                let userImage = UIImageView()
                let profilePicPath = data["profile_pic"]
                
                await withUnsafeContinuation { continuation in
                    self.fetchImage(from: profilePicPath as! String) { image in
                        userImage.image = image.image
                        continuation.resume()
                    }
                }
                
                let name = UILabel()
                name.text = data["username"] as? String ?? ""
                
                let user = Follow(u_image: userImage, u_name: name)
                self.followDataArray.append(user)
            }
        }catch let error {
            print("Error getting documents: \(error)")
            lastDocumentSnapshot = nil
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating() // Stop animating on error
            }

        }
    }
    
    func fetchUserIdByEmail(_ userEmail: String) async -> String? {
        do {
            let querySnapshot = try await db.collection("users").whereField("email", isEqualTo: userEmail).getDocuments()
            guard let userDocument = querySnapshot.documents.first else {
                print("No matching user document found")
                return nil
            }
            let userId = userDocument.data()["user_id"] as? String
            return userId
        } catch {
            print("Error fetching user document: \(error)")
            return nil
        }
    }
    
    func fetchFollowRef(_ userId: String) async -> [String]? {
        do {
            let querySnapshot = try await db.collection("users").whereField("user_id", isEqualTo: userId).getDocuments()
            guard let userDocument = querySnapshot.documents.first else {
                print("No matching user document found")
                return nil
            }
            let follow = userDocument.data()["follow"] as? [String] ?? []
            return follow
        } catch {
            print("Error fetching user document: \(error)")
            return nil
        }
    }
        
    private func fetchImage(from path: String, completion: @escaping (UIImageView) -> Void) {
        let imageView = UIImageView()
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child(path)
//        print("path: \(path)")

        imageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching image: \(error)")
                } else if let data = data, let image = UIImage(data: data) {
                    imageView.image = image
                    completion(imageView)
                } else {
                    print("No data or error returned.")
                }
            }
        }
    }

}
