import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

actor UserCanister {
    let users = HashMap.HashMap<Text, UserProfile>(0, Text.equal, Text.hash);
    let posts = HashMap.HashMap<Text, Post>(0, Text.equal, Text.hash);
    // Index: Mapea User principalId de los IDs de los Posts
    let userPostsIndex = HashMap.HashMap<Text, [Text]>(0, Text.equal, Text.hash);
    stable var nextPostId : Nat = 1;

    public type UserProfile = {
        principalId : Text; // Stored as text for II compatibility
        username : Text;
        bio : Text;
        avatarUrl : Text;
        joinedAt : Time.Time;
    };

    public type Post = {
        id : Text;
        authorId : Text;
        content : Text;
        timestamp : Time.Time;
        likes : [Text];
        comments : [Comment];
        shares : Nat;
    };

    public type Comment = {
        authorId : Text;
        content : Text;
        timestamp : Time.Time;
    };

    // Internet Identity Authentication
    public shared ({ caller }) func authenticate() : async UserProfile {
        // Deny anonymous principals
        // if (Principal.isAnonymous(caller)) {
        //     throw Error.reject("Authentication required - please use Internet Identity");
        // };

        let existingUser = users.get(Principal.toText(caller));

        switch (existingUser) {
            case (?user) { user };
            case null {
                let username = "user-" # Principal.toText(caller);
                let avatarUrl = "http://www.clsdmrs.com/profile/" # Principal.toText(caller);
                let newUser = createUser(Principal.toText(caller), username, avatarUrl);
                return newUser;
            };
        };
    };

    func authenticateWithCaller(caller : Principal) : async UserProfile {
        // Deny anonymous principals
        // if (Principal.isAnonymous(caller)) {
        //     throw Error.reject("Authentication required - please use Internet Identity");
        // };

        let existingUser = users.get(Principal.toText(caller));

        switch (existingUser) {
            case (?user) { user };
            case null {
                let username = "user-" # Principal.toText(caller);
                let avatarUrl = "http://www.clsdmrs.com/profile/" # Principal.toText(caller);
                let newUser = createUser(Principal.toText(caller), username, avatarUrl);
                return newUser;
            };
        };
    };

    // CRUD Operations

    // Create users
    func createUser(id : Text, username : Text, avatarUrl : Text) : UserProfile {
        let newUser = {
            principalId = id;
            username = username;
            bio = "";
            avatarUrl = avatarUrl;
            joinedAt = Time.now();
        };
        users.put(id, newUser);
        newUser;
    };

    // Create a Post
    public shared ({ caller }) func createPost(content : Text) : async Post {
        let user = await authenticateWithCaller(caller);

        let postId = Nat.toText(nextPostId);
        nextPostId += 1;

        let newPost : Post = {
            id = postId;
            authorId = user.principalId;
            content = content;
            timestamp = Time.now();
            likes : [Text] = [];
            comments : [Comment] = [];
            shares = 0;
        };

        // Add to posts
        posts.put(postId, newPost);

        // Update index
        let currentPosts = switch (userPostsIndex.get(user.principalId)) {
            case (?posts) posts;
            case null [];
        };
        userPostsIndex.put(user.principalId, Array.append(currentPosts, [postId]));

        newPost;
    };

    // Create Comment
    public shared ({ caller }) func addComment(postId : Text, content : Text) {
        let authorId = (await authenticateWithCaller(caller)).principalId;
        let post = await getPost(postId);

        switch (post) {
            case (?currentPost) {
                let newComment = {
                    authorId = authorId;
                    content = content;
                    timestamp = Time.now();
                };

                let updatedComments = Array.append(currentPost.comments, [newComment]);
                let updatedPost = {
                    currentPost with comments = updatedComments
                };

                posts.put(postId, updatedPost);
            };
            case (null) {
                throw Error.reject("There is no comment to add.");
            };
        };
    };

    // Read users
    public query func getUser(id : Text) : async ?UserProfile {
        users.get(id);
    };

    public query func getUsers() : async [(Text, UserProfile)] {
        Iter.toArray(users.entries());
    };

    // Read Posts
    public query func getAllPosts() : async [(Text, Post)] {
        Iter.toArray(posts.entries());
    };

    public query func getAllUserPosts(principalId : Text) : async [Post] {
        let postIds = switch (userPostsIndex.get(principalId)) {
            case (?ids) ids;
            case null [];
        };

        Array.mapFilter<Text, Post>(
            postIds,
            func(postId : Text) : ?Post {
                posts.get(postId) // Returns ?Post (some or null)
            },
        );
    };

    public query func getPost(postId : Text) : async ?Post {
        posts.get(postId);
    };

    // Update User
    public shared ({ caller }) func updateProfile(
        username : Text,
        bio : Text,
        avatarUrl : Text,
    ) : async UserProfile {
        // if (Principal.isAnonymous(caller)) {
        //     throw Error.reject("Authentication required");
        // };

        let user = await authenticateWithCaller(caller);

        let updatedUser : UserProfile = {
            user with
            username;
            bio;
            avatarUrl;
        };
        users.put(user.principalId, updatedUser);
        updatedUser;
    };

    // Update Post
    public shared ({ caller }) func updatePost(id : Text, new_content : Text) {
        let user = await authenticateWithCaller(caller);
        let post : ?Post = posts.get(id);
        switch (post) {
            case (null) {
                throw Error.reject("Post no encontrado");
            };
            case (?currentPost) {
                let newPost : Post = { currentPost with content = new_content };
                posts.put(id, newPost);
                Debug.print("Post actualizado");
            };
        };
    };

    // Add likes to Post
    public shared ({ caller }) func likePost(postId : Text) {
        let userId = (await authenticateWithCaller(caller)).principalId;
        let post : ?Post = await getPost(postId);
        switch (post) {
            case (null) {
                throw Error.reject("Post no encontrado");
            };
            case (?currentPost) {
                let existingLikeIndex = Array.indexOf<Text>(userId, currentPost.likes, Text.equal);
                let newLikes = if (Option.isSome(existingLikeIndex)) Array.filter<Text>(currentPost.likes, func(x) = x != userId) else Array.append(currentPost.likes, [userId]);
                let newPost : Post = {
                    currentPost with likes = newLikes;
                };
                posts.put(postId, newPost);
                Debug.print("Post actualizado");
            };
        };
    };

    // Delete Profile
    public shared ({ caller }) func deleteProfile() {
        let principalId = (await authenticateWithCaller(caller)).principalId;

        switch (userPostsIndex.get(principalId)) {
            case (?postIds) {
                for (postId in postIds.vals()) {
                    posts.delete(postId);
                };
                userPostsIndex.delete(principalId);
            };
            case null {};
        };

        users.delete(principalId);
    };

    // Delete Post
    public shared ({ caller }) func deletePost(postId : Text) : async () {
        let user = await authenticateWithCaller(caller);
        let post = posts.get(postId);
        switch (post) {
            case (?currentPost) {
                // Remove from index
                let userPosts = userPostsIndex.get(currentPost.authorId);
                switch (userPosts) {
                    case (?postIds) {
                        let filteredIds = Array.filter<Text>(postIds, func(id : Text) : Bool { id != postId });
                        userPostsIndex.put(currentPost.authorId, filteredIds);
                    };
                    case null {};
                };

                // Delete post (comments die with it)
                posts.delete(postId);
            };
            case null {
                throw Error.reject("Post not found");
            };
        };
    };

};
