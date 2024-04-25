//
//  ExploreViewController.swift
//  nailARt
//
//  Created by Chloe Nguyen on 4/1/24.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

let db = Firestore.firestore()
let storageRef = Storage.storage().reference()

class CustomTableCell: UITableViewCell {
    
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postAuthorImage: UIImageView!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postSaves: UILabel!
    @IBOutlet weak var postImageBackground: UIImageView!
    @IBOutlet weak var postContainer: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        postImageBackground.layer.cornerRadius = 37
        postAuthorImage.layer.cornerRadius = 35
        
        // Configure the shadow for postImageBackground
        postImageBackground.layer.shadowColor = UIColor.black.cgColor
        postImageBackground.layer.shadowOpacity = 0.25
        postImageBackground.layer.shadowOffset = CGSize(width: 8, height: 9)
        postImageBackground.layer.shadowRadius = 5
        
        // Configure the shadow for postContainer
        postContainer.layer.shadowColor = UIColor.black.cgColor
        postContainer.layer.shadowOpacity = 0.15
        postContainer.layer.shadowOffset = CGSize(width: 10, height: 11)
        postContainer.layer.shadowRadius = 5
        
        postImageBackground.layer.masksToBounds = false
        postContainer.layer.masksToBounds = false
    }
}


struct Post {
    let p_image: UIImageView
    let p_author_image: UIImageView
    let p_title: UILabel
    let p_saves: UILabel
}

class ExploreViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var postView: UITableView!
    @IBOutlet weak var menuBar: UIView!
    @IBAction func profile(_ sender: Any) {
        self.performSegue(withIdentifier: "exploreToProfile", sender: self)
    }
    
    @IBAction func seenail(_ sender: Any) {
        self.performSegue(withIdentifier: "exploreToSeenail", sender: self)
    }
    var postDataArray: [Post] = []
    var lastDocumentSnapshot: DocumentSnapshot? // Used for pagination
    var isFetchingMore = false // Flag to prevent multiple simultaneous fetches
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = UIActivityIndicatorView(style: .medium)
        self.view.addSubview(activityIndicator)
        
        
        self.overrideUserInterfaceStyle = .light
        
        menuBar.layer.cornerRadius = 25
        
        postView.delegate = self
        postView.dataSource = self
        
        postView.clipsToBounds = false
        postView.showsVerticalScrollIndicator = false
        
        
        activityIndicator.center = self.view.center
        
        
        loadData()
                
//        Task {
//            await getDataForPosts()
//            DispatchQueue.main.async {
//                self.postView.reloadData()
//            }
//        }
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
                await getDataForPosts()
                DispatchQueue.main.async {
                    self.postView.reloadData()
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
        return postDataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath) as? CustomTableCell else {
            return UITableViewCell()
        }
        
        let postData = postDataArray[indexPath.row]

        cell.postImage.image = postData.p_image.image
        cell.postAuthorImage.image = postData.p_author_image.image
        cell.postTitle.text = postData.p_title.text
        cell.postSaves.text = postData.p_saves.text
        
        return cell
    }
    
    func getDataForPosts() async {
        let postsRef = db.collection("posts")
        var query = postsRef.order(by: "date", descending: true).limit(to: 2)
        if let lastSnapshot = lastDocumentSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }
        
        do {
            let querySnapshot = try await query.getDocuments()
//            print("HELLO")
            lastDocumentSnapshot = querySnapshot.documents.last
            for document in querySnapshot.documents {
                let data = document.data()
                
                let nailId = data["nail_id"] as? String ?? ""
                let userId = data["user_id"] as? String ?? ""
                
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
                    let userImage = UIImageView()
                    
                    await withUnsafeContinuation { continuation in
                        self.fetchImage(from: nailImagePath) { image in
                            nailImage.image = image.image
                            continuation.resume()
                        }
                    }
                    
                    if let picPath = await fetchProfilePathbyId(userId) {
                        await withUnsafeContinuation { continuation in
                            self.fetchImage(from: picPath) { image in
                                userImage.image = image.image
                                continuation.resume()
                            }
                        }
//                        print("Found profile pic")
                    }else {
                        userImage.image = UIImage(named: "profilePicHolder")
                    }
                    
                    let postTitleLabel = UILabel()
                    postTitleLabel.text = data["title"] as? String ?? ""
                    
                    let postSavesLabel = UILabel()
                    postSavesLabel.text = "\(data["saves"] as? Int ?? 0)"
                    
                    // Create Post and append to data
                    let post = Post(p_image: nailImage, p_author_image: userImage, p_title: postTitleLabel, p_saves: postSavesLabel)
                    
                    self.postDataArray.append(post)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
