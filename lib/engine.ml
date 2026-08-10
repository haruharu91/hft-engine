open Core

module Order = struct
  type side = Buy | Sell [@@deriving sexp, bin_io]

  type t = {
    id: int64;
    price: int64;
    qty: int64;
    side: side;
  } [@@deriving sexp, bin_io]
end

module OrderBook = struct
  type t = {
    _bids: Order.t list Map.M(Int64).t;
    _asks: Order.t list Map.M(Int64).t;
  }

  let empty = {
    _bids = Map.empty (module Int64);
    _asks = Map.empty (module Int64);
  }

  let add_order book (_order : Order.t) : t * Order.t list =
    (book, [])
end

type log_entry =
  | Command of string
  | Noop
[@@deriving sexp, bin_io]

module RaftNode = struct
  type state = Leader | Follower | Candidate

  type t = {
    mutable state: state;
    mutable current_term: int64;
    mutable log: log_entry Array.t;
    book: OrderBook.t ref;
  }

  type _ Effect.t += 
    | BroadcastLog : log_entry -> unit Effect.t

  let apply_command _node (_cmd_bytecode : string) =
    ()

  let run_loop (_node : t) =
    Effect.Deep.match_with
      (fun () ->
         Effect.perform (BroadcastLog (Command "FILTER price > 1000 THEN MATCH")))
      ()
      {
        retc = (fun () -> ());
        exnc = (fun e -> raise e);
        effc = (fun (type a) (eff : a Effect.t) ->
          match eff with
          | BroadcastLog _entry -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
              Effect.Deep.continue k ())
          | _ -> None);
      }
end