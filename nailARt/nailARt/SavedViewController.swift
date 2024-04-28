//
//  SavedViewController.swift
//  nailARt
//
//  Created by Chloe Nguyen on 4/23/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class CustomCollectionViewCellSaved: UICollectionViewCell {
    
    @IBOutlet weak var cellBackground: UIImageView!
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

class SavedViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource  {
    
    @IBOutlet var sCollectionView: UICollectionView!
    @IBAction func backToProfile(_ sender: Any) {
        self.performSegue(withIdentifier: "savedToProfile", sender: self)
    }
    
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
        
        sCollectionView.delegate = self
        sCollectionView.dataSource = self
        
        sCollectionView.clipsToBounds = false
        sCollectionView.showsVerticalScrollIndicator = false
        
        loadData()
        // Do any additional setup after loading the view.
    }
    
    func collectionView(_ sCollectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postPreviewDataArray.count
    }
    
    func collectionView(_ sCollectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = sCollectionView.dequeueReusableCell(withReuseIdentifier: "myCollectionCellSaved", for: indexPath) as? CustomCollectionViewCellSaved else {
            return UICollectionViewCell()
        }
        
        let postPreview = postPreviewDataArray[indexPath.item]
        cell.cellImage.image = postPreview.pp_image.image
        cell.cellSaves.text = postPreview.pp_saves.text
        
        return cell
    }
    
    func loadData() {
        guard !isFetchingMore else { return }
        isFetchingMore = true
    
        Task {
            // loop here
            var continueLoading = true

            while continueLoading {
                await getDataForPosts()
                DispatchQueue.main.async {
                    self.sCollectionView.reloadData()
                }
                self.activityIndicator.stopAnimating()
                
                continueLoading = lastDocumentSnapshot != nil
            }
            
            DispatchQueue.main.async {
                self.isFetchingMore = false
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        activityIndicator.startAnimating()
    }
    
    func getDataForPosts() async {
        
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
        
//        userId = "u2"
        
        guard let savedPostIds = await fetchSavedRef(userId) else {
                print("Failed to fetch saved post IDs or no saved posts available.")
                return
            }
        if savedPostIds.isEmpty {
            print("No saved posts for this user.")
            return
        }

        let postsRef = db.collection("posts")
        var query = postsRef.whereField("post_id", in: savedPostIds).limit(to: 1)
        if let lastSnapshot = lastDocumentSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }
        
        do {
            let querySnapshot = try await query.getDocuments()
//            print("HELLO")
            lastDocumentSnapshot = querySnapshot.documents.last
            
            if querySnapshot.documents.isEmpty {
                        lastDocumentSnapshot = nil // Reset if no documents are fetched
                        return
                    }
            
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
//            print("postDataArray:\(self.postDataArray)")
        } catch let error {
            print("Error getting documents: \(error)")
            lastDocumentSnapshot = nil
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating() // Stop animating on error
            }
        }
    }
    
    func fetchSavedRef(_ userId: String) async -> [String]? {
        do {
            let querySnapshot = try await db.collection("users").whereField("user_id", isEqualTo: userId).getDocuments()
            guard let userDocument = querySnapshot.documents.first else {
                print("No matching user document found")
                return nil
            }
            let saved = userDocument.data()["saved"] as? [String] ?? []
            return saved
        } catch {
            print("Error fetching user document: \(error)")
            return nil
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



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
