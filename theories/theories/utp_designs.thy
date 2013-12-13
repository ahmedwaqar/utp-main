(******************************************************************************)
(* Project: Mechanisation of the UTP                                          *)
(* File: utp_designs.thy                                                      *)
(* Authors: Simon Foster, University of York                                  *)
(******************************************************************************)

header {* UTP Designs *}

theory utp_designs
imports 
  utp_base
begin

text {* Most predicates need a boolean type, so we here set the appropriate sort constraint *}

default_sort BOOL_SORT

subsection {* Design Alphabet *}

abbreviation "okay  \<equiv> MkPlainP ''okay'' True TYPE(bool) TYPE('m :: BOOL_SORT)"

subsection {* Design Signature *}

abbreviation "ok  \<equiv> `$okay`"
abbreviation "ok' \<equiv> `$okay\<acute>`"
abbreviation "ok'' \<equiv> `$okay\<acute>\<acute>`"
abbreviation "ok''' \<equiv> `$okay\<acute>\<acute>\<acute>`"
abbreviation "OKAY \<equiv> {okay\<down>,okay\<down>\<acute>}"

definition DesignD :: 
"'a WF_PREDICATE \<Rightarrow>
 'a WF_PREDICATE \<Rightarrow>
 'a WF_PREDICATE" (infixr "\<turnstile>" 60) where
"p \<turnstile> q = `ok \<and> p \<Rightarrow> ok' \<and> q`"

definition SkipDA :: "'a VAR set \<Rightarrow> 'a WF_PREDICATE" where
"SkipDA vs = true \<turnstile> II\<^bsub>(vs - OKAY)\<^esub>"

notation SkipDA ("II\<^bsub>D[_]\<^esub>")

abbreviation SkipD :: "'a WF_PREDICATE" where
"SkipD \<equiv> SkipDA REL_VAR"

notation SkipD ("II\<^sub>D")

definition AssignD ::
  "'a VAR \<Rightarrow> 'a WF_EXPRESSION \<Rightarrow> 'a WF_PREDICATE" ("(_ /:=\<^sub>D/ _)") where
"AssignD x v = (true \<turnstile> x :=\<^bsub>(REL_VAR - OKAY)\<^esub> v)"

definition BotD :: "'a WF_PREDICATE" ("\<bottom>\<^sub>D") where
"BotD = true"

definition TopD :: "'a WF_PREDICATE" ("\<top>\<^sub>D") where
"TopD = (\<not>\<^sub>p ok)"

definition JA_pred :: "'a VAR set \<Rightarrow> 'a WF_PREDICATE" ("J\<^bsub>_\<^esub>") where
"J\<^bsub>vs\<^esub> \<equiv> (ok \<Rightarrow>\<^sub>p ok') \<and>\<^sub>p II\<^bsub>vs - OKAY\<^esub>"

abbreviation J_pred :: "'a WF_PREDICATE" ("J") where
"J \<equiv> J\<^bsub>REL_VAR\<^esub>"

abbreviation ok_true :: 
  "'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" ("_\<^sup>t" [1000] 1000) where
"p\<^sup>t \<equiv> `p[true/okay\<acute>]`"

abbreviation ok_false :: 
  "'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" ("_\<^sup>f" [1000] 1000) where
"p\<^sup>f \<equiv> `p[false/okay\<acute>]`"

definition ParallelD :: 
  "'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" (infixr "\<parallel>" 100) where 
"P \<parallel> Q = (\<not>\<^sub>p P\<^sup>f \<and>\<^sub>p \<not>\<^sub>p Q\<^sup>f) \<turnstile> (P\<^sup>t \<and>\<^sub>p Q\<^sup>t)"

definition WF_VALID_MERGE :: "('a VAR set * 'a WF_PREDICATE) set" where
"WF_VALID_MERGE = UNIV"

definition ParallelMergeD :: 
  "'a WF_PREDICATE => ('a VAR set * 'a WF_PREDICATE) => 'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" (infix "\<parallel>\<^bsub>_\<^esub>" 100) where
"P \<parallel>\<^bsub>M\<^esub> Q =  ((add_sub 0 on fst M \<bullet> P) \<parallel> (add_sub 1 on fst M \<bullet> Q)) ;\<^sub>R snd M"

declare BotD_def [eval,evalr,evalrx,evalp]
declare TopD_def [eval,evalr,evalrx,evalp]
declare DesignD_def [eval,evalr,evalrx,evalp]
declare JA_pred_def [eval,evalr,evalrx,evalp]
declare SkipDA_def [eval,evalr,evalrx,evalp]
declare AssignD_def [eval,evalr,evalrx,evalp]
declare ParallelD_def [eval,evalr,evalrx,evalp]

syntax
  "_upred_desbot"   :: "upred" ("\<bottom>\<^sub>D")
  "_upred_destop"   :: "upred" ("\<top>\<^sub>D")
  "_upred_design"   :: "upred \<Rightarrow> upred \<Rightarrow> upred" (infixr "\<turnstile>" 30)
  "_upred_ok_true"  :: "upred \<Rightarrow> upred" ("_\<^sup>t" [1000] 1000)
  "_upred_ok_false" :: "upred \<Rightarrow> upred" ("_\<^sup>f" [1000] 1000)
  "_upred_SkipD"    :: "upred" ("II\<^sub>D")
  "_upred_assignd"  :: "('a, 'm) PVAR \<Rightarrow> pexpr \<Rightarrow> upred" ("_ :=\<^sub>D _" [100] 100)
  "_upred_J"        :: "upred" ("J")
  "_upred_parallel" :: "upred \<Rightarrow> upred \<Rightarrow> upred" (infix "\<parallel>" 50)

translations
  "_upred_desbot"       == "CONST BotD"
  "_upred_destop"       == "CONST TopD"
  "_upred_design p q"   == "CONST DesignD p q"
  "_upred_ok_true p"    == "CONST ok_true p"
  "_upred_ok_false p"   == "CONST ok_false p"
  "_upred_SkipD"        == "CONST SkipD"
  "_upred_assignd x v"  == "CONST AssignD x\<down> v\<down>"
  "_upred_J"            == "CONST J_pred"
  "_upred_parallel P Q" == "CONST ParallelD P Q"

subsection {* Closure / UNREST theorems *}

lemma UNREST_OKAY [unrest]:
  "OKAY \<sharp> p \<Longrightarrow> UNREST {okay\<down>} p"
  "OKAY \<sharp> p \<Longrightarrow> UNREST {okay\<down>\<acute>} p"
  by (auto intro:unrest UNREST_subset)

lemma UNREST_SkipRA_OKAY [unrest]: 
  "OKAY \<sharp> II\<^bsub>REL_VAR - OKAY\<^esub>"
  apply (rule UNREST_subset)
  apply (rule UNREST_SkipRA)
  apply (simp)
done

lemma UNREST_TopD [unrest]:
  "okay\<down> \<notin> vs \<Longrightarrow> vs \<sharp> \<top>\<^sub>D"
  by (simp add:TopD_def unrest)

lemma UNREST_SkipD_NON_REL_VAR [unrest]:
  "NON_REL_VAR \<sharp> II\<^sub>D"
  apply (simp add:SkipDA_def DesignD_def)
  apply (force simp add:PVAR_VAR_MkPVAR intro: unrest)
