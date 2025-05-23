import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";

actor UserCanister {
  stable var users : [UserProfile] = [];
  stable var posts : [Post] = [];
  stable var nextUserId : Nat = 1;
  stable var nextPostId : Nat = 1;
  let postList = HashMap.HashMap<Text, Post>(0, Text.equal, Text.hash);

  // Internet Identity principal type
  // public type Principal = actor {
  //   getPrincipal : () -> async Text;
  // };

  public type UserProfile = {
    id : Nat;
    principalId : Text; // Stored as text for II compatibility
    username : Text;
    bio : Text;
    avatarUrl : Text;
    joinedAt : Time.Time;
  };

  public type Post = {
    id : Nat;
    authorId : Nat;
    content : Text;
    timestamp : Time.Time;
    likes : [Nat];
    comments : [Comment];
    shares : Nat;
  };

  public type Comment = {
    authorId : Nat;
    content : Text;
    timestamp : Time.Time;
  };

  // Internet Identity Authentication
  public shared ({ caller }) func authenticate() : async UserProfile {
    let existingUser = Array.find(
      users,
      func(u : UserProfile) : Bool {
        u.principalId == Principal.toText(caller);
      },
    );

    switch (existingUser) {
      case (?user) { user };
      case null {
        let newUser = createUser(Principal.toText(caller), "", "");
        return newUser;
      };
    };
  };

  // CRUD Operations
  func createUser(principalId : Text, username : Text, avatarUrl : Text) : UserProfile {
    let newUser = {
      id = nextUserId;
      principalId = principalId;
      username = username;
      bio = "";
      avatarUrl = avatarUrl;
      joinedAt = Time.now();
    };
    users := Array.append<UserProfile>(users, [newUser]);
    nextUserId += 1;
    newUser;
  };

  // Find user index by principal id
  func findUserIndexByPrincipal(principalId : Text) : Nat {
    var index : Nat = 0;
    for (user in users.vals()) {
      if (user.principalId == principalId) {
        return index;
      };
      index += 1;
    };
    assert false;
    0 // Manejar error adecuadamente en producción
  };

  public shared ({ caller }) func updateProfile(username : Text, bio : Text, avatarUrl : Text) : async UserProfile {
    let principalId = Principal.toText(caller);
    let index = findUserIndexByPrincipal(principalId);

    let updatedUser = {
      id = users[index].id;
      principalId = principalId;
      username = username;
      bio = bio;
      avatarUrl = avatarUrl;
      joinedAt = users[index].joinedAt;
    };

    users := Array.tabulate<UserProfile>(
      users.size(),
      func(i) {
        if (i == index) updatedUser else users[i];
      },
    );

    updatedUser;
  };

  private func generate_post_id() : Nat {
    nextPostId += 1;
    return nextPostId;
  };

  // Social Interactions
  public func createPost(content : Text) : async Post {
    let authorId = (await authenticate()).id;
    let newPost = {
      id = nextPostId;
      authorId = authorId;
      content = content;
      timestamp = Time.now();
      likes : [Nat] = [];
      comments : [Comment] = [];
      shares = 0;
    };
    posts := Array.append<Post>(posts, [newPost]);
    postList.put(Nat.toText(nextPostId), newPost);
    nextPostId += 1;
    newPost;
  };

  // Find user index by principal id
  func findPostById(postId : Nat) : Nat {
    var index : Nat = 0;
    for (post in posts.vals()) {
      if (post.id == postId) {
        return index;
      };
      index += 1;
    };
    assert false;
    0 // Manejar error adecuadamente en producción
  };

  public func likePost(postId : Nat) : async Post {
    let userId = (await authenticate()).id;
    let index = findPostById(postId);

    let updatedLikes = Array.append(posts[index].likes, [userId]);
    let updatedPost = {
      posts[index] with likes = updatedLikes
    };

    posts := Array.tabulate<Post>(
      posts.size(),
      func(i) {
        if (i == index) updatedPost else posts[i];
      },
    );

    updatedPost;
  };

  public func likePost2(postId : Nat) {
    let userId = (await authenticate()).id;
    let post: ?Post = await getPost(Nat.toText(postId));
    switch (post) {
      case (null) {
        Debug.print("Post no encontrado");
      };
      case (?currentPost) {
        let newPost: Post = { currentPost with likes = Array.append(currentPost.likes, [userId]) };
        postList.put(Nat.toText(postId), newPost);
        Debug.print("Post actualizado");
      };
    };
  };

  public func addComment(postId : Nat, content : Text) : async Post {
    let authorId = (await authenticate()).id;
    let index = findPostById(postId);

    let newComment = {
      authorId = authorId;
      content = content;
      timestamp = Time.now();
    };

    let updatedComments = Array.append(posts[index].comments, [newComment]);
    let updatedPost = {
      posts[index] with comments = updatedComments
    };

    posts := Array.tabulate<Post>(
      posts.size(),
      func(i) {
        if (i == index) updatedPost else posts[i];
      },
    );

    updatedPost;
  };

  public query func getPosts() : async [Post] {
    posts;
  };

  public query func getPost(id : Text) : async ?Post {
    postList.get(id);
  };

  public query func getPosts2() : async [(Text, Post)] {
    Iter.toArray(postList.entries());
  };

  public func updatePost(id : Text, new_content : Text) {
    let post : ?Post = postList.get(id);
    switch (post) {
      case (null) {
        Debug.print("Post no encontrado");
      };
      case (?currentPost) {
        let newPost: Post = { currentPost with content = new_content };
        postList.put(id, newPost);
        Debug.print("Post actualizado");
      };
    };
  };

  public query func deletePost(id: Text): async ?Post {
    postList.remove(id);
  };
};
