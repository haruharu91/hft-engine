open Core

module Order : sig
  type side = Buy | Sell [@@deriving sexp, bin_io]

  type t = {
    id : int64;
    price : int64;
    qty : int64;
    side : side;
  }
  [@@deriving sexp, bin_io]
end

module OrderBook : sig
  type t

  val empty : t
  val add_order : t -> Order.t -> t * Order.t list
end

type log_entry = Command of string | Noop [@@deriving sexp, bin_io]

module RaftNode : sig
  type state = Leader | Follower | Candidate

  type t = {
    mutable state : state;
    mutable current_term : int64;
    mutable log : log_entry Array.t;
    book : OrderBook.t ref;
  }

  val apply_command : t -> string -> unit
  val run_loop : t -> unit
end