# High-Frequency Trading Engine (`hft_engine`)

A high-performance, type-inferred quantitative execution database and matching engine written in OCaml 5 (`Core`, `Eio`).

`hft_engine` supports multiple surface syntaxes—including a **Japanese-inspired Subject-Object-Verb (SOV) postposition syntax**—all compiling down to a single, row-polymorphic Abstract Syntax Tree (`Ast.expr`).

---

## Key Features

* **Multi-Dialect Architecture:** Choose the syntax that best matches your workflow (SOV, Infix (Formal Proof-like), or S-Expressions).
* **Strict File-Level Syntax Isolation:** Enforces exactly one syntax dialect per file via versioned extensions (`.sov.hft`, `.infix.hft`, `.sexp.hft`).
* **Role-Marked Postpositions (SOV):** Particle case markers (`ga`, `wo`/`o`, `ni`, `de`, `kara`, `no`) allow free word order while preserving deterministic, type-safe role mapping.
* **Bi-Directional AST Transpiler:** Convert source code cleanly between any supported syntax format without modifying runtime behavior.
* **Zero-Allocation Memory Model:** Record-lowered particle roles map directly to fixed stack structures for hot-path execution.
* **Cross-Platform Native Target:** Compiles natively via `ocamlopt` to standalone binaries on macOS (`x86_64`, `arm64`) and Linux (`x86_64`, `aarch64`).

---

## File Extension Conventions

Files must use the base `.hft` extension prefixed with their syntax dialect:

| File Extension | Syntax Dialect | Description |
| --- | --- | --- |
| `*.sov.hft` | **SOV Postpositions** | Free word-order syntax using Japanese-style particles. |
| `*.infix.hft` | ** Infix-based like Proof Notation** | Infix sequent calculus-like infix notation |
| `*.sexp.hft` | **S-Expressions** | Canonical Lisp-style wire format for logging and Raft IPC. |

---

## Particle Semantic Mapping (SOV Dialect)

In `*.sov.hft` files, postpositions tag expressions with semantic roles before the final verb/action. This provides syntactic freedom similar to inflected natural languages (e.g., Japanese, Russian) while mapping directly to Hindley-Milner record labels in OCaml:

| Particle | Case Role | HFT Query Role | Semantic Function |
| --- | --- | --- | --- |
| **`ga`** | Nominative | `subject` | Primary entity, symbol, or order book instance |
| **`wo` / `o**` | Accusative | `object` | Data payload, order struct, or execution record |
| **`ni`** | Dative / Allative | `destination` | Sink node, matching engine, or output socket |
| **`de`** | Instrumental | `condition` | Filter predicate, execution condition, or lambda |
| **`kara`** | Ablative | `source` | Input socket, market data feed, or event stream |
| **`no`** | Genitive | `genitive_access` | Qualifier / member field access (`record no field`) |

---

## Dialect Examples & AST Representation

Consider a query that filters ticks from `tick_stream` where `price > 100.0` and sends them to `matching_engine`.

### 1. Japanese SOV Syntax (`query.sov.hft`)

Because each argument is tagged by its postposition, word order before the verb `filter_and_emit` is completely flexible:

```text
tick_stream kara  (price > 100.0) de  matching_engine ni  filter_and_emit

```

*Equivalent free word-order variation:*

```text
(price > 100.0) de  matching_engine ni  tick_stream kara  filter_and_emit

```

### 2. Formal Proof Syntax (`query.infix.hft`)

```text
tick_stream |- filter_and_emit (price > 100.0) |- emit @matching_engine

```

### 3. S-Expression Wire Syntax (`query.sexp.hft`)

```lisp
(filter_and_emit tick_stream (gt price 100.0) matching_engine)

```

### Unified AST Output

All three frontends compile to the identical row-polymorphic record representation:

```ocaml
App (
  Var "filter_and_emit",
  RecordCons ("source", Var "tick_stream",
    RecordCons ("condition", BinOp (Gt, Var "price", Lit (Float 100.0)),
      RecordCons ("destination", Var "matching_engine",
        Lit (Bool true)
      )
    )
  )
)

```

---

## Transpiler Utility

The repository includes a transpiler to convert files between dialects:

```bash
# Convert Japanese SOV syntax into Infix syntax, similar to formal proofs
dune exec hft_transpiler -- --from sov --to infix queries/trade.sov.hft -o queries/trade.infix.hft

# Convert Proof syntax into S-Expressions for network serialisation
dune exec hft_transpiler -- --from infix --to sexp queries/trade.infix.hft -o queries/trade.sexp.hft

```

---

## Building, Testing & Cross-Platform Releases

### Prerequisites

* **OCaml:** 5.0.0 or higher
* **Dune:** 3.14 or higher
* **Menhir:** 3.0 or higher
* **Opam Packages:** `core`, `ppx_jane`, `eio`, `eio_main`

### Local Development Commands

```bash
# Clean build environment
dune clean

# Build all libraries, parsers, and executables
dune build

# Run unit and inline tests
dune runtest

# Execute the main verification binary
dune exec bin/main.exe

```

---

## Cross-Platform Binary Compilation

Dune uses `.exe` internally as a target suffix across all OS targets (e.g., `main.exe`). On Unix systems (macOS/Linux), `dune build` produces native Mach-O or ELF binaries rather than Windows PE files.

### 1. Release Builds (macOS & Linux Host)

To build release-optimized, stripped native binaries:

```bash
dune build --profile release

```

Target executables are generated at:

* `_build/default/bin/main.exe`
* `_build/default/bin/transpiler.exe`

To install them into your environment (`/usr/local/bin` or system path):

```bash
dune install

```

### 2. Portable / Static Linux Binaries (MUSL)

To build fully static Linux binaries capable of running on any Linux distribution without dynamic shared object dependencies:

```bash
# Create a static MUSL opam switch
opam switch create 5.1.1+musl+static-lsb --package=ocaml-option-musl,ocaml-option-static
eval $(opam env)

# Reinstall dependencies and build
opam install . --deps-only
dune build --profile release

```

### 3. Universal macOS Binaries (Apple Silicon + Intel)

To bundle native Apple Silicon (`arm64`) and Intel (`x86_64`) support into a single universal Mach-O binary:

```bash
# Combine architecture artifacts using macOS lipo
lipo -create \
  _build/x86_64-apple-darwin/bin/main.exe \
  _build/arm64-apple-darwin/bin/main.exe \
  -output hft_engine_universal

```

## Interactive REPL Usage

The engine includes an interactive Read-Eval-Print Loop (REPL) that allows you to experiment with different syntactical dialects (`SOV`, `Infix`, and `S-Expression`) and inspect their corresponding AST representations in real time.

### Running the REPL

Launch the REPL via Dune:

```bash
dune exec hft_repl

```

### REPL Commands

* **`:sov`** — Switch active dialect to Subject-Object-Verb syntax (using postpositional particles).
* **`:infix`** — Switch active dialect to Infix / Sequent Judgment syntax.
* **`:sexp`** — Switch active dialect to Canonical S-Expression syntax.
* **`exit`** or **`quit`** — Exit the REPL session.

### Example Session

```text
=== HFT Notation Playground REPL ===  
Commands: :sov, :infix, :sexp to switch dialects, or 'exit' to quit.

hft [SOV]> :infix
Switched dialect to Infix

hft [Infix]> dark_pool_feed |- (size > 1000) |- route_order @smart_order_router

[Parsed AST Successfully]:
(App (App (Var route_order) (Lit (String smart_order_router)))
 (App (BinOp Gt (Var size) (Lit (Int 1000))) (Var dark_pool_feed)))

```