done

lemma UNREST_DesignD [unrest]:
  "\<lbrakk> vs \<sharp> p; vs \<sharp> q; okay\<down> \<notin> vs; okay\<down>\<acute> \<notin> vs \<rbrakk>
   \<Longrightarrow> vs \<sharp> (p \<turnstile> q)"
  by (simp add:DesignD_def unrest)

lemma UNREST_ParallelD [unrest]:
  "\<lbrakk> vs \<sharp> p; vs \<sharp> q; okay\<down> \<notin> vs; okay\<down>\<acute> \<notin> vs \<rbrakk>
   \<Longrightarrow> vs \<sharp> (p \<parallel> q)"
  by (auto intro!:unrest closure simp add:typing defined closure ParallelD_def)

lemma SubstP_UNREST_OKAY [usubst]:
  "\<lbrakk> x \<in> OKAY; OKAY \<sharp> p; v \<rhd>\<^sub>e x \<rbrakk> \<Longrightarrow> p[v/\<^sub>px] = p"
  by (utp_pred_tac)

lemma UNREST_JA [unrest]:
  "UNREST (VAR - (vs \<union> OKAY)) J\<^bsub>vs\<^esub>"
  by (auto intro:unrest UNREST_subset simp add:JA_pred_def)

lemma UNREST_SkipDA [unrest]:
  "UNREST (VAR - (vs \<union> OKAY)) II\<^bsub>D[vs]\<^esub>"
  by (auto intro:unrest UNREST_subset simp add:SkipDA_def)

lemma TopD_rel_closure [closure]:
  "\<top>\<^sub>D \<in> WF_RELATION"
  by (simp add:TopD_def closure)

lemma TopD_cond_closure [closure]: 
  "\<top>\<^sub>D \<in> WF_CONDITION"
  by (simp add:TopD_def closure)

lemma DesignD_rel_closure [closure]:
  "\<lbrakk>P \<in> WF_RELATION; Q \<in> WF_RELATION\<rbrakk> \<Longrightarrow> P \<turnstile> Q \<in> WF_RELATION"
  by (simp add:DesignD_def closure)

lemma SkipD_rel_closure [closure]:
  "II\<^sub>D \<in> WF_RELATION"
  by (auto intro:closure simp add:SkipDA_def)

lemma AssignD_rel_closure [closure]:
  "\<lbrakk> x \<in> UNDASHED; NON_REL_VAR \<union> OKAY \<sharp> v; v \<rhd>\<^sub>e x \<rbrakk> \<Longrightarrow>
     x :=\<^sub>D v \<in> WF_RELATION"
  by (auto intro!:DesignD_rel_closure intro:closure simp add:AssignD_def)

theorem J_closure [closure]:
  "J \<in> WF_RELATION"
  by (simp add:JA_pred_def closure)

lemma ParallelD_rel_closure [closure]:
  "\<lbrakk> P \<in> WF_RELATION; Q \<in> WF_RELATION \<rbrakk> \<Longrightarrow> P \<parallel> Q \<in> WF_RELATION"
  by (simp add:ParallelD_def unrest typing closure defined)

lemma TopD_TrueP_uniqs [simp]:
  "true \<noteq> \<top>\<^sub>D" "\<top>\<^sub>D \<noteq> true"
  by (utp_pred_tac, rule_tac x="\<B>(okay\<down> :=\<^sub>b TrueV)" in exI, simp add:typing inju)+

lemma TopD_FalseP_uniqs [simp]:
  "false \<noteq> \<top>\<^sub>D" "\<top>\<^sub>D \<noteq> false"
  by (utp_poly_tac, rule_tac x="\<B>(okay :=\<^sub>* False)" in exI, simp add:typing defined)+

subsection {* Design Laws *}

theorem DesignD_extreme_point_true:
  "false \<turnstile> false = false \<turnstile> true"
  "false \<turnstile> true = true"
  by (utp_pred_tac+)

theorem DesignD_extreme_point_nok:
  "true \<turnstile> false = \<not>\<^sub>p ok"
  "\<not>\<^sub>p ok = \<top>\<^sub>D"
  by (utp_pred_tac+)

theorem DesignD_assumption:
  assumes "OKAY \<sharp> P"
  shows "`\<not> (P \<turnstile> Q)\<^sup>f` = `P \<and> ok`"
  using assms
  by (utp_poly_auto_tac)

theorem DesignD_commitment:
  assumes
    "OKAY \<sharp> P" 
    "OKAY \<sharp> Q" 
  shows "`(P \<turnstile> Q)\<^sup>t` = `(ok \<and> P \<Rightarrow> Q)`"
  using assms by (utp_poly_auto_tac)

theorem DesignD_export_precondition:
  "(P \<turnstile> Q) = (P \<turnstile> P \<and>\<^sub>p Q)"
  by (utp_pred_tac)

theorem DesignD_embed_right: 
  "`P \<turnstile> (Q \<turnstile> R)` = `P \<turnstile> (Q \<Rightarrow> R)`"
  by (utp_pred_auto_tac)

theorem DesignD_SkipD_right:
  "`P \<turnstile> II\<^sub>D` = `P \<turnstile> II\<^bsub>REL_VAR - OKAY\<^esub>`"
  by (simp add:SkipDA_def DesignD_embed_right)

theorem DesignD_AssignD_right:
  "P \<turnstile> (x :=\<^sub>D v) = P \<turnstile> x :=\<^bsub>(REL_VAR - OKAY) \<^esub>v"
  by (simp add:AssignD_def DesignD_embed_right)

theorem DesignD_AssignD_true [simp]:
  "true \<turnstile> x :=\<^sub>D v = x :=\<^sub>D v"
  by (simp add:AssignD_def DesignD_embed_right)

lemma SkipD_SkipDA_right_link:
  assumes 
    "HOMOGENEOUS vs"
    "D\<^sub>1 - out vs \<sharp> P"
    "okay\<down> \<in> vs" 
  shows "P ;\<^sub>R II\<^sub>D = P ;\<^sub>R II\<^bsub>D[vs]\<^esub>"
  using assms
  apply (subst SemiR_ExistsP_insert_right[of "D\<^sub>0 - (in vs \<union> {okay\<down>})"])
  apply (simp add:var_dist)
  apply (rule UNREST_subset)
  apply (auto simp add:SkipDA_def DesignD_def ImpliesP_def ExistsP_OrP_dist)
  apply (subst ExistsP_AndP_expand2[THEN sym])
  apply (auto intro:unrest)
  apply (simp add:SkipRA_alt_in_def ExistsP_union[THEN sym] var_dist closure)
  apply (subst ExistsP_ident)
  apply (auto intro:unrest)
done  

