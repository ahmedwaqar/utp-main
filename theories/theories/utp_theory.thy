(******************************************************************************)
(* Project: Mechanisation of the UTP                                          *)
(* File: utp/theories/utp_theory.thy                                          *)
(* Author: Simon Foster and Frank Zeyda, University of York                   *)
(******************************************************************************)

header {* UTP Theories *}

theory utp_theory
imports 
  "../core/utp_pred"
  "../core/utp_unrest"
  "../tactics/utp_pred_tac"
  "../tactics/utp_rel_tac"
  "../tactics/utp_xrel_tac"
  "../poly/utp_poly_tac"
  "../alpha/utp_alpha_rel"
(*  "~~/src/HOL/Algebra/Lattice" *)
begin

subsection {* UTP theories definitions *}

definition is_healthy :: 
  "'a::type \<Rightarrow> ('a \<Rightarrow> 'a) \<Rightarrow> bool" (infix "is" 50) where
"is_healthy p H \<equiv> H p = p"

definition IDEMPOTENT_OVER ::
  "'a ALPHABET set \<Rightarrow> 'a ALPHA_FUNCTION set" where
"IDEMPOTENT_OVER vs = {f . \<forall> p. \<alpha> p \<in> vs \<longrightarrow> f (f p) = f p}"

declare is_healthy_def [eval,evalr,evalrx,evalp,evala]

lemma Healthy_intro [intro]:
  "H(P) = P \<Longrightarrow> P is H"
  by (simp add: is_healthy_def)

lemma Healthy_elim [elim]:
  "\<lbrakk> Q is H; \<lbrakk> H(Q) = Q \<rbrakk> \<Longrightarrow> P \<rbrakk> \<Longrightarrow> P"
  by (simp add: is_healthy_def)

lemma Healthy_comp [closure]:
  "\<lbrakk> H2(P) is H1; P is H2 \<rbrakk> \<Longrightarrow> P is (H1 \<circ> H2)"
  by (simp add:is_healthy_def)

lemma Healthy_simp:
  "P is H \<Longrightarrow> H(P) = P"
  by (simp add:is_healthy_def)

lemma Healthy_apply [closure]:
  "\<lbrakk> H \<in> IDEMPOTENT_OVER vs; \<alpha> P \<in> vs \<rbrakk> \<Longrightarrow> H(P) is H"
  by (simp add:is_healthy_def IDEMPOTENT_OVER_def)

type_synonym 'a THEORY = "('a ALPHABET set * 'a ALPHA_FUNCTION set)"

definition WF_THEORY :: "('a THEORY) set" where
"WF_THEORY = {(A,H) | A H . \<forall> hc\<in>H. hc \<in> IDEMPOTENT_OVER A}"

typedef 'a WF_THEORY = "WF_THEORY :: ('a THEORY) set"
  morphisms DestTheory MkTheory
  by (auto simp add:WF_THEORY_def)

declare DestTheory [simp]
declare DestTheory_inverse [simp]
declare MkTheory_inverse [simp]

lemma DestTheory_intro [intro]:
  "(\<And> b. DestTheory x = DestTheory y) \<Longrightarrow> x = y"
  by (auto simp add: DestTheory_inject[THEN sym])

lemma DestTheory_elim [elim]:
  "\<lbrakk> x = y; DestTheory x = DestTheory y \<Longrightarrow> P \<rbrakk> \<Longrightarrow> P"
  by (auto)

setup_lifting type_definition_WF_THEORY

abbreviation utp_alphabets :: 
  "'a WF_THEORY \<Rightarrow> 'a ALPHABET set" ("\<A>") where
"utp_alphabets t \<equiv> fst (DestTheory t)"

abbreviation healthconds :: 
  "'a WF_THEORY \<Rightarrow> 'a ALPHA_FUNCTION set" ("\<H>") where
"healthconds t \<equiv> snd (DestTheory t)"

definition THEORY_PRED :: "'a WF_THEORY \<Rightarrow> 'a WF_ALPHA_PREDICATE set" ("\<lbrakk>_\<rbrakk>\<T>") where
"THEORY_PRED T \<equiv> {p. \<alpha> p \<in> \<A>(T) \<and>  (\<forall> H \<in> \<H>(T). p is H)}"

definition THEORY_PRED_OVER :: 
  "'a WF_THEORY \<Rightarrow> 'a ALPHABET \<Rightarrow> 'a WF_ALPHA_PREDICATE set" ("\<lbrakk>_\<rbrakk>[_]\<T>") where
"THEORY_PRED_OVER T a \<equiv> {p \<in> \<lbrakk>T\<rbrakk>\<T>. \<alpha> p = a}"

