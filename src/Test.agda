
module Test where

open import Prelude
open import X86
open import Memory
open import Container.Traversable
open import Container.Path
open import Text.Printf

import X86.Compile as C
import X86.Untyped as Raw

Pre : Precondition
Pre _ y = NonZeroInt y

code : X86Code Pre initS _
code = mov %rdi %rax
     ∷ idiv %rsi
     ∷ ret
     ∷ []

  -- = mov  %rdi %rdx
  -- ∷ add  %rsi %rdx
  -- ∷ push %rdx
  -- ∷ sub  100  %rdx
  -- ∷ mov  %rdx %rax
  -- ∷ pop  %rdi
  -- ∷ imul %rdi %rax
  -- ∷ mov  0    %rdx
  -- ∷ idiv 2
  -- ∷ ret
  -- ∷ []

-- fun : X86Fun λ x y → ((x + y - 100) * (x + y)) quot 2
-- fun : X86Fun λ x y → (x + y - 100) * (x + y)
fun : X86Fun Pre λ x y → x quot y
fun = mkFun code

finalState : ∀ {P f} → X86Fun P f → S _
finalState (mkFun {s = s} _) = s

compileFun : ∀ {P f} → X86Fun P f → MachineCode
compileFun (mkFun code) = compile code

showMachineCode : ∀ {P s s₁} → X86Code P s s₁ → String
showMachineCode = foldr (printf "%02x %s") "" ∘ compile

jit : ∀ {P f} → X86Fun P f → IO (∀ x y {{_ : P x y}} → Int)
jit fun =
  do f ← writeMachineCode (compileFun fun)
  -| pure (λ x y {{_}} → f x y)

usage : IO ⊤
usage =
  do prog ← getProgName
  -| putStrLn ("Usage: " & prog & " X Y")

run : List Nat → IO ⊤
run (x ∷ zero ∷ []) = putStrLn "Sorry, no division by 0."
run (x ∷ suc y ∷ []) =
  do f ← jit fun
  -| print (f (pos x) (pos (suc y)))
run _ = usage

main : IO ⊤
main =
  do args ← getArgs
  -| maybe usage run (traverse parseNat args)