lemma SkipD_SkipDA_left_link:
  assumes 
    "HOMOGENEOUS vs"
    "D\<^sub>0 - in vs \<sharp> P"
    "okay\<down>\<acute> \<in> vs" 
  shows "II\<^sub>D ;\<^sub>R P = II\<^bsub>D[vs]\<^esub> ;\<^sub>R P" 
  using assms
  apply (subst SemiR_ExistsP_insert_left[of "D\<^sub>1 - (out vs \<union> {okay\<down>\<acute>})"])
  apply (simp add:var_dist)
  apply (rule UNREST_subset)
  apply (auto simp add:SkipDA_def DesignD_def ImpliesP_def ExistsP_OrP_dist)
  apply (metis (hide_lams, no_types) Diff_disjoint Diff_iff Int_absorb1 UNDASHED_minus_in VAR_subset dash_undash_DASHED hom_alphabet_undash in_VAR in_vars_diff out_member)
  apply (subst ExistsP_AndP_expand2[THEN sym])
  apply (auto intro:unrest)
  apply (simp add:SkipRA_alt_out_def ExistsP_union[THEN sym] var_dist closure)
  apply (subst ExistsP_ident)
  apply (auto intro:unrest)
  apply (metis DesignD_extreme_point_nok(2) Diff_iff MkPlain_UNDASHED PVAR_VAR_MkPVAR UNDASHED_eq_dash_contra UNREST_TopD dash_undash_DASHED)
done  

text {* Design refinement law *}

theorem DesignD_refinement:
  assumes 
    "OKAY \<sharp> P1" 
    "OKAY \<sharp> P2"
    "OKAY \<sharp> Q1" 
    "OKAY \<sharp> Q2"
  shows "`P1 \<turnstile> Q1 \<sqsubseteq> P2 \<turnstile> Q2` = `[P1 \<Rightarrow> P2] \<and> [P1 \<and> Q2 \<Rightarrow> Q1]`"
proof -
  have "`(P1 \<turnstile> Q1) \<sqsubseteq> (P2 \<turnstile> Q2)` = `[P2 \<turnstile> Q2 \<Rightarrow> P1 \<turnstile> Q1]`"
    by (utp_pred_tac)

  also have "... = `[(ok \<and> P2 \<Rightarrow> ok' \<and> Q2) \<Rightarrow> (ok \<and> P1 \<Rightarrow> ok' \<and> Q1)]`"
    by (utp_pred_tac)

  also with assms have "... = `[(P2 \<Rightarrow> ok' \<and> Q2) \<Rightarrow> (P1 \<Rightarrow> ok' \<and> Q1)]`"
    apply (rule_tac trans)
    apply (rule_tac x="okay\<down>" in BoolType_aux_var_split_taut)
    apply (simp_all add:usubst unrest typing defined)
  done

  also from assms have "... = `[(\<not> P2 \<Rightarrow> \<not> P1) \<and> ((P2 \<Rightarrow> Q2) \<Rightarrow> (P1 \<Rightarrow> Q1))]`"
    apply (rule_tac trans)
    apply (rule_tac x="okay\<acute>\<down>" in BoolType_aux_var_split_taut)
    apply (simp_all add:usubst typing defined)
  done

  also have "... = `[(P1 \<Rightarrow> P2) \<and> ((P2 \<Rightarrow> Q2) \<Rightarrow> (P1 \<Rightarrow> Q1))]`"
    by (utp_pred_auto_tac)

  also have "... = `[(P1 \<Rightarrow> P2)] \<and> [P1 \<and> Q2 \<Rightarrow> Q1]`"
    by (utp_pred_auto_tac)

  finally show ?thesis .
qed

theorem DesignD_refine [refine]:
  assumes 
    "OKAY \<sharp> P1"
    "OKAY \<sharp> P2"
    "OKAY \<sharp> Q1"
    "OKAY \<sharp> Q2"
    "P2 \<sqsubseteq> P1" 
    "Q1 \<sqsubseteq> P1 \<and>\<^sub>p Q2" 
  shows "P1 \<turnstile> Q1 \<sqsubseteq> P2 \<turnstile> Q2"
  using assms
  apply (simp add:less_eq_WF_PREDICATE_def DesignD_refinement)
  apply (simp add:less_eq_WF_PREDICATE_def RefP_def)
  apply (metis AndP_idem TrueP_eq_ClosureP)
done

theorem DesignD_diverge:
  "`(P \<turnstile> Q)[false/okay]` = true"
  by (simp add:DesignD_def usubst typing defined evalp)

theorem DesignD_left_zero:
  fixes P :: "'m WF_PREDICATE"
  assumes 
    "P \<in> WF_RELATION"
    "Q \<in> WF_RELATION"
  shows "true ;\<^sub>R (P \<turnstile> Q) = true"
proof -

  from assms have "`true ; (P \<turnstile> Q)` = `\<exists> okay\<acute>\<acute>. true[$okay\<acute>\<acute>/okay\<acute>] ; (P \<turnstile> Q)[$okay\<acute>\<acute>/okay]`"
    by (simp add:SemiR_extract_variable erasure typing closure unrest)

  also from assms have "... = `(true[false/okay\<acute>] ; (P \<turnstile> Q)[false/okay]) \<or> (true[true/okay\<acute>] ; (P \<turnstile> Q)[true/okay])`"
    apply (rule_tac trans)
    apply (rule BoolType_aux_var_split_exists, simp_all)
    apply (simp add:erasure typing inju)
    apply (simp add: usubst)
    apply (simp add: SubstP_TrueP SubstP_NON_REL_VAR unrest closure)
    apply (simp add: SubstP_twice_2 unrest usubst typing defined)
  done

  also have "... = `((true ; true) \<or> (true ; ((P \<turnstile> Q)[true/okay])))`"
    by (simp add:usubst closure typing DesignD_diverge)

  ultimately show ?thesis
    by (simp add:closure SemiR_TrueP_precond)
qed

text {* The choice of two designs conjoins the assumptions and disjoins the commitments *}

theorem DesignD_choice:
  "(P1 \<turnstile> Q1) \<sqinter> (P2 \<turnstile> Q2) = `(P1 \<and> P2 \<turnstile> Q1 \<or> Q2)`"
  by (utp_pred_auto_tac)

theorem DesignD_cond:
  "`(P1 \<turnstile> Q1) \<lhd> b \<rhd> (P2 \<turnstile> Q2)` = `((P1 \<lhd> b \<rhd> P2) \<turnstile> (Q1 \<lhd> b \<rhd> Q2))`"
  by (utp_pred_auto_tac)

theorem DesignD_composition:
  assumes 
  "(P1 \<in> WF_RELATION)" "(P2 \<in> WF_RELATION)" 
  "(Q1 \<in> WF_RELATION)" "(Q2 \<in> WF_RELATION)" 
  "OKAY \<sharp> P1" "OKAY \<sharp> P2" "OKAY \<sharp> Q1" "OKAY \<sharp> Q2"
  shows "`(P1 \<turnstile> Q1) ; (P2 \<turnstile> Q2)` = `((\<not> ((\<not> P1) ; true)) \<and> \<not> (Q1 ; (\<not> P2))) \<turnstile> (Q1 ; Q2)`"
