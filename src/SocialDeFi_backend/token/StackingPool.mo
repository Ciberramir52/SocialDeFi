import TokenCanister "canister:TokenCanister";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

actor StakingPool {
  type Stake = { amount : Nat; stakedAt : Int };
  let stakes = HashMap.HashMap<Principal, Stake>(0, Principal.equal, Principal.hash);
  let apr = 15; // 15% annual yield

  // Stake tokens
  public shared ({ caller }) func stake(amount : Nat) : async () {
    let success = await TokenCanister.transfer(caller, Principal.fromActor(StakingPool), amount);
    assert(success);
    
    stakes.put(caller, {
      amount;
      stakedAt = Time.now();
    });
  };

  // Calculate rewards
  func calculateRewards(user : Principal) : Nat {
    let stake = Option.get(stakes.get(user), { amount = 0; stakedAt = 0 });
    let duration = (Time.now() - stake.stakedAt) / 31_540_000_000_000; // Convert nanoseconds to years
    Int.abs(stake.amount * apr * duration / 100)
  };

  // Claim rewards
  public shared ({ caller }) func claim() : async () {
    let rewards = calculateRewards(caller);
    await TokenCanister.mint(caller, rewards);
  };

  // Unstake
  public shared ({ caller }) func unstake() : async () {
    let stake = Option.get(stakes.get(caller), { amount = 0; stakedAt = 0 });
    let success = await TokenCanister.transfer(Principal.fromActor(StakingPool), caller, stake.amount);
    assert(success);
    stakes.delete(caller);
  };
};