instantiation WF_THEORY :: (VALUE) join_semilattice_zero
begin

lift_definition zero_WF_THEORY :: "'a WF_THEORY" is "(UNIV, {}) :: 'a THEORY"
  by (simp add:WF_THEORY_def)

lift_definition plus_WF_THEORY :: "'a::VALUE WF_THEORY \<Rightarrow> 'a WF_THEORY \<Rightarrow> 'a WF_THEORY" 
is "(\<lambda> (A1,HC1) (A2,HC2). (A1\<inter>A2,HC1\<union>HC2)) :: 'a THEORY \<Rightarrow> 'a THEORY \<Rightarrow> 'a THEORY"
  by (auto simp add:WF_THEORY_def IDEMPOTENT_OVER_def)

definition less_eq_WF_THEORY :: "'a WF_THEORY \<Rightarrow> 'a WF_THEORY \<Rightarrow> bool" where
"less_eq_WF_THEORY x y \<longleftrightarrow> x + y = y"

definition less_WF_THEORY :: "'a WF_THEORY \<Rightarrow> 'a WF_THEORY \<Rightarrow> bool" where
"less_WF_THEORY x y \<longleftrightarrow> x \<le> y \<and> x \<noteq> y"

instance
  apply (intro_classes)
  apply (simp add:less_eq_WF_THEORY_def)
  apply (simp add:less_WF_THEORY_def)
  apply (rule DestTheory_intro)
  apply (auto simp add:plus_WF_THEORY.rep_eq zero_WF_THEORY.rep_eq)
  apply (case_tac "DestTheory x", case_tac "DestTheory y", case_tac "DestTheory z")
  apply (auto)
  apply (rule DestTheory_intro)
  apply (auto simp add:plus_WF_THEORY.rep_eq zero_WF_THEORY.rep_eq)
  apply (case_tac "DestTheory x", case_tac "DestTheory y")
  apply (auto)
  apply (rule DestTheory_intro)
  apply (auto simp add:plus_WF_THEORY.rep_eq zero_WF_THEORY.rep_eq)
  apply (case_tac "DestTheory x")
  apply (auto)
done
end

(*
definition THEORY_order :: "'a WF_THEORY \<Rightarrow> 'a ALPHABET \<Rightarrow> 'a WF_ALPHA_PREDICATE gorder" where
"THEORY_order T a = \<lparr> partial_object.carrier = \<lbrakk>T\<rbrakk>[a]\<T>, eq = op =, le = op \<sqsubseteq> \<rparr>"

interpretation THEORY_partial_order: partial_order "(THEORY_order T a)"
  where "partial_object.carrier (THEORY_order T a) = \<lbrakk>T\<rbrakk>[a]\<T>"
    and "eq (THEORY_order T a) = op ="
    and "le (THEORY_order T a) = op \<sqsubseteq>"
  apply (unfold_locales)
  apply (simp_all add:THEORY_order_def)
  apply (utp_alpha_tac, utp_pred_auto_tac)+
done
*)

abbreviation is_theory_top :: "'a WF_THEORY \<Rightarrow> 'a ALPHABET \<Rightarrow> 'a WF_ALPHA_PREDICATE \<Rightarrow> bool" where
"is_theory_top T a p \<equiv> (\<alpha> p = a \<and> p \<in> \<lbrakk>T\<rbrakk>\<T> \<and> (\<forall> q \<in> \<lbrakk>T\<rbrakk>\<T>. \<alpha> q = a \<longrightarrow> q \<sqsubseteq> p))"

abbreviation is_theory_bot :: "'a WF_THEORY \<Rightarrow> 'a ALPHABET \<Rightarrow> 'a WF_ALPHA_PREDICATE \<Rightarrow> bool" where
"is_theory_bot T a p \<equiv> (\<alpha> p = a \<and> p \<in> \<lbrakk>T\<rbrakk>\<T> \<and> (\<forall> q \<in> \<lbrakk>T\<rbrakk>\<T>. \<alpha> q = a \<longrightarrow> p \<sqsubseteq> q))"

definition has_theory_top :: "'a WF_THEORY \<Rightarrow> 'a ALPHABET \<Rightarrow> bool" where
"has_theory_top T a = (\<exists>! p. is_theory_top T a p)"

definition has_theory_bot :: "'a WF_THEORY \<Rightarrow> 'a ALPHABET \<Rightarrow> bool" where
"has_theory_bot T a = (\<exists>! p. is_theory_bot T a p)"

definition TopT :: "'a WF_THEORY \<Rightarrow> 'a ALPHABET \<Rightarrow> 'a WF_ALPHA_PREDICATE" ("\<top>\<^bsub>_[_]\<^esub>") where
"\<top>\<^bsub>T[a]\<^esub> = (THE p. is_theory_top T a p)"

