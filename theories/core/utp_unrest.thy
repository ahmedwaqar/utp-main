(******************************************************************************)
(* Project: Unifying Theories of Programming in HOL                           *)
(* File: utp_unrest.thy                                                       *)
(* Author: Frank Zeyda, University of York (UK)                               *)
(******************************************************************************)

header {* Unrestricted Variables *}

theory utp_unrest
imports 
  utp_pred 
  utp_rename
  "../tactics/utp_pred_tac"
begin

subsection {* Theorem Attributes *}

ML {*
  structure unrest =
    Named_Thms (val name = @{binding unrest} val description = "unrest theorems")
*}

setup unrest.setup

subsubsection {* @{term UNREST} Function *}

definition UNREST ::
  "('a uvar) set \<Rightarrow> 'a upred \<Rightarrow> bool" where
"UNREST vs p \<longleftrightarrow> (\<forall> b1 \<in> destPRED p . \<forall> b2. b1 \<oplus>\<^sub>b b2 on vs \<in> destPRED p)"

(* Relational unrestriction says that if an undashed variable has the
   same value as its dashed partner, it is unrestricted *)

definition REL_UNREST ::
  "('a uvar) set \<Rightarrow> 'a upred \<Rightarrow> bool" where
"REL_UNREST vs p \<longleftrightarrow> (\<forall> b \<in> destPRED p . \<forall>v\<in>in(vs). \<langle>b\<rangle>\<^sub>b(v) = \<langle>b\<rangle>\<^sub>b(v\<acute>))"

definition alphas ::
  "'a upred \<Rightarrow> 'a uvar fset set" where
"alphas(p) = {vs. UNREST (VAR - \<langle>vs\<rangle>\<^sub>f) p}"

consts
  unrest  :: "'v::type \<Rightarrow> 'a::type \<Rightarrow> bool" (infixr "\<sharp>" 60)

adhoc_overloading
  unrest UNREST

subsubsection {* Restricted variables *}

definition rv :: 
  "'a upred \<Rightarrow> ('a uvar) set" where
"rv(p) = \<Inter> {vs. UNREST (VAR - vs) p}"

subsubsection {* Fresh variables *}

definition fresh :: "'a upred \<Rightarrow> 'a utype \<Rightarrow> bool \<Rightarrow> 'a uvar" where
"fresh p t a = (SOME x. UNREST {x} p \<and> vtype x = t \<and> aux x = a)"

(*
definition ExistsFP :: 
  "'a UTYPE \<Rightarrow> bool \<Rightarrow> ('a VAR \<Rightarrow> 'a upred) \<Rightarrow> 'a upred" where
"ExistsFP t a P = 
  (let x = (SOME x. (\<forall> y. x \<noteq> y \<longrightarrow> UNREST {x} (P y)) \<and> vtype x = t \<and> aux x = a)
   in ExistsP {x} (P x))"


lemma "\<forall> y. UNREST {x}
*)

subsubsection {* Restricted Predicates *}

definition WF_PREDICATE_OVER ::
  "('a uvar) set \<Rightarrow>
   'a upred set" where
"WF_PREDICATE_OVER vs = {p . - vs \<sharp> p}"

subsubsection {* Theorems *}

