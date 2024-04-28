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

    @IBAction func explore(_ sender: Any) {
        self.performSegue(withIdentifier: "profileToExplore", sender: self)
    }
    
    @IBAction func seenail(_ sender: Any) {
        self.performSegue(withIdentifier: "profileToSeenail", sender: self)
    }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBAction func savedButtonAction(_ sender: Any) {
        self.performSegue(withIdentifier: "profileToSaved", sender: self)
    }
    @IBAction func profileToFollowing(_ sender: Any) {
        self.performSegue(withIdentifier: "profileToFollowing", sender: self)
    }
    
    @IBOutlet weak var pUsername: UILabel!
    @IBOutlet weak var pImage: UIImageView!
    @IBOutlet weak var menuBar: UIView!
    @IBOutlet weak var numDesigns: UILabel!
    @IBOutlet weak var numFollows: UILabel!
    @IBOutlet weak var savedButton: UIButton!
    
    var postPreviewDataArray: [PostPreview] = []
    
    var lastDocumentSnapshot: DocumentSnapshot? // Used for pagination
    var isFetchingMore = false // Flag to prevent multiple simultaneous fetches
    
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = UIActivityIndicatorView(style: .medium)
        self.view.addSubview(activityIndicator)
        activityIndicator.center = self.view.center
        
        self.overrideUserInterfaceStyle = .light
        
        collectionView.delegate = self
        collectionView.dataSource = self

        menuBar.layer.cornerRadius = 25
        savedButton.layer.cornerRadius = 8
        
        collectionView.clipsToBounds = false
        collectionView.showsVerticalScrollIndicator = false
        
        pImage.layer.cornerRadius = 50
        
        loadData()
        
//        Task {
//            await fetchPostPreviews()
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        activityIndicator.startAnimating()
//        Task {
//            await fetchPostPreviews()
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
//        }
    }
    
    func loadData() {
        
        guard !isFetchingMore else { return }
        isFetchingMore = true
    
        Task {
            // loop here
            var continueLoading = true

            while continueLoading {
                await fetchPostPreviews()
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
                self.activityIndicator.stopAnimating()
                
                continueLoading = lastDocumentSnapshot != nil
            }
            
            DispatchQueue.main.async {
                self.isFetchingMore = false
                
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
        
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("No user is currently signed in, or the user does not have an email.")
            return
        }
        
        var userId: String
        if let uid = await fetchUserIdByEmail(userEmail) {
            userId = uid
            print("Found user_id: \(userId)")
        } else {
            userId = "u2"
        }
        
//        let userId = "u2"
        
        var profileUsername = UILabel()
        if let username = await fetchUsernamebyId(userId) {
            profileUsername.text = username
            print("Found username: \(profileUsername)")
        }else {
            profileUsername.text = "helloworld"
        }
        
        pUsername.text = profileUsername.text
        
        var follows = UILabel()
        if let numFollows = await fetchFollowbyId(userId) {
            follows.text = numFollows
            print("Found num follows: \(follows)")
        }else {
            follows.text = "?"
        }
        
        numFollows.text = follows.text
        
        var profileImage = UIImageView()
        if let picPath = await fetchProfilePathbyId(userId) {
            await withUnsafeContinuation { continuation in
                self.fetchImage(from: picPath) { image in
                    profileImage.image = image.image
                    continuation.resume()
                }
            }
            print("Found profile pic")
        }else {
            profileImage.image = UIImage(named: "profilePicHolder")
        }
        
        pImage.image = profileImage.image
        
        let postsRef = db.collection("posts")
        var postQuery = postsRef.whereField("user_id", isEqualTo: userId).limit(to: 1)
        
        if let lastSnapshot = lastDocumentSnapshot {
            postQuery = postQuery.start(afterDocument: lastSnapshot)
        }
        
        do {
            let querySnapshot = try await postQuery.getDocuments()
//            print("HELLO")
            lastDocumentSnapshot = querySnapshot.documents.last
            numDesigns.text = String(querySnapshot.documents.count)
            for document in querySnapshot.documents {
                let data = document.data()
                
                let nailId = data["nail_id"] as? String ?? ""
//                let userId = data["user_id"] as? String ?? ""
                
//                print("nailId: \(nailId)")
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
    
    func fetchUsernamebyId(_ userId: String) async -> String? {
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
    
    func fetchFollowbyId(_ userId: String) async -> String? {
        do {
            let querySnapshot = try await db.collection("users").whereField("user_id", isEqualTo: userId).getDocuments()
            guard let userDocument = querySnapshot.documents.first else {
                print("No matching user document found")
                return nil
            }
            let follow = userDocument.data()["follow"] as? [String] ?? []
            let numFollow = follow.count
            return String(numFollow)
        } catch {
            print("Error fetching user document: \(error)")
            return nil
        }
    }
    
    func fetchProfilePathbyId(_ userId: String) async -> String? {
        do {
            let querySnapshot = try await db.collection("users").whereField("user_id", isEqualTo: userId).getDocuments()
            guard let userDocument = querySnapshot.documents.first else {
                print("No matching user document found")
                return nil
            }
            let pic_path = userDocument.data()["profile_pic"] as? String
            return pic_path
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
