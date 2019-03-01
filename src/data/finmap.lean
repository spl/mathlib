/-
Copyright (c) 2018 Sean Leather. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sean Leather, Mario Carneiro

Finite maps over `multiset`.
-/
import data.list.alist data.finset data.pfun

universes u v w
open list
variables {α : Type u} {β : α → Type v}

namespace multiset

/-- Multiset of keys of an association multiset. -/
def keys (s : multiset (sigma β)) : multiset α :=
s.map sigma.fst

@[simp] theorem coe_keys {l : list (sigma β)} :
  keys (l : multiset (sigma β)) = (l.keys : multiset α) :=
rfl

/-- `nodupkeys s` means that `s` has no duplicate keys. -/
def nodupkeys (s : multiset (sigma β)) : Prop :=
quot.lift_on s list.nodupkeys (λ s t p, propext $ perm_nodupkeys p)

@[simp] theorem coe_nodupkeys {l : list (sigma β)} : @nodupkeys α β l ↔ l.nodupkeys := iff.rfl

end multiset

/-- `finmap β` is the type of finite maps over a multiset. It is effectively
  a quotient of `alist β` by permutation of the underlying list. -/
structure finmap (β : α → Type v) : Type (max u v) :=
(entries : multiset (sigma β))
(nodupkeys : entries.nodupkeys)

/-- The quotient map from `alist` to `finmap`. -/
def alist.to_finmap (s : alist β) : finmap β := ⟨s.entries, s.nodupkeys⟩

local notation `⟦`:max a `⟧`:0 := alist.to_finmap a

theorem alist.to_finmap_eq {s₁ s₂ : alist β} :
  ⟦s₁⟧ = ⟦s₂⟧ ↔ s₁.entries ~ s₂.entries :=
by cases s₁; cases s₂; simp [alist.to_finmap]

@[simp] theorem alist.to_finmap_entries (s : alist β) : ⟦s⟧.entries = s.entries := rfl

namespace finmap
open alist

/-- Lift a permutation-respecting function on `alist` to `finmap`. -/
@[elab_as_eliminator] def lift_on
  {γ} (s : finmap β) (f : alist β → γ)
  (H : ∀ a b : alist β, a.entries ~ b.entries → f a = f b) : γ :=