definition BotT :: "'a WF_THEORY \<Rightarrow> 'a ALPHABET \<Rightarrow> 'a WF_ALPHA_PREDICATE" ("\<bottom>\<^bsub>_[_]\<^esub>") where
"BotT T a = (THE p. is_theory_bot T a p)"

subsection {* Theory of relations *}

lift_definition RELH :: "'a ALPHA_FUNCTION"
is "\<lambda> p. (Abs_fset (\<langle>\<alpha> p\<rangle>\<^sub>f - NON_REL_VAR), \<exists>\<^sub>p NON_REL_VAR. \<pi> p)"
  by (auto simp add:WF_ALPHA_PREDICATE_def WF_PREDICATE_OVER_def unrest)

lemma RELH_alphabet [alphabet]:
  "\<alpha> (RELH p) = Abs_fset (\<langle>\<alpha> p\<rangle>\<^sub>f - NON_REL_VAR)"
  by (simp add:pred_alphabet_def RELH.rep_eq)

lemma RELH_in_REL_ALPHABET [closure]:
  "\<alpha> (RELH p) \<in> REL_ALPHABET"
  by (auto simp add:alphabet REL_ALPHABET_def)

lemma EvalA_RELH [evala]:
  "\<lbrakk>RELH p\<rbrakk>\<pi> = (\<exists>\<^sub>p NON_REL_VAR. \<lbrakk>p\<rbrakk>\<pi>)"
  by (simp add:EvalA_def RELH.rep_eq)

theorem RELH_idem:
  "RELH (RELH p) = RELH p"
  by (utp_alpha_tac, utp_pred_tac)

lemma REL_ALPHABET_UNREST_NON_REL_VAR [unrest]:
  "\<alpha> p \<in> REL_ALPHABET \<Longrightarrow> NON_REL_VAR \<sharp> \<lbrakk>p\<rbrakk>\<pi>"
  by (metis UNREST_NON_REL_VAR_WF_RELATION WF_ALPHA_REL_EvalA_WF_RELATION WF_ALPHA_REL_def mem_Collect_eq)

lemma RELH_REL_ALPHABET:
  "p is RELH \<longleftrightarrow> \<alpha> p \<in> REL_ALPHABET"
  apply (rule iffI)
  apply (metis Healthy_simp RELH_in_REL_ALPHABET)
  apply (utp_alpha_tac)
  apply (rule conjI)
  apply (metis Diff_Compl NON_REL_VAR_UNDASHED_DASHED REL_ALPHABET_UNDASHED_DASHED Rep_fset_inverse le_iff_inf)
  apply (metis ExistsP_ident REL_ALPHABET_UNREST_NON_REL_VAR)
done

lift_definition REL :: "'a WF_THEORY"
is "(REL_ALPHABET, {RELH})"
  by (auto simp add:WF_THEORY_def IDEMPOTENT_OVER_def RELH.rep_eq RELH_idem)

lemma REL_WF_ALPHA_REL:
  "\<lbrakk>REL\<rbrakk>\<T> = WF_ALPHA_REL"
  by (simp add:REL.rep_eq THEORY_PRED_def RELH_REL_ALPHABET WF_ALPHA_REL_def)

lemma bot_REL_ALPHABET:
  "a \<in> REL_ALPHABET \<Longrightarrow> \<bottom>\<^bsub>REL[a]\<^esub> = true\<^bsub>a\<^esub>"
  apply (simp add:BotT_def)
  apply (rule the_equality)
  apply (simp add:alphabet closure REL_WF_ALPHA_REL)
  apply (utp_alpha_tac, utp_pred_tac)
  apply (auto simp add:REL_WF_ALPHA_REL)
  apply (drule_tac x="true\<^bsub>\<alpha> p\<^esub>" in bspec)
  apply (simp add:closure)
  apply (utp_alpha_tac, utp_pred_auto_tac)
done

lemma top_REL_ALPHABET:
  "a \<in> REL_ALPHABET \<Longrightarrow> \<top>\<^bsub>REL[a]\<^esub> = false\<^bsub>a\<^esub>"
  apply (auto simp add:TopT_def)
  apply (rule the_equality)
  apply (simp add:alphabet closure REL_WF_ALPHA_REL)
  apply (utp_alpha_tac, utp_pred_tac)
  apply (auto simp add:REL_WF_ALPHA_REL)
  apply (drule_tac x="false\<^bsub>\<alpha> p\<^esub>" in bspec)
  apply (simp add:closure)
  apply (utp_alpha_tac, utp_pred_auto_tac)
done

end
