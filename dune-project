(lang dune 3.14)

(using menhir 3.0)

(name hft_engine)

(package
 (name hft_engine)
 (synopsis "Distributed Type-Inferred HFT Database & Matching Engine")
 (depends
  (ocaml
   (>= 5.0.0))
  (dune
   (>= 3.14))
  (menhir
   (>= 3.0))
  (core
   (>= v0.17.0))
  (ppx_jane
   (>= v0.17.0))
  eio
  eio_main
  qcheck))