begin
  refine (quotient.lift_on s.1 (λ l, (⟨_, λ nd, f ⟨l, nd⟩⟩ : roption γ))
    (λ l₁ l₂ p, roption.ext' (perm_nodupkeys p) _) : roption γ).get _,
  { exact λ h₁ h₂, H _ _ (by exact p) },
  { have := s.nodupkeys, rcases s.entries with ⟨l⟩, exact id }
end

@[simp] theorem lift_on_to_finmap {γ} (s : alist β) (f : alist β → γ) (H) :
  lift_on ⟦s⟧ f H = f s := by cases s; refl

/-- Lift a permutation-respecting function on 2 `alist`s to 2 `finmap`s. -/
@[elab_as_eliminator] def lift_on₂
  {γ} (s₁ s₂ : finmap β) (f : alist β → alist β → γ)
  (H : ∀ a₁ b₁ a₂ b₂ : alist β, a₁.entries ~ a₂.entries → b₁.entries ~ b₂.entries → f a₁ b₁ = f a₂ b₂) : γ :=
lift_on s₁
  (λ l₁, lift_on s₂ (f l₁) (λ b₁ b₂ p, H _ _ _ _ (perm.refl _) p))
  (λ a₁ a₂ p, have H' : f a₁ = f a₂ := funext (λ _, H _ _ _ _ p (perm.refl _)), by simp only [H'])

@[simp] theorem lift_on₂_to_finmap {γ} (s₁ s₂ : alist β) (f : alist β → alist β → γ) (H) :
  lift_on₂ ⟦s₁⟧ ⟦s₂⟧ f H = f s₁ s₂ :=
by cases s₁; cases s₂; refl

@[elab_as_eliminator] theorem induction_on
  {C : finmap β → Prop} (s : finmap β) (H : ∀ (a : alist β), C ⟦a⟧) : C s :=
by rcases s with ⟨⟨a⟩, h⟩; exact H ⟨a, h⟩

@[elab_as_eliminator] theorem induction_on₂ {C : finmap β → finmap β → Prop}
  (s₁ s₂ : finmap β) (H : ∀ (a₁ a₂ : alist β), C ⟦a₁⟧ ⟦a₂⟧) : C s₁ s₂ :=
induction_on s₁ $ λ l₁, induction_on s₂ $ λ l₂, H l₁ l₂

@[elab_as_eliminator] theorem induction_on₃ {C : finmap β →  finmap β → finmap β → Prop}
  (s₁ s₂ s₃ : finmap β) (H : ∀ (a₁ a₂ a₃ : alist β), C ⟦a₁⟧ ⟦a₂⟧ ⟦a₃⟧) : C s₁ s₂ s₃ :=
induction_on₂ s₁ s₂ $ λ l₁ l₂, induction_on s₃ $ λ l₃, H l₁ l₂ l₃

@[extensionality] theorem ext : ∀ {s t : finmap β}, s.entries = t.entries → s = t
| ⟨l₁, h₁⟩ ⟨l₂, h₂⟩ H := by congr'

@[simp] theorem ext_iff {s t : finmap β} : s.entries = t.entries ↔ s = t :=
⟨ext, congr_arg _⟩

/- mem -/

/-- The predicate `a ∈ s` means that `s` has a value associated to the key `a`. -/
instance : has_mem α (finmap β) := ⟨λ a s, a ∈ s.entries.keys⟩

theorem mem_def {a : α} {s : finmap β} :
  a ∈ s ↔ a ∈ s.entries.keys := iff.rfl

@[simp] theorem mem_to_finmap {a : α} {s : alist β} :
  a ∈ ⟦s⟧ ↔ a ∈ s := iff.rfl

/- keys -/

/-- The set of keys of a finite map. -/
def keys (s : finmap β) : finset α :=
⟨s.entries.keys, induction_on s keys_nodup⟩

@[simp] theorem keys_val (s : alist β) : (keys ⟦s⟧).val = s.keys := rfl

@[simp] theorem keys_ext {s₁ s₂ : alist β} :
  keys ⟦s₁⟧ = keys ⟦s₂⟧ ↔ s₁.keys ~ s₂.keys :=
by simp [keys, alist.keys]

@[simp] theorem mem_keys {a : α} {s : finmap β} : a ∈ s.keys ↔ a ∈ s :=
induction_on s $ λ s, alist.mem_keys

/- empty -/

/-- The empty map. -/
instance : has_emptyc (finmap β) := ⟨⟨0, nodupkeys_nil⟩⟩

@[simp] theorem empty_to_finmap (s : alist β) :
  (⟦∅⟧ : finmap β) = ∅ := rfl

theorem not_mem_empty {a : α} : a ∉ (∅ : finmap β) :=
multiset.not_mem_zero a

@[simp] theorem keys_empty : (∅ : finmap β).keys = ∅ := rfl

/- singleton -/

/-- The singleton map. -/
def singleton (a : α) (b : β a) : finmap β :=
⟨⟨a, b⟩::0, nodupkeys_singleton _⟩

@[simp] theorem keys_singleton (a : α) (b : β a) :
  (singleton a b).keys = finset.singleton a := rfl

variables [decidable_eq α]

instance has_decidable_eq [∀ a, decidable_eq (β a)] : decidable_eq (finmap β)
| s₁ s₂ := decidable_of_iff _ ext_iff

/- lookup -/

/-- Look up the value associated to a key in a map. -/
def lookup (a : α) (s : finmap β) : option (β a) :=
lift_on s (lookup a) (λ s t, perm_lookup)

@[simp] theorem lookup_to_finmap (a : α) (s : alist β) :
  lookup a ⟦s⟧ = s.lookup a := rfl

@[simp] theorem lookup_empty (a) : lookup a (∅ : finmap β) = none :=
rfl

theorem lookup_is_some {a : α} {s : finmap β} :
  (s.lookup a).is_some ↔ a ∈ s :=
induction_on s $ λ s, alist.lookup_is_some

theorem lookup_eq_none {a} {s : finmap β} : lookup a s = none ↔ a ∉ s :=
induction_on s $ λ s, alist.lookup_eq_none

instance (a : α) (s : finmap β) : decidable (a ∈ s) :=
decidable_of_iff _ lookup_is_some

theorem lookup_ext {s₁ s₂ : finmap β} : s₁ = s₂ ↔ ∀ a, lookup a s₁ = lookup a s₂ :=
induction_on₂ s₁ s₂ $ λ s₁ s₂, to_finmap_eq.trans perm_lookup_ext

/- replace -/

/-- Replace a key with a given value in a finite map.
  If the key is not present it does nothing. -/
def replace (a : α) (b : β a) (s : finmap β) : finmap β :=
lift_on s (λ t, ⟦replace a b t⟧) $
λ s₁ s₂ p, to_finmap_eq.2 $ perm_replace p

@[simp] theorem replace_to_finmap (a : α) (b : β a) (s : alist β) :
  replace a b ⟦s⟧ = ⟦s.replace a b⟧ := by simp [replace]

@[simp] theorem keys_replace (a : α) (b : β a) (s : finmap β) :
  (replace a b s).keys = s.keys :=
induction_on s $ λ s, by simp

@[simp] theorem mem_replace {a a' : α} {b : β a} {s : finmap β} :
  a' ∈ replace a b s ↔ a' ∈ s :=
induction_on s $ λ s, by simp

/-- Fold a commutative function over the key-value pairs in the map -/
def foldl {δ : Type w} (f : δ → Π a, β a → δ)
  (H : ∀ d a₁ b₁ a₂ b₂, f (f d a₁ b₁) a₂ b₂ = f (f d a₂ b₂) a₁ b₁)
  (d : δ) (m : finmap β) : δ :=
m.entries.foldl (λ d s, f d s.1 s.2) (λ d s t, H _ _ _ _ _) d

/- erase -/

/-- Erase a key from the map. If the key is not present it does nothing. -/
def erase (a : α) (s : finmap β) : finmap β :=
lift_on s (λ t, ⟦erase a t⟧) $
λ s₁ s₂ p, to_finmap_eq.2 $ perm_erase p

@[simp] theorem erase_to_finmap (a : α) (s : alist β) :
  erase a ⟦s⟧ = ⟦s.erase a⟧ := by simp [erase]

@[simp] theorem keys_erase_to_finset (a : α) (s : alist β) :
  keys ⟦s.erase a⟧ = (keys ⟦s⟧).erase a :=
by simp [finset.erase, keys, alist.erase, keys_kerase]

@[simp] theorem keys_erase (a : α) (s : finmap β) :
  (erase a s).keys = s.keys.erase a :=
induction_on s $ λ s, by simp

@[simp] theorem mem_erase {a a' : α} {s : finmap β} : a' ∈ erase a s ↔ a' ≠ a ∧ a' ∈ s :=
induction_on s $ λ s, by simp

@[simp] theorem lookup_erase (a) (s : finmap β) : lookup a (erase a s) = none :=
induction_on s $ lookup_erase a

@[simp] theorem lookup_erase_ne {a a'} {s : finmap β} (h : a ≠ a') :
  lookup a (erase a' s) = lookup a s :=
induction_on s $ λ s, lookup_erase_ne h

/- insert -/

/-- Insert a key-value pair into a finite map, replacing any existing pair with
  the same key. -/
def insert (a : α) (b : β a) (s : finmap β) : finmap β :=
lift_on s (λ t, ⟦insert a b t⟧) $
λ s₁ s₂ p, to_finmap_eq.2 $ perm_insert p

@[simp] theorem insert_to_finmap (a : α) (b : β a) (s : alist β) :
  insert a b ⟦s⟧ = ⟦s.insert a b⟧ := by simp [insert]

theorem insert_entries_of_neg {a : α} {b : β a} {s : finmap β} : a ∉ s →
  (insert a b s).entries = ⟨a, b⟩ :: s.entries :=
induction_on s $ λ s h,
by simp [insert_entries_of_neg (mt mem_to_finmap.1 h)]

@[simp] theorem mem_insert {a a' : α} {b' : β a'} {s : finmap β} :
  a ∈ insert a' b' s ↔ a = a' ∨ a ∈ s :=
induction_on s mem_insert

@[simp] theorem keys_insert {a : α} {b : β a} {s : finmap β} :
  (insert a b s).keys = _root_.insert a s.keys :=
finset.ext' $ by simp

@[simp] theorem lookup_insert {a} {b : β a} (s : finmap β) :
  lookup a (insert a b s) = some b :=
induction_on s $ λ s,
by simp only [insert_to_finmap, lookup_to_finmap, lookup_insert]

/- extract -/

/-- Erase a key from the map, and return the corresponding value, if found. -/
def extract (a : α) (s : finmap β) : option (β a) × finmap β :=
lift_on s (λ t, prod.map id to_finmap (extract a t)) $
λ s₁ s₂ p, by simp [perm_lookup p, to_finmap_eq, perm_erase p]

@[simp] theorem extract_eq_lookup_erase (a : α) (s : finmap β) :
  extract a s = (lookup a s, erase a s) :=
induction_on s $ λ s, by simp [extract]

/- union -/

/-- `s₁ ∪ s₂` is the key-based union of two finite maps. It is left-biased: if
there exists an `a ∈ s₁`, `lookup a (s₁ ∪ s₂) = lookup a s₁`. -/
def union (s₁ s₂ : finmap β) : finmap β :=
lift_on₂ s₁ s₂ (λ s₁ s₂, ⟦s₁ ∪ s₂⟧) $
λ s₁ s₂ s₃ s₄ p₁₃ p₂₄, to_finmap_eq.mpr $ perm_union p₁₃ p₂₄

instance : has_union (finmap β) := ⟨union⟩

@[simp] theorem mem_union {a} {s₁ s₂ : finmap β} :
  a ∈ s₁ ∪ s₂ ↔ a ∈ s₁ ∨ a ∈ s₂ :=
induction_on₂ s₁ s₂ $ λ _ _, mem_union

@[simp] theorem union_to_finmap (s₁ s₂ : alist β) : ⟦s₁⟧ ∪ ⟦s₂⟧ = ⟦s₁ ∪ s₂⟧ :=
by simp [(∪), union]

@[simp] theorem keys_union {s₁ s₂ : finmap β} : (s₁ ∪ s₂).keys = s₁.keys ∪ s₂.keys :=
induction_on₂ s₁ s₂ $ λ s₁ s₂, finset.ext' $ by simp [keys]

@[simp] theorem lookup_union_left {a} {s₁ s₂ : finmap β} :
  a ∈ s₁ → lookup a (s₁ ∪ s₂) = lookup a s₁ :=
induction_on₂ s₁ s₂ $ λ s₁ s₂, lookup_union_left

@[simp] theorem lookup_union_right {a} {s₁ s₂ : finmap β} :
  a ∉ s₁ → lookup a (s₁ ∪ s₂) = lookup a s₂ :=
induction_on₂ s₁ s₂ $ λ s₁ s₂, lookup_union_right

@[simp] theorem mem_lookup_union {a} {b : β a} {s₁ s₂ : finmap β} :
  b ∈ lookup a (s₁ ∪ s₂) ↔ b ∈ lookup a s₁ ∨ a ∉ s₁ ∧ b ∈ lookup a s₂ :=
induction_on₂ s₁ s₂ $ λ s₁ s₂, mem_lookup_union

theorem mem_lookup_union_middle {a} {b : β a} {s₁ s₂ s₃ : finmap β} :
  b ∈ lookup a (s₁ ∪ s₃) → a ∉ s₂ → b ∈ lookup a (s₁ ∪ s₂ ∪ s₃) :=
induction_on₃ s₁ s₂ s₃ $ λ s₁ s₂ s₃, mem_lookup_union_middle

theorem union_assoc {s₁ s₂ s₃ : finmap β} : (s₁ ∪ s₂) ∪ s₃ = s₁ ∪ (s₂ ∪ s₃) :=
lookup_ext.mpr $ λ a,
by by_cases h₁ : a ∈ s₁; by_cases h₂ : a ∈ s₂; by_cases h₃ : a ∈ s₃; simp [h₁, h₂, h₃]

/- disjointkeys -/

/-- Two finite maps have disjoint key sets. -/
def disjointkeys (s₁ s₂ : finmap β) : Prop :=
disjoint s₁.keys s₂.keys

theorem disjointkeys_left {s₁ s₂ : finmap β} :
  disjointkeys s₁ s₂ ↔ ∀ {a}, a ∈ s₁ → a ∉ s₂ :=
finset.disjoint_left

theorem disjointkeys_right {s₁ s₂ : finmap β} :
  disjointkeys s₁ s₂ ↔ ∀ {a}, a ∈ s₂ → a ∉ s₁ :=
finset.disjoint_right

@[simp] theorem disjointkeys_insert_left {a} (b : β a) {s₁ s₂ : finmap β} :
  disjointkeys (insert a b s₁) s₂ ↔ a ∉ s₂ ∧ disjointkeys s₁ s₂ :=
by simp [disjointkeys]

@[simp] theorem disjointkeys_insert_right {a} (b : β a) {s₁ s₂ : finmap β} :
  disjointkeys s₁ (insert a b s₂) ↔ a ∉ s₁ ∧ disjointkeys s₁ s₂ :=
by simp [disjointkeys]

@[simp] theorem disjointkeys_union_left {s₁ s₂ s₃ : finmap β} :
  disjointkeys (s₁ ∪ s₂) s₃ ↔ disjointkeys s₁ s₃ ∧ disjointkeys s₂ s₃ :=
by simp [disjointkeys]

@[simp] theorem disjointkeys_union_right {s₁ s₂ s₃ : finmap β} :
  disjointkeys s₁ (s₂ ∪ s₃) ↔ disjointkeys s₁ s₂ ∧ disjointkeys s₁ s₃ :=
by simp [disjointkeys]

theorem union_comm {s₁ s₂ : finmap β} (dk : disjointkeys s₁ s₂) :
  s₁ ∪ s₂ = s₂ ∪ s₁ :=
lookup_ext.mpr $ λ a,
begin
  by_cases h₁ : a ∈ s₁; by_cases h₂ : a ∈ s₂; simp [h₁, h₂],
  { have := disjointkeys_left.mp dk h₁, contradiction },
  { rw ←lookup_eq_none at h₁ h₂, rw [h₁, h₂] }
end

end finmap
