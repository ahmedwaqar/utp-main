(******************************************************************************)
(* Project: Unifying Theories of Programming in HOL                           *)
(* File: utp_base.thy                                                         *)
(* Author: Frank Zeyda, University of York (UK)                               *)
(******************************************************************************)

header {* Base UTP without any theories *}

theory utp_base
imports
  utp_common
  "core/utp_core"
  "alpha/utp_alpha_pred"
  "tactics/utp_pred_tac"
  "tactics/utp_expr_tac"
  "tactics/utp_rel_tac"
  "tactics/utp_xrel_tac"
  "laws/utp_pred_laws"
  "laws/utp_rel_laws"
  "laws/utp_subst_laws"
  "laws/utp_rename_laws"
  "laws/utp_refine_laws"
  "poly/utp_poly"
  "parser/utp_pred_parser"
  "theories/utp_theory"
begin
end
