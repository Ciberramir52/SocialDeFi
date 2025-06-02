import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Iter "mo:base/Iter";

actor NFTCanister {
    // ICRC-7-like implementation
    var nfts = HashMap.HashMap<Text, NFT>(0, Text.equal, Text.hash);
    stable var nextId : Nat = 0;

    public type NFT = {
        owner : Principal;
        metadata : Text;
    };

    public type OwnedNFT = {
        id : Text;
        owner : Principal;
        metadata : Text;
    };

    // Get NFTs by owner
    public query func getNFTsByOwner(owner : Principal) : async [OwnedNFT] {
        Iter.toArray(
            Iter.map(
                Iter.filter(
                    nfts.entries(),
                    func((_ : Text, nft : NFT)) : Bool { nft.owner == owner },
                ),
                func((id : Text, nft : NFT)) : OwnedNFT {
                    {
                        id = id;
                        owner = nft.owner;
                        metadata = nft.metadata;
                    };
                },
            )
        );
    };

    // Award achievement NFT
    public func awardAchievement(user : Principal, metadata : Text) : async Nat {
        let id = nextId;
        nfts.put(Nat.toText(id), { owner = user; metadata });
        nextId += 1;
        id;
    };

};
