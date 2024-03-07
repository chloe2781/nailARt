//
//  ExploreTableViewController.swift
//  nailARt
//
//  Created by Chloe Nguyen on 3/5/24.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

let db = Firestore.firestore()
let storageRef = Storage.storage().reference()

struct Post {
    let p_image: UIImageView
    let p_author_image: UIImageView
    let p_title: UILabel
    let p_saves: UILabel
}
//    @IBOutlet weak var postImage: UIImageView!
//    @IBOutlet weak var postAuthorImage: UIImageView!
//    @IBOutlet weak var postTitle: UILabel!
//    @IBOutlet weak var postSaves: UILabel!

// test@gmail.com
// helloworld
class CustomTableCell: UITableViewCell {
    
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postAuthorImage: UIImageView!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postSaves: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
//@IBOutlet weak var postView: UITableView!
class ExploreView: UITableViewController {

    @IBOutlet var postView: UITableView!
    
    var postDataArray: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postView.rowHeight = UITableView.automaticDimension
        postView.estimatedRowHeight = 393
        
        Task {
            await getDataForPosts()
            DispatchQueue.main.async {
                self.postView.reloadData()
            }
        }
    }

    func getDataForPosts() async {
        let postsRef = db.collection("posts")
        do {
            let querySnapshot = try await postsRef.getDocuments()
            for document in querySnapshot.documents {
                let data = document.data()
                
                let nailId = data["nail_id"] as? String ?? ""
                let userId = data["user_id"] as? String ?? ""
                
                print("nailId: \(nailId)")
                print("userId: \(userId)")

                // Fetch nail image
                let nailQuery = db.collection("nails").whereField("nail_id", isEqualTo: nailId)
                let nailQuerySnapshot = try await nailQuery.getDocuments()
                if let nailDocument = nailQuerySnapshot.documents.first,
                   let nailImagePath = nailDocument.data()["image"] as? String {
                    print("nailPath: \(nailImagePath)")
                                        
                    // Async fetch for nail and user images
                    let nailImage = UIImageView()
                    let userImage = UIImageView()
                    
                    await withUnsafeContinuation { continuation in
                        self.fetchImage(from: nailImagePath) { image in
                            nailImage.image = image.image
                            continuation.resume()
                        }
                    }
                    
                    await withUnsafeContinuation { continuation in
                        self.fetchImage(from: nailImagePath) { image in
                            userImage.image = image.image
                            continuation.resume()
                        }
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
            print("postDataArray:\(self.postDataArray)")
        } catch let error {
            print("Error getting documents: \(error)")
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
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return postDataArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath) as? CustomTableCell else {
            return UITableViewCell()
        }
        
        let postData = postDataArray[indexPath.row]
        DispatchQueue.main.async {
            cell.postImage.image = postData.p_image.image
            cell.postAuthorImage.image = postData.p_author_image.image
            cell.postTitle.text = postData.p_title.text
            cell.postSaves.text = postData.p_saves.text
        }
        
        return cell
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
    