proof -

  have " `(P1 \<turnstile> Q1) ; (P2 \<turnstile> Q2)` 
        = `\<exists> okay\<acute>\<acute> . ((P1 \<turnstile> Q1)[$okay\<acute>\<acute>/okay\<acute>] ; (P2 \<turnstile> Q2)[$okay\<acute>\<acute>/okay])`"
    by (rule SemiR_extract_variable_ty, simp_all add:closure typing unrest assms)

  also have "... = ` ((P1 \<turnstile> Q1)[false/okay\<acute>] ; (P2 \<turnstile> Q2)[false/okay]) 
                      \<or> ((P1 \<turnstile> Q1)[true/okay\<acute>] ; (P2 \<turnstile> Q2)[true/okay])`"
    by (simp add:ucases typing usubst defined closure unrest DesignD_def assms erasure inju SubstP_VarP_single_UNREST)

  also from assms
  have "... = `((ok \<and> P1 \<Rightarrow> Q1) ; (P2 \<Rightarrow> ok' \<and> Q2)) \<or> ((\<not> (ok \<and> P1)) ; true)`"
    by (simp add: typing usubst defined unrest DesignD_def OrP_comm erasure)

  also have "... = `((\<not> (ok \<and> P1) ; (P2 \<Rightarrow> ok' \<and> Q2)) \<or> \<not> (ok \<and> P1) ; true) 
                       \<or> Q1 ; (P2 \<Rightarrow> ok' \<and> Q2)`"
    by (smt OrP_assoc OrP_comm SemiR_OrP_distr ImpliesP_def)

  also have "... = `(\<not> (ok \<and> P1) ; true) \<or> Q1 ; (P2 \<Rightarrow> ok' \<and> Q2)`"
    by (smt SemiR_OrP_distl utp_pred_simps(9))

  also have "... = `(\<not>ok ; true) \<or> (\<not>P1 ; true) \<or> (Q1 ; \<not>P2) \<or> (ok' \<and> (Q1 ; Q2))`"
  proof -
    from assms have "`Q1 ; (P2 \<Rightarrow> ok' \<and> Q2)` = `(Q1 ; \<not>P2) \<or> (ok' \<and> (Q1 ; Q2))`"
      by (simp add:ImpliesP_def SemiR_OrP_distl AndP_comm SemiR_AndP_right_postcond closure)
    
    thus ?thesis by (smt OrP_assoc SemiR_OrP_distr demorgan2)
  qed

  also have "... = `(\<not> (\<not> P1 ; true) \<and> \<not> (Q1 ; \<not> P2)) \<turnstile> (Q1 ; Q2)`"
  proof -
    have "`(\<not> ok) ; true \<or> (\<not> P1) ; true` = `\<not> ok \<or> (\<not> P1) ; true`"
      by (simp add: SemiR_TrueP_precond closure)

    thus ?thesis
      by (smt DesignD_def ImpliesP_def OrP_assoc demorgan2 demorgan3)
  qed

  finally show ?thesis .
qed

theorem DesignD_composition_cond:
  assumes 
    "p1 \<in> WF_CONDITION" 
    "P2 \<in> WF_RELATION" 
    "Q1 \<in> WF_RELATION" 
    "Q2 \<in> WF_RELATION"
    "OKAY \<sharp> p1" 
    "OKAY \<sharp> P2" 
    "OKAY \<sharp> Q1" 
    "OKAY \<sharp> Q2"
  shows "`(p1 \<turnstile> Q1) ; (P2 \<turnstile> Q2)` = `(p1 \<and> \<not> (Q1 ; \<not> P2)) \<turnstile> (Q1 ; Q2)`"
  by (simp add:DesignD_composition closure assms unrest)

theorem DesignD_composition_wp:
  assumes 
    "p1 \<in> WF_CONDITION" 
    "P2 \<in> WF_RELATION" 
    "Q1 \<in> WF_RELATION" 
    "Q2 \<in> WF_RELATION"
    "OKAY \<sharp> p1" "OKAY \<sharp> P2" 
    "OKAY \<sharp> Q1" "OKAY \<sharp> Q2"
  shows "`(p1 \<turnstile> Q1) ; (P2 \<turnstile> Q2)` = `(p1 \<and> (Q1 wp P2)) \<turnstile> (Q1 ; Q2)`"
  by (simp add: DesignD_composition_cond closure WeakPrecondP_def assms)

theorem AssignD_idem :
  assumes 
    "x \<in> UNDASHED" 
    "x \<notin> OKAY"
    "OKAY \<union> (VAR - (in vs - {x})) \<sharp> v"
    "v \<rhd>\<^sub>e x"
  shows "x :=\<^sub>D v ;\<^sub>R x :=\<^sub>D v = x :=\<^sub>D v"
  using assms
  apply (simp add:AssignD_def)
  apply (subst DesignD_composition_wp)
  apply (simp_all add:closure unrest wp typing defined UNREST_EXPR_subset)
  apply (rule closure)
  apply (simp_all)
  apply (rule UNREST_EXPR_subset)
  apply (simp)
  apply (auto)[1]
  apply (metis (full_types) UNDASHED_not_NON_REL_VAR in_mono utp_var.in_UNDASHED)
  apply (rule unrest)
  apply (simp_all)
  apply (rule UNREST_EXPR_subset)
  apply (simp)
  apply (auto)[1]
  apply (metis (full_types) UNDASHED_not_NON_REL_VAR utp_var.in_UNDASHED set_mp)
  apply (subst AssignRA_idem)
  apply (simp_all add:var_dist closure)
  apply (metis dash_elim)
  apply (rule UNREST_EXPR_subset)
  apply (auto)
  apply (metis (full_types) utp_var.in_UNDASHED set_mp)
done

theorem ParallelD_DesignD:
  assumes 
    "OKAY \<sharp> P1" 
    "OKAY \<sharp> P2" 
    "OKAY \<sharp> Q1" 
    "OKAY \<sharp> Q2"
  shows "`(P1 \<turnstile> P2) \<parallel> (Q1 \<turnstile> Q2)` = `(P1 \<and> Q1) \<turnstile> (P2 \<and> Q2)`"
  using assms 
  by (utp_poly_auto_tac)

theorem ParallelD_comm:
  "P \<parallel> Q = Q \<parallel> P"
  by (utp_pred_auto_tac)

theorem ParallelD_assoc:
  fixes P :: "'a WF_PREDICATE"
  shows "P \<parallel> Q \<parallel> R = (P \<parallel> Q) \<parallel> R"
  by (utp_poly_auto_tac)

subsection {* Design Healthiness Conditions *}

subsubsection {* H1: Only observation after starting *}

definition "H1(P) = `ok \<Rightarrow> P`"

declare H1_def [eval,evalr,evalrx]

theorem H1_true [closure]:
  "true is H1"
  by (utp_pred_tac)

theorem DesignD_is_H1 [closure]:
  "P \<turnstile> Q is H1"
  by (utp_pred_auto_tac)

theorem SkipD_is_H1 [closure]:
  "II\<^sub>D is H1"
  by (simp add:SkipDA_def closure)

theorem H1_AndP: "H1 (p \<and>\<^sub>p q) = H1(p) \<and>\<^sub>p H1(q)"
  by (utp_pred_auto_tac)

theorem H1_OrP: "H1 (p \<or>\<^sub>p q) = H1(p) \<or>\<^sub>p H1(q)"
  by (utp_pred_auto_tac)

theorem H1_CondR: 
  "`H1(P \<lhd> c \<rhd> Q)` = `H1(P) \<lhd> c \<rhd> H1(Q)`"
  by (utp_pred_auto_tac)

theorem H1_algebraic_intro:
  assumes 
    "R \<in> WF_RELATION"  
    "(true ;\<^sub>R R = true)" 
    "(II\<^sub>D ;\<^sub>R R = R)"
  shows "R is H1"
proof -
  let ?vs = "REL_VAR - OKAY"
  have "R = II\<^sub>D ;\<^sub>R R" by (simp add: assms)

  also have "... = `(true \<turnstile> II\<^bsub>?vs\<^esub>) ; R`"
    by (simp add:SkipDA_def)

  also have "... = `(ok \<Rightarrow> (ok' \<and> II\<^bsub>?vs\<^esub>)) ; R`"
    by (simp add:DesignD_def)

  also have "... = `(ok \<Rightarrow> (ok \<and> ok' \<and> II\<^bsub>?vs\<^esub>)) ; R`"
    by (smt ImpliesP_export)

  also have "... = `(ok \<Rightarrow> (ok \<and> $okay\<acute> = $okay \<and> II\<^bsub>?vs\<^esub>)) ; R`"
    apply (simp add:VarP_EqualP_aux typing defined erasure)
    apply (auto simp add:evalr unrest closure evale relcomp_unfold)
  done

  also have "... = `(ok \<Rightarrow> II) ; R`"
    by (simp add:SkipRA_unfold[THEN sym] 
        SkipR_as_SkipRA ImpliesP_export[THEN sym] erasure closure typing)

  also have "... = `((\<not> ok) ; R \<or> R)`"
    by (simp add:ImpliesP_def SemiR_OrP_distr)

  also have "... = `(((\<not> ok) ; true) ; R \<or> R)`"
    by (simp add:SemiR_TrueP_precond closure)

  also have "... = `((\<not> ok) ; true \<or> R)`"
    by (simp add:SemiR_assoc[THEN sym] assms)

  also have "... = `ok \<Rightarrow> R`"
    by (simp add:SemiR_TrueP_precond closure ImpliesP_def)

  finally show ?thesis by (simp add:is_healthy_def H1_def)
qed

theorem H1_left_zero:
  assumes "P \<in> WF_RELATION" "P is H1"
  shows "`true ; P` = `true`"
proof -
  from assms have "`true ; P` = `true ; (ok \<Rightarrow> P)`"
    by (simp add:is_healthy_def H1_def)

  also have "... = `true ; (\<not> ok \<or> P)`"
    by (simp add:ImpliesP_def)

  also have "... = `(true ; \<not> ok) \<or> (true ; P)`"
    by (simp add:SemiR_OrP_distl)

  also from assms have "... = `true \<or> (true ; P)`"
    by (simp add:SemiR_precond_left_zero closure)

  finally show ?thesis by simp
qed

theorem H1_left_unit:
  assumes "P \<in> WF_RELATION" "P is H1"
  shows "`II\<^sub>D ; P` = `P`"
proof -
  let ?vs = "REL_VAR - OKAY"
  have "`II\<^sub>D ; P` = `(true \<turnstile> II\<^bsub>?vs\<^esub>) ; P`" by (simp add:SkipDA_def)
  also have "... = `(ok \<Rightarrow> ok' \<and> II\<^bsub>?vs\<^esub>) ; P`" 
    by (simp add:DesignD_def)
  also have "... = `(ok \<Rightarrow> ok \<and> ok' \<and> II\<^bsub>?vs\<^esub>) ; P`" 
    by (smt ImpliesP_export)
  also have "... = `(ok \<Rightarrow> ok \<and> $okay\<acute> = $okay \<and> II\<^bsub>?vs\<^esub>) ; P`"
    by (simp add:VarP_EqualP_aux erasure typing closure, utp_pred_tac)
  also have "... = `(ok \<Rightarrow> II) ; P`"
    by (simp add: SkipR_as_SkipRA SkipRA_unfold[of "okay\<down>"] ImpliesP_export[THEN sym]
                  erasure typing closure)
  also have "... = `((\<not> ok) ; P \<or> P)`"
    by (simp add:ImpliesP_def SemiR_OrP_distr)
  also have "... = `(((\<not> ok) ; true) ; P \<or> P)`"
    by (simp add: SemiR_TrueP_precond closure)
  also have "... = `((\<not> ok) ; (true ; P) \<or> P)`"
    by (metis SemiR_assoc)
  also from assms have "... = `(ok \<Rightarrow> P)`"
    by (simp add:H1_left_zero ImpliesP_def SemiR_TrueP_precond closure)
  finally show ?thesis using assms
    by (simp add:H1_def is_healthy_def)
qed

theorem SkipD_left_unit:
  assumes "P \<in> WF_RELATION" "Q \<in> WF_RELATION"
  shows "`II\<^sub>D ; (P \<turnstile> Q)` = `P \<turnstile> Q`"
  by (simp add: DesignD_is_H1 DesignD_rel_closure H1_left_unit assms)

theorem H1_algebraic:
  assumes "P \<in> WF_RELATION"
  shows "P is H1 \<longleftrightarrow> (`true ; P` = `true`) \<and> (`II\<^sub>D ; P` = `P`)"
   by (metis H1_algebraic_intro H1_left_unit H1_left_zero assms)
  
theorem H1_false:
  "H1 false \<noteq> false"
  apply (auto simp add:H1_def eval evale)
  apply (rule_tac x="\<B>(okay\<down> :=\<^sub>b FalseV)" in exI)
  apply (simp add:typing defined)
done

theorem H1_ImpliesP_SemiR:
  assumes "p \<in> WF_CONDITION" "Q \<in> WF_RELATION" "R \<in> WF_RELATION" "R is H1"
  shows "`p \<Rightarrow> (Q ; R)` = `(p \<Rightarrow> Q) ; R`"
proof -

  have "`(p \<Rightarrow> Q) ; R` = `\<not> p ; R \<or> (Q ; R)`"
    by (metis ImpliesP_def SemiR_OrP_distr)

  also have "... = `(\<not> p ; true) ; R \<or> (Q ; R)`"
    by (metis NotP_cond_closure SemiR_TrueP_precond assms(1))

  also have "... = `\<not> p \<or> (Q ; R)`"
    by (metis H1_left_zero SemiR_assoc assms SemiR_condition_comp utp_pred_simps(3))

  ultimately show ?thesis
    by (metis ImpliesP_def)

qed

theorem H1_idempotent:
  "H1 (H1 p) = H1 p"
  by (rule, simp add:H1_def eval)

theorem H1_monotone:
  "p \<sqsubseteq> q \<Longrightarrow> H1 p \<sqsubseteq> H1 q"
  by (utp_pred_tac)

subsubsection {* H2: No requirement of non-termination *}

definition "H2(P) = `P ; J`"

declare H2_def [eval,evalr,evalrx]

theorem J_split:
  assumes "P \<in> WF_RELATION"
  shows "`P ; J` = `P\<^sup>f \<or> (P\<^sup>t \<and> ok')`"
proof -

  let ?vs = "(REL_VAR - OKAY) :: 'a VAR set"

  have "`P ; J` = `P ; ((ok \<Rightarrow> ok') \<and> II\<^bsub>?vs\<^esub>)`"
    by (simp add:JA_pred_def)

  also have "... = `P ; ((ok \<Rightarrow> ok \<and> ok') \<and> II\<^bsub>?vs\<^esub>)`"
    by (metis ImpliesP_export)

  also have "... = `P ; ((\<not> ok \<or> (ok \<and> ok')) \<and> II\<^bsub>?vs\<^esub>)`"
    by (utp_rel_auto_tac)

  also have "... = `(P ; (\<not> ok \<and> II\<^bsub>?vs\<^esub>)) \<or> (P ; (ok \<and> (II\<^bsub>?vs\<^esub> \<and> ok')))`"
    by (smt AndP_OrP_distr AndP_assoc AndP_comm SemiR_OrP_distl)
    
  also have "... = `P\<^sup>f \<or> (P\<^sup>t \<and> ok')`"
  proof -
    from assms have "`(P ; (\<not> ok \<and> II\<^bsub>?vs\<^esub>))` = `P\<^sup>f`"
      by (simp add: VarP_NotP_EqualP_aux SemiR_left_one_point closure typing defined unrest urename usubst SemiR_SkipRA_right var_dist erasure)

    moreover have "`(P ; (ok \<and> (II\<^bsub>?vs\<^esub> \<and> ok')))` = `(P\<^sup>t \<and> ok')`"
    proof -
      have "`(P ; (ok \<and> (II\<^bsub>?vs\<^esub> \<and> ok')))` = `(P ; (ok \<and> II\<^bsub>?vs\<^esub>)) \<and> ok'`"
        apply (insert SemiR_TrueP_postcond[OF VarP_precond_closure[of "okay\<down>\<acute>",simplified]])
        apply (auto simp add:evalrx closure assms)
      done

      moreover from assms have "`(P ; (ok \<and> II\<^bsub>?vs\<^esub>))` =  `P\<^sup>t`"
        by (simp add: VarP_EqualP_aux SemiR_left_one_point closure typing defined unrest urename usubst SemiR_SkipRA_right var_dist erasure)
     
      finally show ?thesis .
    qed

    ultimately show ?thesis by (simp)
  qed

  finally show ?thesis .
qed

theorem H2_equivalence:
  assumes "P \<in> WF_RELATION"
  shows "P is H2 \<longleftrightarrow> `P\<^sup>f \<Rightarrow> P\<^sup>t`"
proof -
  from assms have "`[P \<Leftrightarrow> (P ; J)]` = `[P \<Leftrightarrow> (P\<^sup>f \<or> (P\<^sup>t \<and> ok'))]`"
    by (simp add:J_split)

  also have "... = `[(P \<Leftrightarrow> P\<^sup>f \<or> P\<^sup>t \<and> ok')\<^sup>f \<and> (P \<Leftrightarrow> P\<^sup>f \<or> P\<^sup>t \<and> ok')\<^sup>t]`"
    by (simp add: ucases erasure)

  also have "... = `[(P\<^sup>f \<Leftrightarrow> P\<^sup>f) \<and> (P\<^sup>t \<Leftrightarrow> P\<^sup>f \<or> P\<^sup>t)]`"
    by (simp add:usubst closure typing defined erasure)

  also have "... = `[P\<^sup>t \<Leftrightarrow> (P\<^sup>f \<or> P\<^sup>t)]`"
    by (utp_pred_tac)

  ultimately show ?thesis
    by (utp_pred_auto_tac)
qed

theorem J_is_H2:
  "H2(J) = J"
proof -
  have "H2(J) = `J\<^sup>f \<or> (J\<^sup>t \<and> ok')`"
    by (simp add:H2_def closure J_split)

  also have "... = `((\<not> ok \<and> II\<^bsub>(REL_VAR - OKAY)\<^esub>) \<or> II\<^bsub>(REL_VAR - OKAY)\<^esub> \<and> ok')`"
    by (simp add:JA_pred_def usubst typing defined closure erasure)

  also have "... = `(\<not> ok \<or> ok') \<and> II\<^bsub>REL_VAR - OKAY\<^esub>`"
    by (utp_pred_auto_tac)

  also have "... = `(ok \<Rightarrow> ok') \<and> II\<^bsub>REL_VAR - OKAY\<^esub>`"
    by (utp_pred_tac)

  ultimately show ?thesis
    by (metis JA_pred_def)
qed

theorem J_idempotent [simp]: "`J ; J` = J"
  by (simp add:H2_def[THEN sym] J_is_H2)

theorem H2_idempotent:
  "H2 (H2 p) = H2 p"
  apply (simp add:H2_def)
  apply (metis J_idempotent SemiR_assoc)
done

theorem H2_monotone:
  "p \<sqsubseteq> q \<Longrightarrow> H2 p \<sqsubseteq> H2 q"
  by (utp_rel_auto_tac)

theorem DesignD_is_H2 [closure]:
  "\<lbrakk> P \<in> WF_RELATION; Q \<in> WF_RELATION; OKAY \<sharp> P; OKAY \<sharp> Q \<rbrakk> \<Longrightarrow> P \<turnstile> Q is H2"
  apply (simp add:H2_equivalence closure)
  apply (simp add:DesignD_def usubst closure typing defined erasure)
  apply (utp_pred_auto_tac)
done

theorem H1_H2_commute: "H1 (H2 P) = H2 (H1 P)"
  apply (simp add:H1_def H2_def ImpliesP_def)
  apply (smt DesignD_is_H2 FalseP_rel_closure H2_def SemiR_OrP_distr TrueP_rel_closure UNREST_FalseP UNREST_TrueP DesignD_extreme_point_nok is_healthy_def)
done

theorem H1_H2_is_DesignD:
  assumes "P \<in> WF_RELATION" "P is H1" "P is H2"
  shows "P = `\<not>P\<^sup>f \<turnstile> P\<^sup>t`"
proof -
  have "P = `ok \<Rightarrow> P`"
    by (metis H1_def assms(2) is_healthy_def) 
  
  also have "... = `ok \<Rightarrow> (P ; J)`"
    by (metis H2_def assms(3) is_healthy_def) 

  also have "... = `ok \<Rightarrow> (P\<^sup>f \<or> (P\<^sup>t \<and> ok'))`"
    by (metis J_split assms(1))

  also have "... = `ok \<and> (\<not> P\<^sup>f) \<Rightarrow> ok' \<and> P\<^sup>t`"
    by (utp_pred_auto_tac)

  also have "... = `(\<not> P\<^sup>f) \<turnstile> P\<^sup>t`"
    by (metis DesignD_def)

  finally show ?thesis .
qed

theorem H2_AndP_closure:
  assumes 
  "P \<in> WF_RELATION" "Q \<in> WF_RELATION" 
  "P is H2" "Q is H2"
  shows "`P \<and> Q` is H2"
  using assms
  apply (simp add:H2_equivalence closure usubst)
  apply (utp_pred_auto_tac)
done

theorem H2_OrP:
  "`H2(P \<or> Q)` = `H2(P) \<or> H2(Q)`"
  by (simp add:H2_def SemiR_OrP_distr)

theorem H2_CondR:
  assumes "P \<in> WF_RELATION" "Q \<in> WF_RELATION" "c \<in> WF_CONDITION"
  shows "`H2(P \<lhd> c \<rhd> Q)` = `H2(P) \<lhd> c \<rhd> H2(Q)`"
  by (simp add:H2_def CondR_SemiR_distr assms closure)

text {* H1 and H2 can be distinguished by the following counterexample *}

abbreviation "NoTerminate \<equiv> `ok \<Rightarrow> \<not> ok'`"

theorem NoTerminate_H1: 
  "NoTerminate is H1"
  by (utp_pred_auto_tac)

theorem NoTerminate_not_H2:
  "\<not> (NoTerminate is H2)"
  apply (simp add:H2_equivalence closure usubst typing defined)
  apply (utp_pred_tac)
  apply (rule_tac x="\<B>(okay\<down> :=\<^sub>b TrueV)" in exI, simp add:typing)
done

subsubsection {* H3: Assumption is a condition *}

definition "H3(P) = `P ; II\<^sub>D`"
declare H3_def [eval,evalr,evalrx]

theorem SkipD_idempotent:
  "`II\<^sub>D ; II\<^sub>D` = `II\<^sub>D`"
  by (utp_xrel_auto_tac)

theorem H3_idempotent:
  "H3 (H3 p) = H3 p"
  by (metis (hide_lams, no_types) H3_def SemiR_assoc SkipD_idempotent)

theorem H3_monotone:
  "p \<sqsubseteq> q \<Longrightarrow> H3 p \<sqsubseteq> H3 q"
  by (utp_rel_auto_tac)

theorem H3_WF_CONDITION: 
  assumes "P \<in> WF_CONDITION"
  shows "P is H3"
proof -
  from assms have "`P ; II\<^sub>D` = `P ; (true ; II\<^sub>D)`"
    by (metis SemiR_TrueP_precond SemiR_assoc)

  also have "... = `P ; true`"
    by (metis H1_left_zero SkipD_is_H1 SkipD_rel_closure)

  finally show ?thesis
    by (metis H3_def Healthy_intro SemiR_TrueP_precond assms)
qed

theorem DesignD_precondition_H3 [closure]:
  assumes 
    "OKAY \<sharp> p" "OKAY \<sharp> Q"
    "p \<in> WF_CONDITION" "Q \<in> WF_RELATION"
  shows "(p \<turnstile> Q) is H3"
proof -
  have "`(p \<turnstile> Q) ; II\<^sub>D` = `(p \<turnstile> Q) ; (true \<turnstile> II\<^bsub>REL_VAR - OKAY\<^esub>)`"
    by (simp add:SkipDA_def)

  also from assms have "... = `p \<turnstile> (Q ; II\<^bsub>REL_VAR - OKAY\<^esub>)`"
    by (simp add:DesignD_composition_cond closure unrest)

  also have "... = `p \<turnstile> Q`"
    by (simp add:SemiR_SkipRA_right closure assms unrest var_dist)
    
  finally show ?thesis
    by (simp add:H3_def is_healthy_def)
qed

theorem H1_H3_commute: "H1 (H3 P) = H3 (H1 P)"
  apply (simp add:H1_def H3_def ImpliesP_def SemiR_OrP_distr TopD_def[THEN sym])
  apply (metis H3_WF_CONDITION H3_def Healthy_simp TopD_cond_closure)
done

theorem SkipD_absorbs_J_1 [simp]: 
  "`II\<^sub>D ; J` = `II\<^sub>D`"
  by (utp_xrel_auto_tac)

theorem H3_absorbs_H2_1:
  "H2 (H3 P) = H3 P"
  by (simp add:H2_def H3_def SemiR_assoc[THEN sym])

theorem SkipD_absorbs_J_2 [simp]:
  "`J ; II\<^sub>D` = `II\<^sub>D`"
  by (utp_xrel_auto_tac)

theorem H3_absorbs_H2_2:
  "H3 (H2 P) = H3 P"
  by (simp add:H2_def H3_def SemiR_assoc[THEN sym])

theorem H3_implies_H2:
  "P is H3 \<Longrightarrow> P is H2"
  by (metis H3_absorbs_H2_1 is_healthy_def)

text {* H2-H3 commutivity is vacuously true *}

theorem H2_H3_commute: "H2 (H3 P) = H3 (H2 P)"
  by (metis H3_absorbs_H2_1 H3_absorbs_H2_2)

subsubsection {* H4: Feasibility *}

definition "H4(P) = `(P ; true) \<Rightarrow> P`"

definition "isH4(P) \<equiv> `P ; true` = `true`"

declare H4_def [eval,evalr,evalrx]
declare isH4_def [eval,evalr,evalrx]

theorem H4_idempotent: "H4 (H4 P) = H4 P"
  by (utp_rel_tac)

theorem H4_equiv: "P \<in> WF_RELATION \<Longrightarrow> P is H4 \<longleftrightarrow> isH4(P)"
  by (utp_xrel_auto_tac)

text {* This lemma shows intuitively what H4 means: there exists an output
        for every input. *}

lemma H4_soundness:
  assumes "P \<in> WF_RELATION"
  shows "P is H4 \<longleftrightarrow> (\<exists>\<^sub>p DASHED. P)" 
proof -
  have "P is H4 \<longleftrightarrow> (`P ; true` = `true`)"
    by (simp add:H4_equiv assms isH4_def)

  moreover have "`P ; true` = (\<exists>\<^sub>p DASHED. P)"
    by (metis TrueP_right_ExistsP)

  finally show ?thesis by (utp_pred_tac)
qed

theorem SkipR_is_H4 [closure]:
  "II is H4"
  by (simp add:is_healthy_def H4_def)
 
theorem SkipR_not_H1: 
  "\<not> (II is H1)"
proof -
  have "`ok \<Rightarrow> II` = (`II` :: 'a WF_PREDICATE) \<longleftrightarrow> (`true` :: 'a WF_PREDICATE) = `II[false/okay]`"
    by (unfold BoolType_pvaux_cases[of "okay" "`ok \<Rightarrow> II`" "II", simplified], utp_subst_tac)

  moreover have "`II[false/okay]` = `($okay\<acute> = $okay \<and> II\<^bsub>REL_VAR - OKAY\<^esub>)[false/okay]`"
    by (simp add: SkipR_as_SkipRA SkipRA_unfold[of "okay\<down>"] typing defined closure erasure)
    
  also have "... = `$okay\<acute> = false \<and> II\<^bsub>REL_VAR - OKAY\<^esub>`"
    by (utp_subst_tac)

  also have "... \<noteq> true"
    apply (auto)
    apply (unfold BoolType_pvaux_cases[of "okay\<acute>" "`$okay\<acute> = false \<and> II\<^bsub>REL_VAR - OKAY\<^esub>`" "TrueP", simplified])
    apply (utp_subst_tac)
    apply (utp_pred_tac)
  done

  ultimately show ?thesis
    by (simp add:is_healthy_def H1_def, metis)
qed

theorem SkipD_is_H4 [closure]:
  "II\<^sub>D is H4"
  by (utp_xrel_auto_tac)

text {* No condition other than true is feasible *}

theorem H4_condition:
  "p \<in> WF_CONDITION \<Longrightarrow> H4(p) = true"
  by (simp add:H4_def SemiR_TrueP_precond)

theorem H4_TopD:
  "H4(\<top>\<^sub>D) = true"
  by (simp add:H4_def SemiR_TrueP_precond closure)

theorem TopD_not_H4: 
  "\<not> \<top>\<^sub>D is H4"
  by (simp add:is_healthy_def H4_TopD)

theorem H1_H4_commute:
  "P \<in> WF_RELATION \<Longrightarrow> H1(H4(P)) = H4(H1(P))"
  by (utp_xrel_auto_tac)

theorem H2_H4_commute:
  "P \<in> WF_RELATION \<Longrightarrow> H2(H4(P)) = H4(H2(P))"
  by (utp_xrel_auto_tac)

theorem H3_H4_commute:
  assumes "P \<in> WF_RELATION"
  shows "H3(H4(P)) = H4(H3(P))"
proof -
  have "H4(H3(P)) = `((P ; II\<^sub>D) ; true \<Rightarrow> P ; II\<^sub>D)`" 
    by (simp add:H3_def H4_def)

  also have "... = `(P ; true) \<Rightarrow> P ; II\<^sub>D`"
    by (metis H1_left_unit H1_true SemiR_assoc TrueP_rel_closure)

  also have "... = `\<not> (P ; true) \<or> P ; II\<^sub>D`"
    by (metis ImpliesP_def)
    
  also have "... = `\<not> (P ; true) ; true \<or> P ; II\<^sub>D`"
    by (metis SemiR_TrueP_compl assms)

  also have "... = `\<not> (P ; true) ; (true ; II\<^sub>D) \<or> P ; II\<^sub>D`"
    by (metis H1_left_zero SkipD_is_H1 SkipD_rel_closure)

  also have "... = `\<not> (P ; true) ; II\<^sub>D \<or> P ; II\<^sub>D`"
    by (metis SemiR_TrueP_compl SemiR_assoc assms)

  also have "... = `(\<not> (P ; true) \<or> P) ; II\<^sub>D`"
    by (metis SemiR_OrP_distr)

  finally show ?thesis
    by (metis H3_def H4_def ImpliesP_def)
qed
    
theorem H4_top: "true \<turnstile> true is H4"
  by (utp_xrel_auto_tac)

(*
subsection {* The theory of Designs *}

lift_definition DESIGNS :: "'a WF_THEORY" 
is "({vs. vs \<subseteq> REL_VAR \<and> OKAY \<subseteq> vs}, {H1,H2})"
  by (simp add:WF_THEORY_def IDEMPOTENT_OVER_def H1_idempotent H2_idempotent)

abbreviation "WF_DESIGN \<equiv> THEORY_PRED DESIGNS"

lemma DESIGNS_WF_RELATION [closure]:
  "p \<in> WF_DESIGN \<Longrightarrow> p \<in> WF_RELATION"
  apply (auto simp add:THEORY_PRED_def DESIGNS.rep_eq utp_alphabets_def WF_RELATION_def)
  apply (rule UNREST_subset, auto)
done

lemma DESIGNS_H1 [closure]:
  "p \<in> THEORY_PRED DESIGNS \<Longrightarrow> p is H1"
  by (auto simp add:THEORY_PRED_def DESIGNS.rep_eq healthconds_def WF_RELATION_def)

lemma DESIGNS_H2 [closure]:
  "p \<in> THEORY_PRED DESIGNS \<Longrightarrow> p is H2"
  by (auto simp add:THEORY_PRED_def DESIGNS.rep_eq healthconds_def WF_RELATION_def)

lemma DESIGNS_intro:
  "\<lbrakk> P is H1; P is H2; P \<in> WF_RELATION
   ; (VAR - vs) \<sharp> P; OKAY \<subseteq> vs; vs \<subseteq> REL_VAR \<rbrakk> \<Longrightarrow> P \<in> WF_DESIGN"
  apply (simp add:THEORY_PRED_def utp_alphabets_def healthconds_def DESIGNS.rep_eq)
  apply (rule_tac x="vs" in exI, auto)
done

lemma [simp]: "(VAR - UNDASHED) \<inter> (VAR - DASHED) = NON_REL_VAR"
  by auto

lemma DESIGNS_intro_witness:
  "\<lbrakk> P = R1 \<turnstile> R2; R1 \<in> WF_RELATION; R2 \<in> WF_RELATION; OKAY \<sharp> R1; OKAY \<sharp> R2 \<rbrakk> 
   \<Longrightarrow> P \<in> WF_DESIGN"
  apply (rule_tac vs="REL_VAR" in DESIGNS_intro)
  apply (auto simp add:unrest closure)
done

lemma TrueP_design_closure [closure]:
  "TrueP \<in> WF_DESIGN"
  apply (rule_tac DESIGNS_intro_witness[of _ "FalseP" "TrueP"])
  apply (utp_pred_tac)
  apply (simp_all add:closure unrest)
done

lemma TopD_design_closure [closure]:
  "\<top>\<^sub>D \<in> WF_DESIGN"
  apply (rule_tac DESIGNS_intro_witness[of _ "TrueP" "FalseP"])
  apply (utp_pred_tac, simp_all add:closure unrest)
done

lemma ChoiceR_design_closure [closure]:
  "\<lbrakk> P \<in> WF_DESIGN; Q \<in> WF_DESIGN \<rbrakk> \<Longrightarrow> P \<sqinter> Q \<in> WF_DESIGN"
  apply (rule_tac vs="REL_VAR" in DESIGNS_intro)
  apply (metis DESIGNS_H1 H1_OrP is_healthy_def sup_WF_PREDICATE_def)
  apply (metis DESIGNS_H2 H2_def Healthy_intro Healthy_simp SemiR_OrP_distr sup_WF_PREDICATE_def)
  apply (simp_all add:closure unrest sup_WF_PREDICATE_def)
done
  
lemma SemiR_design_closure [closure]:
  "\<lbrakk> P \<in> WF_DESIGN; Q \<in> WF_DESIGN \<rbrakk> \<Longrightarrow> P ; Q \<in> WF_DESIGN"
  apply (rule_tac vs="REL_VAR" in DESIGNS_intro)
  apply (smt DESIGNS_H1 DESIGNS_WF_RELATION H1_algebraic SemiR_assoc SemiR_closure)
  apply (metis DESIGNS_H2 H2_def SemiR_assoc is_healthy_def)
  apply (simp_all add:closure unrest)
done

subsection {* The theory of Normal Designs *}

lift_definition NORMAL_DESIGNS :: "'a WF_THEORY" 
is "({vs. vs \<subseteq> REL_VAR \<and> OKAY \<subseteq> vs}, {H1,H3})"
  by (simp add:WF_THEORY_def IDEMPOTENT_OVER_def H1_idempotent H3_idempotent)
   
abbreviation "WF_NORM_DESIGN \<equiv> THEORY_PRED NORMAL_DESIGNS"

lemma WF_NORM_DESIGN_WF_DESIGN:
  "p \<in> WF_NORM_DESIGN \<Longrightarrow> p \<in> WF_DESIGN"
  by (simp add:THEORY_PRED_def DESIGNS.rep_eq NORMAL_DESIGNS.rep_eq 
      utp_alphabets_def healthconds_def H3_implies_H2)

subsection {* The theory of Feasible Designs *}

lift_definition FEASIBLE_DESIGNS :: "'a WF_THEORY" 
is "({vs. vs \<subseteq> REL_VAR \<and> OKAY \<subseteq> vs}, {H1,H3,H4})"
  by (simp add:WF_THEORY_def IDEMPOTENT_OVER_def H1_idempotent H2_idempotent H3_idempotent H4_idempotent)
*)

end