import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

actor NFTCanister {
    // ICRC-7-like implementation
    var nfts = HashMap.HashMap<Text, NFT>(0, Text.equal, Text.hash);
    stable var nextId : Nat = 0;

    public type NFT = {
        owner : Principal;
        metadata : Text;
    };

    // Award achievement NFT
    public func awardAchievement(user : Principal, metadata : Text) : async Nat {
        let id = nextId;
        nfts.put(Nat.toText(id), { owner = user; metadata });
        nextId += 1;
        id;
    };
};
