(******************************************************************************)
(* Project: VDM model for Isabelle/UTP                                        *)
(* File: utp_vdm.thy                                                          *)
(* Authors: Original CML model by Simon Foster, University of York (UK)       *)
(*          Adapted to VDM by Luis Diogo Couto, Aarhus University (DK)        *)
(******************************************************************************)

theory utp_vdm
imports
  utp_vdm_model
  utp_vdm_inject
  utp_vdm_sorts
  utp_vdm_expr
  utp_vdm_laws
  utp_vdm_monad
  utp_vdm_tac
  utp_vdm_types
  utp_vdm_functions
  utp_vdm_records
  utp_vdm_stmt
  utp_vdm_commands
begin 

text {* Remove syntax which will likely clash *}

hide_const "SUB" "floor" "greatest" "Set.empty" "Map.empty" "Id" 
           "size" "top" "top_class.top" "bot_class.bot"

no_notation
  J_pred ("J") and
  relcomp (infixr "O" 75)

(* Remove standard HOL arithmetic operators *)

no_notation
  plus (infixl "+" 65) and
  minus (infixl "-" 65) and
  times (infixl "*" 70) and
  uminus ("- _" [81] 80) and
  divide (infixl "'/" 70) and
  Groups.zero ("0") and
  greater_eq  (infix ">=" 50) and
  greater  (infix ">" 50) and
  less_eq  ("op <=") and
  less_eq  ("(_/ <= _)" [51, 51] 50) and
  less  ("op <") and
  less  ("(_/ < _)"  [51, 51] 50) and
  TrueP ("true") and
  FalseP ("false") and
  VarA ("&_") and
  TrueAE ("true") and
  FalseAE ("false") and
  Sublist.parallel (infixl "\<parallel>" 50) and
  utp_designs_sig.ParallelD (infixr "\<parallel>" 100)

no_syntax
  "_n_upred_assigns"    :: "n_pvars \<Rightarrow> n_pexprs \<Rightarrow> n_upred" ("_ := _" [100] 100)
  "_n_upred_ifthenelse" :: "n_upred \<Rightarrow> n_upred \<Rightarrow> n_upred \<Rightarrow> n_upred" ("if _ then _ else _")
  "_n_upred_while"      :: "n_upred \<Rightarrow> n_upred \<Rightarrow> n_upred" ("while _ do _ od")
  "_upred_prefixed"     :: "n_pexpr \<Rightarrow> n_upred \<Rightarrow> n_upred" ("_ -> _")
  "_n_upred_index"      :: "('b \<Rightarrow> 'a upred) \<Rightarrow> 'b \<Rightarrow> n_upred" ("_<_>" 50)
  "_n_upred_var"        :: "idt \<Rightarrow> n_upred" ("_")
  "_upred_StopCSP"      :: "n_upred" ("STOP")
  "_upred_SkipCSP"      :: "n_upred" ("SKIP")
  "_upred_ChaosCSP"     :: "n_upred" ("CHAOS")
  "_n_upred_PrefixSkipCSP" :: "n_pexpr \<Rightarrow> n_upred" ("@_")
  "_upred_callpr"          :: "('a, 'b, 'm) WF_POPERATION \<Rightarrow> n_pexpr \<Rightarrow> n_upred" ("call _'[_']")
  "_upred_assignpr"        :: "('a, 'm) pvar \<Rightarrow> ('a, 'b, 'm) WF_POPERATION \<Rightarrow> n_pexpr \<Rightarrow> n_upred" ("_ := _'[_']" [100] 100)

declare EvalD_vexpr_set_range [evalp del]

(*
vdmacts
  P = "i:@int @ P<&i>" and
  Q = "i:@int @ P<5 + &i>" and
  R = "Q<1>" and
  S = "let x : @nat = 5 in SKIP"

term "ActionBlock"
*)

end