theorem UNREST_binding_override [intro] :
"\<lbrakk>b \<in> destPRED p; vs \<sharp> p\<rbrakk> \<Longrightarrow>
 (b \<oplus>\<^sub>b b' on vs) \<in> destPRED p"
  by (simp add: UNREST_def)

theorem UNREST_empty [unrest]:
"UNREST {} p"
  by (simp add: UNREST_def)

theorem UNREST_subset :
"\<lbrakk>UNREST vs1 p;
 vs2 \<subseteq> vs1\<rbrakk> \<Longrightarrow>
 UNREST vs2 p"
apply (simp add: UNREST_def)
apply (clarify)
apply (drule_tac x = "b1" in bspec)
apply (assumption)
apply (drule_tac x = "b2 \<oplus>\<^sub>b b1 on (vs1 - vs2)" in spec)
apply (simp add: closure)
apply (subgoal_tac "vs1 - (vs1 - vs2) = vs2")
apply (simp)
apply (auto)
done

theorem UNREST_union [unrest]:
"\<lbrakk>UNREST vs1 p;
 UNREST vs2 p\<rbrakk> \<Longrightarrow>
 UNREST (vs1 \<union> vs2) p"
apply (simp add: UNREST_def)
apply (clarify)
apply (metis binding_override_simps(1))
done

lemma UNREST_unionE [elim]: 
  "\<lbrakk> UNREST (xs \<union> ys) p; \<lbrakk> UNREST xs p; UNREST ys p \<rbrakk> \<Longrightarrow> P \<rbrakk> \<Longrightarrow> P"
  by (metis UNREST_subset sup_ge1 sup_ge2)

theorem UNREST_minus [unrest]:
"UNREST vs1 p \<Longrightarrow>
 UNREST (vs1 - vs2) p"
  apply (auto simp add:UNREST_def)
  apply (metis binding_override_simps(5))
done

theorem UNREST_inter_1 [unrest]:
"UNREST vs1 p \<Longrightarrow>
 UNREST (vs1 \<inter> vs2) p"
  apply (auto simp add:UNREST_def)
  apply (metis binding_override_simps(6) inf.commute)
done

theorem UNREST_inter_2 [unrest]:
"UNREST vs2 p \<Longrightarrow>
 UNREST (vs1 \<inter> vs2) p"
  apply (auto simp add:UNREST_def)
  apply (metis binding_override_simps(6) inf.commute)
done

theorem UNREST_LiftP_1 [unrest]:
"\<lbrakk> f \<in> WF_BINDING_PRED vs \<rbrakk> \<Longrightarrow>
   - vs \<sharp> LiftP f"
  apply (simp add: UNREST_def LiftP_def)
  apply (simp add: WF_BINDING_PRED_def)
  apply (auto)
  apply (drule_tac x = "b1" in spec, auto)
  apply (drule_tac x = "b1 \<oplus>\<^sub>b b2 on (- vs)" in spec)
  apply (simp add: binding_equiv_def)
done

theorem UNREST_LiftP_2 [unrest]:
"\<lbrakk>f \<in> WF_BINDING_PRED vs1; vs1 \<inter> vs2 = {} \<rbrakk> \<Longrightarrow>
 vs2 \<sharp> (LiftP f)"
  apply (simp add: UNREST_def LiftP_def)
  apply (simp add: WF_BINDING_PRED_def)
  apply (auto)
  apply (metis binding_override_equiv1 binding_override_reorder binding_override_simps(2))
done

theorem UNREST_EqualsP [unrest]:
"v \<notin> vs \<Longrightarrow> vs \<sharp> (v =\<^sub>p x)"
  apply (simp add: EqualsP_def)
  apply (rule UNREST_LiftP_2[of _ "{v}"])
  apply (auto simp add: WF_BINDING_PRED_def)
done

theorem UNREST_TrueP [unrest]:
"vs \<sharp> true"
  by (simp add: UNREST_def TrueP_def)

theorem UNREST_FalseP [unrest]:
"vs \<sharp> false"
  by (simp add: UNREST_def FalseP_def)

theorem UNREST_NotP [unrest]:
"\<lbrakk> vs \<sharp> p \<rbrakk> \<Longrightarrow> vs \<sharp> \<not>\<^sub>p p"
  apply (simp add: UNREST_def NotP.rep_eq)
  apply (auto)
  apply (drule_tac x = "b1 \<oplus>\<^sub>b b2 on vs" in bspec)
  apply (assumption)
  apply (drule_tac x = "b1" in spec)
  apply (simp)
done

theorem UNREST_AndP [unrest]:
"\<lbrakk> vs \<sharp> p1; vs \<sharp> p2 \<rbrakk> \<Longrightarrow>
   vs \<sharp> (p1 \<and>\<^sub>p p2)"
  by (simp add: UNREST_def AndP_def)

theorem UNREST_AndP_alt [unrest]:
"\<lbrakk> vs1 \<sharp> p1; vs2 \<sharp> p2 \<rbrakk> \<Longrightarrow>
 (vs1 \<inter> vs2) \<sharp> (p1 \<and>\<^sub>p p2)"
by (simp add: unrest)

theorem UNREST_OrP [unrest]:
"\<lbrakk> vs \<sharp> p1; vs \<sharp> p2 \<rbrakk> \<Longrightarrow>
 vs \<sharp> (p1 \<or>\<^sub>p p2)"
  by (auto simp add: UNREST_def OrP_def)

theorem UNREST_ImpliesP [unrest]:
"\<lbrakk> vs \<sharp> p1; vs \<sharp> p2 \<rbrakk> \<Longrightarrow>
 vs \<sharp> (p1 \<Rightarrow>\<^sub>p p2)"
  apply (simp add: ImpliesP_def)
  apply (auto intro: UNREST_OrP UNREST_NotP closure)
done

theorem UNREST_IffP [unrest]:
"\<lbrakk> vs \<sharp> p1; vs \<sharp> p2 \<rbrakk> \<Longrightarrow>
 vs \<sharp> (p1 \<Leftrightarrow>\<^sub>p p2)"
  apply (simp add: IffP_def)
  apply (auto intro: UNREST_ImpliesP UNREST_AndP closure)
done

theorem UNREST_AndDistP [unrest]:
  "\<lbrakk> \<And> p. p \<in> ps \<Longrightarrow> vs \<sharp> p \<rbrakk> \<Longrightarrow> vs \<sharp> \<And>\<^sub>p ps"
  by (auto simp add: UNREST_def AndDistP_rep_eq)

theorem UNREST_OrDistP [unrest]:
  "\<lbrakk> \<And> p. p \<in> ps \<Longrightarrow> vs \<sharp> p \<rbrakk> \<Longrightarrow> vs \<sharp> \<Or>\<^sub>p ps"
  by (auto simp add: UNREST_def OrDistP_rep_eq)

lemma UNREST_ANDI [unrest]:
  "\<lbrakk> \<And> p. p \<in> ps \<Longrightarrow> vs \<sharp> f p \<rbrakk> \<Longrightarrow> vs \<sharp> (\<And>\<^sub>p p:ps. f p)"
  by (auto intro: unrest simp add:ANDI_def)

lemma UNREST_ORDI [unrest]:
  "\<lbrakk> \<And> p. p \<in> ps \<Longrightarrow> vs \<sharp> f p \<rbrakk> \<Longrightarrow> vs \<sharp> (\<Or>\<^sub>p p:ps. f p)"
  by (auto intro: unrest simp add:ORDI_def)

theorem UNREST_ExistsP [unrest]:
"\<lbrakk> vs1 \<sharp> p; vs = vs1 \<union> vs2 \<rbrakk> \<Longrightarrow>
 vs \<sharp> (\<exists>\<^sub>p vs2 . p)"
apply (simp add: UNREST_def ExistsP_def)
apply (clarify)
apply (simp)
apply (rule_tac x = "b1a \<oplus>\<^sub>b b2 on vs1" in exI)
apply (simp)
apply (rule_tac x = "b2" in exI)
apply (simp)
done

theorem UNREST_ForallP [unrest]:
"\<lbrakk> vs1 \<sharp> p; vs = vs1 \<union> vs2\<rbrakk> \<Longrightarrow>
   vs \<sharp> (\<forall>\<^sub>p vs2 . p)"
  apply (simp add: ForallP_def)
  apply (auto intro: UNREST_ExistsP UNREST_NotP closure)
done

theorem UNREST_ExistsP_simple [unrest]:
"\<lbrakk> vs1 \<subseteq> vs2 \<rbrakk> \<Longrightarrow>
   vs1 \<sharp> (\<exists>\<^sub>p vs2 . p)"
  apply (insert UNREST_ExistsP [of "{}" "p" "vs2"])
  apply (simp add: UNREST_empty)
  apply (auto intro: UNREST_subset closure)
done

theorem UNREST_ExistsP_simple' [unrest]:
  "vs1 \<sharp> p \<Longrightarrow> vs1 \<sharp> (\<exists>\<^sub>p vs2. p)"
  by (metis UNREST_ExistsP UNREST_subset sup_ge1)

theorem UNREST_ForallP_simple [unrest]:
"\<lbrakk> vs1 \<subseteq> vs2 \<rbrakk> \<Longrightarrow>
   vs1 \<sharp> (\<forall>\<^sub>p vs2 . p)"
apply (insert UNREST_ForallP [of "{}" "p" "vs2"])
apply (simp add: UNREST_empty)
apply (auto intro: UNREST_subset closure)
done

theorem UNREST_ClosureP [unrest]:
"vs \<sharp> [p]\<^sub>p"
  apply (simp add: ClosureP_def)
  apply (metis UNREST_ForallP_simple VAR_subset)
done

theorem UNREST_RefP [unrest]:
"vs \<sharp> (p1 \<sqsubseteq>\<^sub>p p2)"
  apply (simp add: RefP_def)
  apply (auto intro: UNREST_ClosureP closure)
done

theorem UNREST_RenameP [unrest]:
"\<lbrakk> vs1 \<sharp> p; vs2 = \<langle>ss\<rangle>\<^sub>s ` vs1 \<rbrakk> \<Longrightarrow>
   vs2 \<sharp> (p[ss]\<^sub>p)"
  apply (simp add: UNREST_def)
  apply (simp add: PermP.rep_eq)
  apply (safe)
  apply (drule_tac x = "b1" in bspec)
  apply (assumption)
  apply (drule_tac x = "RenameB (inv\<^sub>s ss) b2" in spec)
  apply (drule imageI [where f = "RenameB ss"]) back
  apply (simp add: RenameB_override_distr1 closure)
done

lemma WF_PREDICATE_binding_equiv:
"\<lbrakk> - vs \<sharp> p; b1 \<in> destPRED p; b1 \<cong> b2 on vs \<rbrakk> 
 \<Longrightarrow> b2 \<in> destPRED p"
  apply (auto simp add:UNREST_def)
  apply (metis (full_types) binding_equiv_override binding_override_simps(2))
done

subsubsection {* Proof Support *}

theorem UNREST_LiftP_alt [unrest]:
"\<lbrakk>f \<in> WF_BINDING_PRED vs1;
 vs2 \<subseteq> - vs1\<rbrakk> \<Longrightarrow>
 vs2 \<sharp> (LiftP f)"
  by (auto intro: UNREST_LiftP_1 UNREST_subset simp: closure)

theorem UNREST_ExistsP_alt [unrest]:
"\<lbrakk> vs1 \<sharp> p; vs3 \<subseteq> vs1 \<union> vs2 \<rbrakk> \<Longrightarrow>
 vs3 \<sharp> (\<exists>\<^sub>p vs2 . p)"
  by (auto intro: UNREST_ExistsP UNREST_subset simp: closure)

theorem UNREST_ExistsP_minus [unrest]:
"\<lbrakk> (vs1 - vs2) \<sharp> p \<rbrakk> \<Longrightarrow>
 vs1 \<sharp> (\<exists>\<^sub>p vs2 . p)"
  by (auto intro: UNREST_ExistsP UNREST_subset simp: closure)

theorem UNREST_ForallP_alt [unrest]:
"\<lbrakk> vs1 \<sharp> p; vs3 \<subseteq> vs1 \<union> vs2 \<rbrakk> \<Longrightarrow>
 vs3 \<sharp> (\<forall>\<^sub>p vs2 . p)"
  by (auto intro: UNREST_ForallP UNREST_subset simp: closure)

theorem UNREST_RenameP_alt [unrest]:
"\<lbrakk> vs1 \<sharp> p;
 vs2 \<subseteq> (\<langle>ss\<rangle>\<^sub>s ` vs1)\<rbrakk> \<Longrightarrow>
 vs2 \<sharp> (p[ss]\<^sub>p)"
  by (auto intro: UNREST_RenameP UNREST_subset simp: closure)

(*
theorem UNREST_RenameP_single :
"\<lbrakk> x \<noteq> y; vtype x = vtype y; aux x = aux y; x \<in> vs; y \<notin> vs;
   UNREST ((vs - {x}) \<union> {y})  p \<rbrakk> \<Longrightarrow> 
   UNREST vs p\<^bsup>[x \<mapsto> y]\<^esup>"
  apply (simp add:RenamePMap_def)
  apply (rule UNREST_RenameP_alt)
  apply (simp)
  apply (simp add:closure)
  apply (simp add: MapRename_image[of "[x]" "[y]" "(vs - {x})",simplified])
  apply (force)
done
*)

(*
theorem UNREST_RenameP_single :
"\<lbrakk> x \<noteq> y; vtype x = vtype y; aux x = aux y;
   UNREST {y} p \<rbrakk> \<Longrightarrow> 
   UNREST {x} p\<^bsup>[x \<mapsto> y]\<^esup>"
  apply (simp add:RenamePMap_def)
  apply (rule UNREST_RenameP_alt)
  apply (auto simp add:closure)
done
*)

theorem UNREST_fresh [unrest]: 
  "\<exists> v. {v} \<sharp> p \<and> vtype v = t \<and> aux v = a \<Longrightarrow> {fresh p t a} \<sharp> p"
  apply (auto simp add:fresh_def)
  apply (metis (mono_tags, lifting) someI)+
done

theorem UNREST_fresh' [unrest]:
  "\<lbrakk> {v} \<sharp> p; vtype v = t; aux v = a \<rbrakk> \<Longrightarrow> {fresh p t a} \<sharp> p"
  by (metis UNREST_fresh)

lemma UNREST_aux [unrest]:
  "\<lbrakk> aux x; AUX_VAR \<sharp> p \<rbrakk> \<Longrightarrow> {x} \<sharp> p"
  by (rule UNREST_subset, auto)

text {* A predicate unrestricted on all variables is either true or false *}

theorem UNREST_true_false: 
  "VAR \<sharp> p \<Longrightarrow> p = true \<or> p = false"
  by (auto simp add:UNREST_def TrueP_def FalseP_def)

text {* Evaluation Laws *}

theorem EvalP_UNREST_assign [eval] :
"\<lbrakk> vs \<sharp> p; x \<in> vs \<rbrakk> \<Longrightarrow> 
  \<lbrakk>p\<rbrakk>(b(x :=\<^sub>b v)) = \<lbrakk>p\<rbrakk>b"
  apply (simp add:EvalP_def)
  apply (metis UNREST_binding_override binding_override_simps(2) binding_upd_override)
done

theorem EvalP_UNREST_override [eval] :
"vs \<sharp> p \<Longrightarrow> \<lbrakk>p\<rbrakk>(b1 \<oplus>\<^sub>b b2 on vs) = \<lbrakk>p\<rbrakk>b1"
  apply (auto simp add:EvalP_def)
  apply (metis UNREST_binding_override binding_override_simps(2) binding_override_simps(3))
done

theorem EvalP_UNREST_binding_equiv [eval] :
"\<lbrakk> - vs \<sharp> p; \<lbrakk>p\<rbrakk>b1; b1 \<cong> b2 on vs \<rbrakk> 
 \<Longrightarrow> \<lbrakk>p\<rbrakk>b2"
  by (simp add: EvalP_def WF_PREDICATE_binding_equiv)

lemma EvalP_binding_equiv:
  "\<lbrakk> - vs \<sharp> p; b1 \<cong> b2 on vs \<rbrakk> \<Longrightarrow> \<lbrakk>p\<rbrakk>b1 = \<lbrakk>p\<rbrakk>b2"
  by (metis EvalP_UNREST_override binding_equiv_override)

lemma UNREST_EvalP_def:
  "vs \<sharp> P \<longleftrightarrow> (\<forall>b1. \<lbrakk>P\<rbrakk>b1 \<longrightarrow> (\<forall> b2. \<lbrakk>P\<rbrakk>(b1 \<oplus>\<^sub>b b2 on vs)))" 
  by (auto simp add:UNREST_def EvalP_def)

lemma "rv false = {}"
  by (simp add:rv_def unrest)

lemma "rv true = {}"
  by (simp add:rv_def unrest)

lemma pred_map_set_inv:
  "- xs \<sharp> p \<Longrightarrow> map_set_pred (pred_map_set xs p) = p"
  apply (rule)
  apply (auto simp add:pred_map_set_def map_set_pred.rep_eq binding_map_dom)
  apply (rule WF_PREDICATE_binding_equiv, simp_all add:VAR_def Compl_eq_Diff_UNIV[THEN sym])
  apply (metis binding_equiv_comm binding_equiv_override_subsume binding_override_minus map_binding_inv)
  apply (metis binding_equiv_override binding_map_dom binding_override_minus binding_override_simps(2) image_eqI map_binding_inv)
done

lemma alphas_FalseP: "alphas(false) = UNIV"
  by (auto simp add:alphas_def unrest)

lemma alphas_TrueP: "alphas(true) = UNIV"
  by (metis (lifting) UNIV_eq_I UNREST_TrueP alphas_def mem_Collect_eq)

lemma alphas_NotP: "alphas(\<not>\<^sub>p p) = alphas(p)"
  by (metis (lifting, no_types) Collect_cong NotP_NotP UNREST_NotP alphas_def)
  
end