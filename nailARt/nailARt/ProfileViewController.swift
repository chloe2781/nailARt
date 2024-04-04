//
//  ProfileViewController.swift
//  nailARt
//
//  Created by Chloe Nguyen on 3/7/24.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// db  = Firestore.firestore()
// storageRef = Storage.storage().reference()

class CustomCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellBackground: UIView!
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellSaves: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Configure cellBackground for cornerRadius without masking to bounds
        cellBackground.layer.cornerRadius = 25
        cellBackground.clipsToBounds = true
        
        cellBackground.layer.shadowColor = UIColor.black.cgColor
        cellBackground.layer.shadowOpacity = 0.25
        cellBackground.layer.shadowOffset = CGSize(width: 8, height: 9)
        cellBackground.layer.shadowRadius = 5
        
        cellBackground.layer.masksToBounds = false
        
        self.clipsToBounds = false // Ensure the cell doesn't clip its contents
        self.contentView.clipsToBounds = false // Ensure contentView doesn't clip its subviews
    }
}

struct PostPreview {
    let pp_image: UIImageView
    let pp_saves: UILabel
}

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

//    @IBAction func explore(_ sender: Any) {
//        self.performSegue(withIdentifier: "profileToExplore", sender: self)
//    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBAction func savedButtonAction(_ sender: Any) {
    }
    
    @IBOutlet weak var pUsername: UILabel!
    @IBOutlet weak var pImage: UIImageView!
    @IBOutlet weak var menuBar: UIView!
    @IBOutlet weak var numDesigns: UILabel!
    @IBOutlet weak var numFollowers: UILabel!
    @IBOutlet weak var savedButton: UIButton!
    
    var postPreviewDataArray: [PostPreview] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self

        menuBar.layer.cornerRadius = 25
        savedButton.layer.cornerRadius = 8
        
        collectionView.clipsToBounds = false
        
//        Task {
//            await fetchPostPreviews()
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Task {
            await fetchPostPreviews()
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postPreviewDataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCollectionCell", for: indexPath) as? CustomCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let postPreview = postPreviewDataArray[indexPath.item]
        cell.cellImage.image = postPreview.pp_image.image
        cell.cellSaves.text = postPreview.pp_saves.text
        
        return cell
    }
    
    func fetchPostPreviews() async {
        
//        guard let userEmail = Auth.auth().currentUser?.email else {
//            print("No user is currently signed in, or the user does not have an email.")
//            return
//        }
//        var userId: String
//        if let uid = await fetchUserIdByEmail(userEmail) {
//            userId = uid
//            print("Found user_id: \(userId)")
//        } else {
//            userId = "u2"
//        }
        
        let userId = "u2"
        
        var profileUsername = UILabel()
        if let username = await fetchUsernamebyId(userId) {
            profileUsername.text = username
            print("Found username: \(profileUsername)")
        }
        else {
            profileUsername.text = "helloworld"
        }
        
        pUsername.text = profileUsername.text
        
        let postsRef = db.collection("posts")
        do {
            let postQuery = postsRef.whereField("user_id", isEqualTo: userId)
            let querySnapshot = try await postQuery.getDocuments()
//            print("HELLO")
            for document in querySnapshot.documents {
                let data = document.data()
                
                let nailId = data["nail_id"] as? String ?? ""
//                let userId = data["user_id"] as? String ?? ""
                
                print("nailId: \(nailId)")
//                print("userId: \(userId)")

                // Fetch nail image
                let nailQuery = db.collection("nails").whereField("nail_id", isEqualTo: nailId)
                let nailQuerySnapshot = try await nailQuery.getDocuments()
                if let nailDocument = nailQuerySnapshot.documents.first,
                   let nailImagePath = nailDocument.data()["image"] as? String {
//                    print("nailPath: \(nailImagePath)")
                                        
                    // Async fetch for nail and user images
                    let nailImage = UIImageView()
//                    let userImage = UIImageView()
                    
                    await withUnsafeContinuation { continuation in
                        self.fetchImage(from: nailImagePath) { image in
                            nailImage.image = image.image
                            continuation.resume()
                        }
                    }
                    
                    let postSavesLabel = UILabel()
                    postSavesLabel.text = "\(data["saves"] as? Int ?? 0)"
                    
                    // Create Post and append to data
                    let post = PostPreview(pp_image: nailImage, pp_saves: postSavesLabel)
                    
                    self.postPreviewDataArray.append(post)
                }
                
            }
//            print("postPreviewDataArray:\(self.postPreviewDataArray)")
        } catch let error {
            print("Error getting documents: \(error)")
        }
    }
    
    func fetchUserIdByEmail(_ userEmail: String) async -> String? {
//        let db = Firestore.firestore()
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
    
    func fetchUsernamebyId(_ userId: String) async -> String? {
//        let db = Firestore.firestore()
        do {
            let querySnapshot = try await db.collection("users").whereField("user_id", isEqualTo: userId).getDocuments()
            guard let userDocument = querySnapshot.documents.first else {
                print("No matching user document found")
                return nil
            }
            let username = userDocument.data()["username"] as? String
            return username
        } catch {
            print("Error fetching user document: \(error)")
            return nil
        }
    }
    
    private func fetchImage(from path: String, completion: @escaping (UIImageView) -> Void) {
        let imageView = UIImageView()
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child(path)
        print("path: \(path)")

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
