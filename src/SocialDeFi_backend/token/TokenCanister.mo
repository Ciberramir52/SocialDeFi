import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";

actor TokenCanister {
  // ICRC-1 Configuration
  let tokenName = "SOCIAL";
  let tokenSymbol = "SOCIAL";
  let decimals : Nat8 = 8;
  let fee = 10_000; // 0.0001 SOCIAL

  // Stable storage for upgrades
  stable var entries : [(Principal, Nat)] = [];
  stable var totalSupply : Nat = 0;
  stable var authorizedMinters : [Principal] = [];

  public query func icrc1_name() : async Text { tokenName };
  public query func icrc1_symbol() : async Text { tokenSymbol };
  public query func icrc1_decimals() : async Nat8 { decimals };
  public query func icrc1_fee() : async Nat { fee };
  public query func icrc1_total_supply() : async Nat { totalSupply };
  public query func icrc1_balance_of(args : { account : Principal }) : async Nat {
    Option.get(balances.get(args.account), 0);
  };

  // Initialize balances from stable entries
  let balances = HashMap.fromIter<Principal, Nat>(
    entries.vals(),
    0,
    Principal.equal,
    Principal.hash,
  );

  system func postupgrade() {
    entries := Iter.toArray(balances.entries());
  };

  // Mint tokens (callable by authorized minters)
  public func mint(receiver : Principal, amount : Nat) : async () {
    assert (Array.indexOf(receiver, authorizedMinters, Principal.equal) != null);

    let current = Option.get(balances.get(receiver), 0);
    balances.put(receiver, current + amount);
    Debug.print(Principal.toText(receiver) # Nat.toText(current + amount));
    totalSupply += amount;
  };

  // Add/remove authorized minters
  public func authorizeMinter(minter : Principal) : async () {
    authorizedMinters := Array.append(authorizedMinters, [minter]);
  };

  // Transfer tokens (ICRC-1 compliant)
  public shared func transfer(from : Principal, to : Principal, amount : Nat) : async Bool {
    let fromBalance = Option.get(balances.get(from), 0);
    if (fromBalance >= amount + fee) {
      balances.put(from, fromBalance - amount - fee);
      let toBalance = Option.get(balances.get(to), 0);
      balances.put(to, toBalance + amount);
      Debug.print(Principal.toText(from) # Nat.toText(fromBalance - amount - fee));
      Debug.print(Principal.toText(to) # Nat.toText(toBalance + amount));
      true;
    } else {
      false;
    };
  };
};
