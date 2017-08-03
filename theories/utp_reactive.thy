section {* Reactive processes *}

theory utp_reactive
imports
  "../utp/utp_concurrency"
  utp_designs
begin
  
alphabet 't::trace rp_vars = des_vars +
  wait :: bool
  tr   :: "'t"

declare rp_vars.splits [alpha_splits]

text {*
  The two locale interpretations below are a technicality to improve automatic
  proof support via the predicate and relational tactics. This is to enable the
  (re-)interpretation of state spaces to remove any occurrences of lens types
  after the proof tactics @{method pred_simp} and @{method rel_simp}, or any
  of their derivatives have been applied. Eventually, it would be desirable to
  automate both interpretations as part of a custom outer command for defining
  alphabets.
*}

interpretation rp_vars:
  lens_interp "\<lambda>(ok, r). (ok, wait\<^sub>v r, tr\<^sub>v r, more r)"
apply (unfold_locales)
apply (rule injI)
apply (clarsimp)
done

interpretation rp_vars_rel: lens_interp "\<lambda>(ok, ok', r, r').
  (ok, ok', wait\<^sub>v r, wait\<^sub>v r', tr\<^sub>v r, tr\<^sub>v r', more r, more r')"
apply (unfold_locales)
apply (rule injI)
apply (clarsimp)
done

type_synonym ('t, '\<alpha>) rp = "('t, '\<alpha>) rp_vars_scheme des"

type_synonym ('t,'\<alpha>,'\<beta>) rel_rp  = "(('t,'\<alpha>) rp, ('t,'\<beta>) rp) rel"
type_synonym ('t,'\<alpha>) hrel_rp  = "('t,'\<alpha>) rp hrel"

translations
  (type) "('t,'\<alpha>) rp" <= (type) "('t, '\<alpha>) rp_vars_scheme des"
  (type) "('t,'\<alpha>) rp" <= (type) "('t, '\<alpha>) rp_vars_ext des"
  (type) "('t,'\<alpha>,'\<beta>) rel_rp" <= (type) "(('t,'\<alpha>) rp, ('\<gamma>,'\<beta>) rp) rel"
  (type) "('t, '\<alpha>) hrel_rp"  <= (type) "('t, '\<alpha>) rp hrel"
  
notation rp_vars_child_lens\<^sub>a ("\<Sigma>\<^sub>r")
notation rp_vars_child_lens ("\<Sigma>\<^sub>R")

lemma rea_var_ords [usubst]:
  "$tr \<prec>\<^sub>v $tr\<acute>" "$wait \<prec>\<^sub>v $wait\<acute>"
  "$ok \<prec>\<^sub>v $tr" "$ok\<acute> \<prec>\<^sub>v $tr\<acute>" "$ok \<prec>\<^sub>v $tr\<acute>" "$ok\<acute> \<prec>\<^sub>v $tr"
  "$ok \<prec>\<^sub>v $wait" "$ok\<acute> \<prec>\<^sub>v $wait\<acute>" "$ok \<prec>\<^sub>v $wait\<acute>" "$ok\<acute> \<prec>\<^sub>v $wait"
  "$tr \<prec>\<^sub>v $wait" "$tr\<acute> \<prec>\<^sub>v $wait\<acute>" "$tr \<prec>\<^sub>v $wait\<acute>" "$tr\<acute> \<prec>\<^sub>v $wait"
  by (simp_all add: var_name_ord_def)

abbreviation wait_f::"('t::trace, '\<alpha>, '\<beta>) rel_rp \<Rightarrow> ('t, '\<alpha>, '\<beta>) rel_rp"
where "wait_f R \<equiv> R\<lbrakk>false/$wait\<rbrakk>"

abbreviation wait_t::"('t::trace, '\<alpha>, '\<beta>) rel_rp \<Rightarrow> ('t, '\<alpha>, '\<beta>) rel_rp"
where "wait_t R \<equiv> R\<lbrakk>true/$wait\<rbrakk>"
  
syntax
  "_wait_f"  :: "logic \<Rightarrow> logic" ("_\<^sub>f" [1000] 1000)
  "_wait_t"  :: "logic \<Rightarrow> logic" ("_\<^sub>t" [1000] 1000)

translations
  "P \<^sub>f" \<rightleftharpoons> "CONST usubst (CONST subst_upd CONST id (CONST ivar CONST wait) false) P"
  "P \<^sub>t" \<rightleftharpoons> "CONST usubst (CONST subst_upd CONST id (CONST ivar CONST wait) true) P"

abbreviation lift_rea :: "_ \<Rightarrow> _" ("\<lceil>_\<rceil>\<^sub>R") where
"\<lceil>P\<rceil>\<^sub>R \<equiv> P \<oplus>\<^sub>p (\<Sigma>\<^sub>R \<times>\<^sub>L \<Sigma>\<^sub>R)"

abbreviation drop_rea :: "('t::trace, '\<alpha>, '\<beta>) rel_rp \<Rightarrow> ('\<alpha>, '\<beta>) rel" ("\<lfloor>_\<rfloor>\<^sub>R") where
"\<lfloor>P\<rfloor>\<^sub>R \<equiv> P \<restriction>\<^sub>p (\<Sigma>\<^sub>R \<times>\<^sub>L \<Sigma>\<^sub>R)"

abbreviation rea_pre_lift :: "_ \<Rightarrow> _" ("\<lceil>_\<rceil>\<^sub>R\<^sub><") where "\<lceil>n\<rceil>\<^sub>R\<^sub>< \<equiv> \<lceil>\<lceil>n\<rceil>\<^sub><\<rceil>\<^sub>R"

abbreviation trace ::
  "('t::trace, ('t, '\<alpha>) rp) hexpr" ("tt") where
"tt \<equiv> $tr\<acute> - $tr"

translations
  "tt" <= "CONST minus (CONST utp_expr.var (CONST ovar CONST tr)) (CONST utp_expr.var (CONST ivar CONST tr))"

subsection {* Reactive lemmas *}

lemma unrest_ok_lift_rea [unrest]:
  "$ok \<sharp> \<lceil>P\<rceil>\<^sub>R" "$ok\<acute> \<sharp> \<lceil>P\<rceil>\<^sub>R"
  by (pred_auto)+

lemma unrest_wait_lift_rea [unrest]:
  "$wait \<sharp> \<lceil>P\<rceil>\<^sub>R" "$wait\<acute> \<sharp> \<lceil>P\<rceil>\<^sub>R"
  by (pred_auto)+

lemma unrest_tr_lift_rea [unrest]:
  "$tr \<sharp> \<lceil>P\<rceil>\<^sub>R" "$tr\<acute> \<sharp> \<lceil>P\<rceil>\<^sub>R"
  by (pred_auto)+

lemma wait_tr_bij_lemma: "bij_lens (wait\<^sub>a +\<^sub>L tr\<^sub>a +\<^sub>L \<Sigma>\<^sub>r)"
  by (unfold_locales, auto simp add: lens_defs)

lemma des_lens_equiv_wait_tr_rest: "\<Sigma>\<^sub>D \<approx>\<^sub>L wait +\<^sub>L tr +\<^sub>L \<Sigma>\<^sub>R"
proof -
  have "wait +\<^sub>L tr +\<^sub>L \<Sigma>\<^sub>R = (wait\<^sub>a +\<^sub>L tr\<^sub>a +\<^sub>L \<Sigma>\<^sub>r) ;\<^sub>L \<Sigma>\<^sub>D"
    by (simp add: plus_lens_distr wait_def tr_def rp_vars_child_lens_def)
  also have "... \<approx>\<^sub>L 1\<^sub>L ;\<^sub>L \<Sigma>\<^sub>D"
    using lens_equiv_via_bij wait_tr_bij_lemma by auto
  also have "... = \<Sigma>\<^sub>D"
    by (simp)
  finally show ?thesis
    using lens_equiv_sym by blast
qed

lemma rea_lens_bij: "bij_lens (ok +\<^sub>L wait +\<^sub>L tr +\<^sub>L \<Sigma>\<^sub>R)"
proof -
  have "ok +\<^sub>L wait +\<^sub>L tr +\<^sub>L \<Sigma>\<^sub>R \<approx>\<^sub>L ok +\<^sub>L \<Sigma>\<^sub>D"
    using des_lens_equiv_wait_tr_rest des_vars_indeps lens_equiv_sym lens_plus_eq_right by blast
  also have "... \<approx>\<^sub>L 1\<^sub>L"
    using bij_lens_equiv_id[of "ok +\<^sub>L \<Sigma>\<^sub>D"] by (simp add: ok_des_bij_lens)
  finally show ?thesis
    by (simp add: bij_lens_equiv_id)
qed

lemma seqr_wait_true [usubst]: "(P ;; Q) \<^sub>t = (P \<^sub>t ;; Q)"
  by (rel_auto)

lemma seqr_wait_false [usubst]: "(P ;; Q) \<^sub>f = (P \<^sub>f ;; Q)"
  by (rel_auto)

subsection {* R1: Events cannot be undone *}

definition R1_def [upred_defs]: "R1 (P) =  (P \<and> ($tr \<le>\<^sub>u $tr\<acute>))"

lemma R1_idem: "R1(R1(P)) = R1(P)"
  by pred_auto

lemma R1_Idempotent [closure]: "Idempotent R1"
  by (simp add: Idempotent_def R1_idem)

lemma R1_mono: "P \<sqsubseteq> Q \<Longrightarrow> R1(P) \<sqsubseteq> R1(Q)"
  by pred_auto

lemma R1_Monotonic: "Monotonic R1"
  by (simp add: mono_def R1_mono)

lemma R1_Continuous: "Continuous R1"
  by (auto simp add: Continuous_def, rel_auto)

lemma R1_unrest [unrest]: "\<lbrakk> x \<bowtie> in_var tr; x \<bowtie> out_var tr; x \<sharp> P \<rbrakk> \<Longrightarrow> x \<sharp> R1(P)"
  by (metis R1_def in_var_uvar lens_indep_sym out_var_uvar tr_vwb_lens unrest_bop unrest_conj unrest_var)

lemma R1_false: "R1(false) = false"
  by pred_auto

lemma R1_conj: "R1(P \<and> Q) = (R1(P) \<and> R1(Q))"
  by pred_auto

lemma conj_R1_closed_1 [closure]: "P is R1 \<Longrightarrow> (P \<and> Q) is R1"
  by (rel_blast)

lemma conj_R1_closed_2 [closure]: "Q is R1 \<Longrightarrow> (P \<and> Q) is R1"
  by (rel_blast)

lemma R1_disj: "R1(P \<or> Q) = (R1(P) \<or> R1(Q))"
  by pred_auto

lemma R1_impl: "R1(P \<Rightarrow> Q) = ((\<not> R1(\<not> P)) \<Rightarrow> R1(Q))"
  by (rel_auto)

lemma R1_inf: "R1(P \<sqinter> Q) = (R1(P) \<sqinter> R1(Q))"
  by pred_auto

lemma R1_USUP:
  "R1(\<Sqinter> i \<in> A \<bullet> P(i)) = (\<Sqinter> i \<in> A \<bullet> R1(P(i)))"
  by (rel_auto)

lemma R1_UINF:
  assumes "A \<noteq> {}"
  shows "R1(\<Squnion> i \<in> A \<bullet> P(i)) = (\<Squnion> i \<in> A \<bullet> R1(P(i)))"
  using assms by (rel_auto)

lemma R1_extend_conj: "R1(P \<and> Q) = (R1(P) \<and> Q)"
  by pred_auto

lemma R1_extend_conj': "R1(P \<and> Q) = (P \<and> R1(Q))"
  by pred_auto

lemma R1_cond: "R1(P \<triangleleft> b \<triangleright> Q) = (R1(P) \<triangleleft> b \<triangleright> R1(Q))"
  by (rel_auto)

lemma R1_cond': "R1(P \<triangleleft> b \<triangleright> Q) = (R1(P) \<triangleleft> R1(b) \<triangleright> R1(Q))"
  by (rel_auto)

lemma R1_negate_R1: "R1(\<not> R1(P)) = R1(\<not> P)"
  by pred_auto

lemma R1_wait_true [usubst]: "(R1 P)\<^sub>t = R1(P)\<^sub>t"
  by pred_auto

lemma R1_wait_false [usubst]: "(R1 P) \<^sub>f = R1(P) \<^sub>f"
  by pred_auto

lemma R1_wait'_true [usubst]: "(R1 P)\<lbrakk>true/$wait\<acute>\<rbrakk> = R1(P\<lbrakk>true/$wait\<acute>\<rbrakk>)"
  by (rel_auto)

lemma R1_wait'_false [usubst]: "(R1 P)\<lbrakk>false/$wait\<acute>\<rbrakk> = R1(P\<lbrakk>false/$wait\<acute>\<rbrakk>)"
  by (rel_auto)

lemma R1_wait_false_closed [closure]: "P is R1 \<Longrightarrow> P\<lbrakk>false/$wait\<rbrakk> is R1"
  by (rel_auto)

lemma R1_wait'_false_closed [closure]: "P is R1 \<Longrightarrow> P\<lbrakk>false/$wait\<acute>\<rbrakk> is R1"
  by (rel_auto)

lemma R1_skip: "R1(II) = II"
  by (rel_auto)

lemma skip_is_R1 [closure]: "II is R1"
  by (rel_auto)

lemma R1_by_refinement:
  "P is R1 \<longleftrightarrow> (($tr \<le>\<^sub>u $tr\<acute>) \<sqsubseteq> P)"
  by (rel_blast)

lemma R1_trace_extension [closure]:
  "$tr\<acute> \<ge>\<^sub>u $tr ^\<^sub>u e is R1"
  by (rel_auto)
    
lemma tr_le_trans:
  "(($tr \<le>\<^sub>u $tr\<acute>) ;; ($tr \<le>\<^sub>u $tr\<acute>)) = ($tr \<le>\<^sub>u $tr\<acute>)"
  by (rel_auto)
    
lemma R1_seqr:
  "R1(R1(P) ;; R1(Q)) = (R1(P) ;; R1(Q))"
  by (rel_auto)

lemma R1_seqr_closure [closure]:
  assumes "P is R1" "Q is R1"
  shows "(P ;; Q) is R1"
  using assms unfolding R1_by_refinement
  by (metis seqr_mono tr_le_trans)

lemma R1_true_comp [simp]: "(R1(true) ;; R1(true)) = R1(true)"
  by (rel_auto)

lemma R1_ok'_true: "(R1(P))\<^sup>t = R1(P\<^sup>t)"
  by pred_auto

lemma R1_ok'_false: "(R1(P))\<^sup>f = R1(P\<^sup>f)"
  by pred_auto

lemma R1_ok_true: "(R1(P))\<lbrakk>true/$ok\<rbrakk> = R1(P\<lbrakk>true/$ok\<rbrakk>)"
  by pred_auto

lemma R1_ok_false: "(R1(P))\<lbrakk>false/$ok\<rbrakk> = R1(P\<lbrakk>false/$ok\<rbrakk>)"
  by pred_auto

lemma seqr_R1_true_right: "((P ;; R1(true)) \<or> P) = (P ;; ($tr \<le>\<^sub>u $tr\<acute>))"
  by (rel_auto)

lemma conj_R1_true_right: "(P;;R1(true) \<and> Q;;R1(true)) ;; R1(true) = (P;;R1(true) \<and> Q;;R1(true))"
  apply (rel_auto) using dual_order.trans by blast+

lemma R1_extend_conj_unrest: "\<lbrakk> $tr \<sharp> Q; $tr\<acute> \<sharp> Q \<rbrakk> \<Longrightarrow> R1(P \<and> Q) = (R1(P) \<and> Q)"
  by pred_auto

lemma R1_extend_conj_unrest': "\<lbrakk> $tr \<sharp> P; $tr\<acute> \<sharp> P \<rbrakk> \<Longrightarrow> R1(P \<and> Q) = (P \<and> R1(Q))"
  by pred_auto

lemma R1_tr'_eq_tr: "R1($tr\<acute> =\<^sub>u $tr) = ($tr\<acute> =\<^sub>u $tr)"
  by (rel_auto)

lemma R1_tr_less_tr': "R1($tr <\<^sub>u $tr\<acute>) = ($tr <\<^sub>u $tr\<acute>)"
  by (rel_auto)

lemma tr_strict_prefix_R1_closed [closure]: "$tr <\<^sub>u $tr\<acute> is R1"
  by (rel_auto)

lemma R1_H2_commute: "R1(H2(P)) = H2(R1(P))"
  by (simp add: H2_split R1_def usubst, rel_auto)

subsection {* R2 *}

definition R2a_def [upred_defs]: "R2a (P) = (\<Sqinter> s \<bullet> P\<lbrakk>\<guillemotleft>s\<guillemotright>,\<guillemotleft>s\<guillemotright>+($tr\<acute>-$tr)/$tr,$tr\<acute>\<rbrakk>)"
definition R2a' :: "('t::trace, '\<alpha>, '\<beta>) rel_rp \<Rightarrow> ('t,'\<alpha>,'\<beta>) rel_rp" where
R2a'_def [upred_defs]: "R2a' (P :: _ upred) = (R2a(P) \<triangleleft> R1(true) \<triangleright> P)"
definition R2s_def [upred_defs]: "R2s (P) = (P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>($tr\<acute>-$tr)/$tr\<acute>\<rbrakk>)"
definition R2_def  [upred_defs]: "R2(P) = R1(R2s(P))"
definition R2c_def [upred_defs]: "R2c(P) = (R2s(P) \<triangleleft> R1(true) \<triangleright> P)"

lemma R2a_R2s: "R2a(R2s(P)) = R2s(P)"
  by (rel_auto)

lemma R2s_R2a: "R2s(R2a(P)) = R2a(P)"
  by (rel_auto)

lemma R2a_equiv_R2s: "P is R2a \<longleftrightarrow> P is R2s"
  by (metis Healthy_def' R2a_R2s R2s_R2a)

lemma R2a_idem: "R2a(R2a(P)) = R2a(P)"
  by (rel_auto)

lemma R2a'_idem: "R2a'(R2a'(P)) = R2a'(P)"
  by (rel_auto)

lemma R2a_mono: "P \<sqsubseteq> Q \<Longrightarrow> R2a(P) \<sqsubseteq> R2a(Q)"
  by (rel_simp, rule Sup_mono, blast)

lemma R2a'_mono: "P \<sqsubseteq> Q \<Longrightarrow> R2a'(P) \<sqsubseteq> R2a'(Q)"
  by (rel_blast)

lemma R2a'_weakening: "R2a'(P) \<sqsubseteq> P"
  apply (rel_simp)
  apply (rename_tac ok wait tr more ok' wait' tr' more')
  apply (rule_tac x="tr" in exI)
  apply (simp add: diff_add_cancel_left')
done

lemma R2s_idem: "R2s(R2s(P)) = R2s(P)"
  by (pred_auto)

lemma R2s_unrest [unrest]: "\<lbrakk> vwb_lens x; x \<bowtie> in_var tr; x \<bowtie> out_var tr; x \<sharp> P \<rbrakk> \<Longrightarrow> x \<sharp> R2s(P)"
  by (simp add: R2s_def unrest usubst lens_indep_sym)

lemma R2_idem: "R2(R2(P)) = R2(P)"
  by (pred_auto)

lemma R2_mono: "P \<sqsubseteq> Q \<Longrightarrow> R2(P) \<sqsubseteq> R2(Q)"
  by (pred_auto)

lemma R2c_Continuous: "Continuous R2c"
  by (rel_simp)

lemma R2c_lit: "R2c(\<guillemotleft>x\<guillemotright>) = \<guillemotleft>x\<guillemotright>"
  by (rel_auto)

lemma tr_strict_prefix_R2c_closed [closure]: "$tr <\<^sub>u $tr\<acute> is R2c"
  by (rel_auto)

lemma R2s_conj: "R2s(P \<and> Q) = (R2s(P) \<and> R2s(Q))"
  by (pred_auto)

lemma R2_conj: "R2(P \<and> Q) = (R2(P) \<and> R2(Q))"
  by (pred_auto)

lemma R2s_disj: "R2s(P \<or> Q) = (R2s(P) \<or> R2s(Q))"
  by pred_auto

lemma R2s_USUP:
  "R2s(\<Sqinter> i \<in> A \<bullet> P(i)) = (\<Sqinter> i \<in> A \<bullet> R2s(P(i)))"
  by (simp add: R2s_def usubst)

lemma R2c_USUP:
  "R2c(\<Sqinter> i \<in> A \<bullet> P(i)) = (\<Sqinter> i \<in> A \<bullet> R2c(P(i)))"
  by (rel_auto)

lemma R2s_UINF:
  "R2s(\<Squnion> i \<in> A \<bullet> P(i)) = (\<Squnion> i \<in> A \<bullet> R2s(P(i)))"
  by (simp add: R2s_def usubst)

lemma R2c_UINF:
  "R2c(\<Squnion> i \<in> A \<bullet> P(i)) = (\<Squnion> i \<in> A \<bullet> R2c(P(i)))"
  by (rel_auto)

lemma R2_disj: "R2(P \<or> Q) = (R2(P) \<or> R2(Q))"
  by (pred_auto)

lemma R2s_not: "R2s(\<not> P) = (\<not> R2s(P))"
  by pred_auto

lemma R2s_condr: "R2s(P \<triangleleft> b \<triangleright> Q) = (R2s(P) \<triangleleft> R2s(b) \<triangleright> R2s(Q))"
  by (rel_auto)

lemma R2_condr: "R2(P \<triangleleft> b \<triangleright> Q) = (R2(P) \<triangleleft> R2(b) \<triangleright> R2(Q))"
  by (rel_auto)

lemma R2_condr': "R2(P \<triangleleft> b \<triangleright> Q) = (R2(P) \<triangleleft> R2s(b) \<triangleright> R2(Q))"
  by (rel_auto)

lemma R2s_ok: "R2s($ok) = $ok"
  by (rel_auto)

lemma R2s_ok': "R2s($ok\<acute>) = $ok\<acute>"
  by (rel_auto)

lemma R2s_wait: "R2s($wait) = $wait"
  by (rel_auto)

lemma R2s_wait': "R2s($wait\<acute>) = $wait\<acute>"
  by (rel_auto)

lemma R2s_true: "R2s(true) = true"
  by pred_auto

lemma R2s_false: "R2s(false) = false"
  by pred_auto

lemma true_is_R2s:
  "true is R2s"
  by (simp add: Healthy_def R2s_true)

lemma R2s_lift_rea: "R2s(\<lceil>P\<rceil>\<^sub>R) = \<lceil>P\<rceil>\<^sub>R"
  by (simp add: R2s_def usubst unrest)

lemma R2c_lift_rea: "R2c(\<lceil>P\<rceil>\<^sub>R) = \<lceil>P\<rceil>\<^sub>R"
  by (simp add: R2c_def R2s_lift_rea cond_idem usubst unrest)

lemma R2c_true: "R2c(true) = true"
  by (rel_auto)

lemma R2c_false: "R2c(false) = false"
  by (rel_auto)

lemma R2c_and: "R2c(P \<and> Q) = (R2c(P) \<and> R2c(Q))"
  by (rel_auto)

lemma conj_R2c_closed [closure]: "\<lbrakk> P is R2c; Q is R2c \<rbrakk> \<Longrightarrow> (P \<and> Q) is R2c"
  by (simp add: Healthy_def R2c_and)

lemma R2c_disj: "R2c(P \<or> Q) = (R2c(P) \<or> R2c(Q))"
  by (rel_auto)

lemma R2c_inf: "R2c(P \<sqinter> Q) = (R2c(P) \<sqinter> R2c(Q))"
  by (rel_auto)

lemma R2c_not: "R2c(\<not> P) = (\<not> R2c(P))"
  by (rel_auto)

lemma R2c_ok: "R2c($ok) = ($ok)"
  by (rel_auto)

lemma R2c_ok': "R2c($ok\<acute>) = ($ok\<acute>)"
  by (rel_auto)

lemma R2c_wait: "R2c($wait) = $wait"
  by (rel_auto)

lemma R2c_wait': "R2c($wait\<acute>) = $wait\<acute>"
  by (rel_auto)

lemma R2c_wait'_true [usubst]: "(R2c P)\<lbrakk>true/$wait\<acute>\<rbrakk> = R2c(P\<lbrakk>true/$wait\<acute>\<rbrakk>)"
  by (rel_auto)

lemma R2c_wait'_false [usubst]: "(R2c P)\<lbrakk>false/$wait\<acute>\<rbrakk> = R2c(P\<lbrakk>false/$wait\<acute>\<rbrakk>)"
  by (rel_auto)

lemma R2c_tr'_minus_tr: "R2c($tr\<acute> =\<^sub>u $tr) = ($tr\<acute> =\<^sub>u $tr)"
  apply (rel_auto) using minus_zero_eq by blast

lemma R2c_tr'_ge_tr: "R2c($tr\<acute> \<ge>\<^sub>u $tr) = ($tr\<acute> \<ge>\<^sub>u $tr)"
  by (rel_auto)

lemma R2c_tr_less_tr': "R2c($tr <\<^sub>u $tr\<acute>) = ($tr <\<^sub>u $tr\<acute>)"
  by (rel_auto)

lemma R2c_condr: "R2c(P \<triangleleft> b \<triangleright> Q) = (R2c(P) \<triangleleft> R2c(b) \<triangleright> R2c(Q))"
  by (rel_auto)

lemma R2c_shAll: "R2c (\<^bold>\<forall> x \<bullet> P x) = (\<^bold>\<forall> x \<bullet> R2c(P x))"
  by (rel_auto)

lemma R2c_impl: "R2c(P \<Rightarrow> Q) = (R2c(P) \<Rightarrow> R2c(Q))"
  by (metis (no_types, lifting) R2c_and R2c_not double_negation impl_alt_def not_conj_deMorgans)

lemma R2c_skip_r: "R2c(II) = II"
proof -
  have "R2c(II) = R2c($tr\<acute> =\<^sub>u $tr \<and> II\<restriction>\<^sub>\<alpha>tr)"
    by (subst skip_r_unfold[of tr], simp_all)
  also have "... = (R2c($tr\<acute> =\<^sub>u $tr) \<and> II\<restriction>\<^sub>\<alpha>tr)"
    by (simp add: R2c_and, simp add: R2c_def R2s_def usubst unrest cond_idem)
  also have "... = ($tr\<acute> =\<^sub>u $tr \<and> II\<restriction>\<^sub>\<alpha>tr)"
    by (simp add: R2c_tr'_minus_tr)
  finally show ?thesis
    by (subst skip_r_unfold[of tr], simp_all)
qed

lemma R1_R2c_commute: "R1(R2c(P)) = R2c(R1(P))"
  by (rel_auto)

lemma R1_R2c_is_R2: "R1(R2c(P)) = R2(P)"
  by (rel_auto)

lemma R1_R2s_R2c: "R1(R2s(P)) = R1(R2c(P))"
  by (rel_auto)

lemma R1_R2s_tr_wait:
  "R1 (R2s ($tr\<acute> =\<^sub>u $tr \<and> $wait\<acute>)) = ($tr\<acute> =\<^sub>u $tr \<and> $wait\<acute>)"
  apply rel_auto using minus_zero_eq by blast

lemma R1_R2s_tr'_eq_tr:
  "R1 (R2s ($tr\<acute> =\<^sub>u $tr)) = ($tr\<acute> =\<^sub>u $tr)"
  apply (rel_auto) using minus_zero_eq by blast

lemma R1_R2s_tr'_extend_tr:
  "\<lbrakk> $tr \<sharp> v; $tr\<acute> \<sharp> v \<rbrakk> \<Longrightarrow> R1 (R2s ($tr\<acute> =\<^sub>u $tr ^\<^sub>u v)) = ($tr\<acute> =\<^sub>u $tr  ^\<^sub>u v)"
  apply (rel_auto)
  apply (metis less_eq_list_def prefix_concat_minus self_append_conv2 zero_list_def)
  apply (metis append_minus self_append_conv2 zero_list_def)
  apply (simp add: Prefix_Order.prefixI)
done

lemma R2_tr_prefix: "R2($tr \<le>\<^sub>u $tr\<acute>) = ($tr \<le>\<^sub>u $tr\<acute>)"
  by (pred_auto)

lemma R2_form:
  "R2(P) = (\<^bold>\<exists> tt\<^sub>0 \<bullet> P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>0\<guillemotright>/$tr\<acute>\<rbrakk> \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>0\<guillemotright>)"
  by (rel_auto, metis trace_class.add_diff_cancel_left trace_class.le_iff_add)

lemma R2_seqr_form:
  shows "(R2(P) ;; R2(Q)) =
         (\<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> ((P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk>) ;; (Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk>))
                        \<and> ($tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>))"
proof -
  have "(R2(P) ;; R2(Q)) = (\<^bold>\<exists> tr\<^sub>0 \<bullet> (R2(P))\<lbrakk>\<guillemotleft>tr\<^sub>0\<guillemotright>/$tr\<acute>\<rbrakk> ;; (R2(Q))\<lbrakk>\<guillemotleft>tr\<^sub>0\<guillemotright>/$tr\<rbrakk>)"
    by (subst seqr_middle[of tr], simp_all)
  also have "... =
       (\<^bold>\<exists> tr\<^sub>0 \<bullet> \<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> ((P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk> \<and> \<guillemotleft>tr\<^sub>0\<guillemotright> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright>) ;;
                                (Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk> \<and> $tr\<acute> =\<^sub>u \<guillemotleft>tr\<^sub>0\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>)))"
    by (simp add: R2_form usubst unrest uquant_lift, rel_blast)
  also have "... =
       (\<^bold>\<exists> tr\<^sub>0 \<bullet> \<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> ((\<guillemotleft>tr\<^sub>0\<guillemotright> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright> \<and> P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk>) ;;
                                (Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk> \<and> $tr\<acute> =\<^sub>u \<guillemotleft>tr\<^sub>0\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>)))"
    by (simp add: conj_comm)
  also have "... =
       (\<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> \<^bold>\<exists> tr\<^sub>0 \<bullet> ((P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk>) ;; (Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk>))
                                \<and> \<guillemotleft>tr\<^sub>0\<guillemotright> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright> \<and> $tr\<acute> =\<^sub>u \<guillemotleft>tr\<^sub>0\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>)"
    by (rel_blast)
  also have "... =
       (\<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> ((P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk>) ;; (Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk>))
                        \<and> (\<^bold>\<exists> tr\<^sub>0 \<bullet> \<guillemotleft>tr\<^sub>0\<guillemotright> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright> \<and> $tr\<acute> =\<^sub>u \<guillemotleft>tr\<^sub>0\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>))"
    by (rel_auto)
  also have "... =
       (\<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> ((P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk>) ;; (Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk>))
                        \<and> ($tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>))"
    by (rel_auto)
  finally show ?thesis .
qed

lemma R2_seqr_distribute:
  fixes P :: "('t::trace,'\<alpha>,'\<beta>) rel_rp" and Q :: "('t,'\<beta>,'\<gamma>) rel_rp"
  shows "R2(R2(P) ;; R2(Q)) = (R2(P) ;; R2(Q))"
proof -
  have "R2(R2(P) ;; R2(Q)) =
    ((\<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> (P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk> ;; Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk>)\<lbrakk>($tr\<acute> - $tr)/$tr\<acute>\<rbrakk>
      \<and> $tr\<acute> - $tr =\<^sub>u \<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>) \<and> $tr\<acute> \<ge>\<^sub>u $tr)"
    by (simp add: R2_seqr_form, simp add: R2s_def usubst unrest, rel_auto)
  also have "... =
    ((\<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> (P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk> ;; Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk>)\<lbrakk>(\<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>)/$tr\<acute>\<rbrakk>
      \<and> $tr\<acute> - $tr =\<^sub>u \<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>) \<and> $tr\<acute> \<ge>\<^sub>u $tr)"
      by (subst subst_eq_replace, simp)
  also have "... =
    ((\<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> (P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk> ;; Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk>)
      \<and> $tr\<acute> - $tr =\<^sub>u \<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>) \<and> $tr\<acute> \<ge>\<^sub>u $tr)"
      by (rel_auto)
  also have "... =
    (\<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> (P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk> ;; Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk>)
      \<and> ($tr\<acute> - $tr =\<^sub>u \<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright> \<and> $tr\<acute> \<ge>\<^sub>u $tr))"
    by pred_auto
  also have "... =
    ((\<^bold>\<exists> tt\<^sub>1 \<bullet> \<^bold>\<exists> tt\<^sub>2 \<bullet> (P\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<acute>\<rbrakk> ;; Q\<lbrakk>0/$tr\<rbrakk>\<lbrakk>\<guillemotleft>tt\<^sub>2\<guillemotright>/$tr\<acute>\<rbrakk>)
      \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>))"
  proof -
    have "\<And> tt\<^sub>1 tt\<^sub>2. ((($tr\<acute> - $tr =\<^sub>u \<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>) \<and> $tr\<acute> \<ge>\<^sub>u $tr) :: ('t,'\<alpha>,'\<gamma>) rel_rp)
           = ($tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright> + \<guillemotleft>tt\<^sub>2\<guillemotright>)"
      apply (rel_auto)
      apply (metis add.assoc diff_add_cancel_left')
      apply (simp add: add.assoc)
      apply (meson le_add order_trans)
    done
    thus ?thesis by simp
  qed
  also have "... = (R2(P) ;; R2(Q))"
    by (simp add: R2_seqr_form)
  finally show ?thesis .
qed

lemma R2_seqr_closure [closure]:
  assumes "P is R2" "Q is R2"
  shows "(P ;; Q) is R2"
  by (metis Healthy_def' R2_seqr_distribute assms(1) assms(2))

lemma R1_R2_commute:
  "R1(R2(P)) = R2(R1(P))"
  by pred_auto

lemma R2_R1_form: "R2(R1(P)) = R1(R2s(P))"
  by (rel_auto)

lemma R2s_H1_commute:
  "R2s(H1(P)) = H1(R2s(P))"
  by (rel_auto)

lemma R2s_H2_commute:
  "R2s(H2(P)) = H2(R2s(P))"
  by (simp add: H2_split R2s_def usubst)

lemma R2_R1_seq_drop_left:
  "R2(R1(P) ;; R1(Q)) = R2(P ;; R1(Q))"
  by (rel_auto)

lemma R2c_idem: "R2c(R2c(P)) = R2c(P)"
  by (rel_auto)

lemma R2c_Idempotent [closure]: "Idempotent R2c"
  by (simp add: Idempotent_def R2c_idem)

lemma R2c_Monotonic [closure]: "Monotonic R2c"
  by (rel_auto)

lemma R2c_H2_commute: "R2c(H2(P)) = H2(R2c(P))"
  by (simp add: H2_split R2c_disj R2c_def R2s_def usubst, rel_auto)

lemma R2c_seq: "R2c(R2(P) ;; R2(Q)) = (R2(P) ;; R2(Q))"
  by (metis (no_types, lifting) R1_R2c_commute R1_R2c_is_R2 R2_seqr_distribute R2c_idem)

lemma R2_R2c_def: "R2(P) = R1(R2c(P))"
  by (rel_auto)

lemma R2c_R1_seq: "R2c(R1(R2c(P)) ;; R1(R2c(Q))) = (R1(R2c(P)) ;; R1(R2c(Q)))"
  using R2c_seq[of P Q] by (simp add: R2_R2c_def)

lemma R1_R2c_seqr_distribute:
  fixes P :: "('t::trace,'\<alpha>,'\<beta>) rel_rp" and Q :: "('t,'\<beta>,'\<gamma>) rel_rp"
  assumes "P is R1" "P is R2c" "Q is R1" "Q is R2c"
  shows "R1(R2c(P ;; Q)) = P ;; Q"
  by (metis Healthy_if R1_seqr R2c_R1_seq assms)

lemma R2_R1_true:
  "R2(R1(true)) = R1(true)"
  by (simp add: R2_R1_form R2s_true)
    
lemma R1_true_R2 [closure]: "R1(true) is R2"
  by (rel_auto)
    
subsection {* R3 *}

definition R3_def [upred_defs]: "R3(P) = (II \<triangleleft> $wait \<triangleright> P)"

lemma R3_idem: "R3(R3(P)) = R3(P)"
  by (rel_auto)

lemma R3_Idempotent [closure]: "Idempotent R3"
  by (simp add: Idempotent_def R3_idem)

lemma R3_mono: "P \<sqsubseteq> Q \<Longrightarrow> R3(P) \<sqsubseteq> R3(Q)"
  by (rel_auto)

lemma R3_Monotonic: "Monotonic R3"
  by (simp add: mono_def R3_mono)

lemma R3_Continuous: "Continuous R3"
  by (rel_auto)

lemma R3_conj: "R3(P \<and> Q) = (R3(P) \<and> R3(Q))"
  by (rel_auto)

lemma R3_disj: "R3(P \<or> Q) = (R3(P) \<or> R3(Q))"
  by (rel_auto)

lemma R3_USUP:
  assumes "A \<noteq> {}"
  shows "R3(\<Sqinter> i \<in> A \<bullet> P(i)) = (\<Sqinter> i \<in> A \<bullet> R3(P(i)))"
  using assms by (rel_auto)

lemma R3_UINF:
  assumes "A \<noteq> {}"
  shows "R3(\<Squnion> i \<in> A \<bullet> P(i)) = (\<Squnion> i \<in> A \<bullet> R3(P(i)))"
  using assms by (rel_auto)

lemma R3_condr: "R3(P \<triangleleft> b \<triangleright> Q) = (R3(P) \<triangleleft> b \<triangleright> R3(Q))"
  by (rel_auto)

lemma R3_skipr: "R3(II) = II"
  by (rel_auto)

lemma R3_form: "R3(P) = (($wait \<and> II) \<or> (\<not> $wait \<and> P))"
  by (rel_auto)

lemma wait_R3:
  "($wait \<and> R3(P)) = (II \<and> $wait\<acute>)"
  by (rel_auto)

lemma nwait_R3:
  "(\<not>$wait \<and> R3(P)) = (\<not>$wait \<and> P)"
  by (rel_auto)

lemma R3_semir_form:
  "(R3(P) ;; R3(Q)) = R3(P ;; R3(Q))"
  by (rel_auto)

lemma R3_semir_closure:
  assumes "P is R3" "Q is R3"
  shows "(P ;; Q) is R3"
  using assms
  by (metis Healthy_def' R3_semir_form)

lemma R1_R3_commute: "R1(R3(P)) = R3(R1(P))"
  by (rel_auto)

lemma R2_R3_commute: "R2(R3(P)) = R3(R2(P))"
  apply (rel_auto)
  using minus_zero_eq apply blast+
done

subsection {* RP laws *}

definition RP_def [upred_defs]: "RP(P) = R1(R2c(R3(P)))"

lemma RP_comp_def: "RP = R1 \<circ> R2c \<circ> R3"
  by (auto simp add: RP_def)

lemma RP_alt_def: "RP(P) = R1(R2(R3(P)))"
  by (metis R1_R2c_is_R2 R1_idem RP_def)

lemma RP_intro: "\<lbrakk> P is R1; P is R2; P is R3 \<rbrakk> \<Longrightarrow> P is RP"
  by (simp add: Healthy_def' RP_alt_def)

lemma RP_idem: "RP(RP(P)) = RP(P)"
  by (simp add: R1_R2c_is_R2 R2_R3_commute R2_idem R3_idem RP_def)

lemma RP_Idempotent [closure]: "Idempotent RP"
  by (simp add: Idempotent_def RP_idem)

lemma RP_mono: "P \<sqsubseteq> Q \<Longrightarrow> RP(P) \<sqsubseteq> RP(Q)"
  by (simp add: R1_R2c_is_R2 R2_mono R3_mono RP_def)

lemma RP_Monotonic: "Monotonic RP"
  by (simp add: mono_def RP_mono)

lemma RP_Continuous: "Continuous RP"
  by (simp add: Continuous_comp R1_Continuous R2c_Continuous R3_Continuous RP_comp_def)

lemma RP_skip:
  "RP(II) = II"
  by (simp add: R1_skip R2c_skip_r R3_skipr RP_def)

lemma RP_skip_closure:
  "II is RP"
  by (simp add: Healthy_def' RP_skip)

lemma RP_seq_closure:
  assumes "P is RP" "Q is RP"
  shows "(P ;; Q) is RP"
proof (rule RP_intro)
  show "(P ;; Q) is R1"
    by (metis Healthy_def R1_seqr RP_def assms)
  thus "(P ;; Q) is R2"
    by (metis Healthy_def' R2_R2c_def R2c_R1_seq RP_def  assms)
  show "(P ;; Q) is R3"
    by (metis (no_types, lifting) Healthy_def' R1_R2c_is_R2 R2_R3_commute R3_idem R3_semir_form RP_def assms)
qed

subsection {* UTP theories *}

typedecl REA
abbreviation "REA \<equiv> UTHY(REA, ('t::trace,'\<alpha>) rp)"

overloading
  rea_hcond == "utp_hcond :: (REA, ('t::trace,'\<alpha>) rp) uthy \<Rightarrow> (('t,'\<alpha>) rp \<times> ('t,'\<alpha>) rp) health"
  rea_unit == "utp_unit :: (REA, ('t::trace,'\<alpha>) rp) uthy \<Rightarrow> ('t,'\<alpha>) hrel_rp"
begin
  definition rea_hcond :: "(REA, ('t::trace,'\<alpha>) rp) uthy \<Rightarrow> (('t,'\<alpha>) rp \<times> ('t,'\<alpha>) rp) health"
  where [upred_defs]: "rea_hcond T = RP"
  definition rea_unit :: "(REA, ('t::trace,'\<alpha>) rp) uthy \<Rightarrow> ('t,'\<alpha>) hrel_rp"
  where [upred_defs]: "rea_unit T = II"
end

interpretation rea_utp_theory: utp_theory "UTHY(REA, ('t::trace,'\<alpha>) rp)"
  rewrites "carrier (uthy_order REA) = \<lbrakk>RP\<rbrakk>\<^sub>H"
  by (simp_all add: rea_hcond_def utp_theory_def RP_idem)

interpretation rea_utp_theory_mono: utp_theory_continuous "UTHY(REA, ('t::trace,'\<alpha>) rp)"
  rewrites "carrier (uthy_order REA) = \<lbrakk>RP\<rbrakk>\<^sub>H"
  by (unfold_locales, simp_all add: RP_Continuous rea_hcond_def)

interpretation rea_utp_theory_rel: utp_theory_unital "UTHY(REA, ('t::trace,'\<alpha>) rp)"
  rewrites "carrier (uthy_order REA) = \<lbrakk>RP\<rbrakk>\<^sub>H"
  by (unfold_locales, simp_all add: rea_hcond_def rea_unit_def RP_seq_closure RP_skip_closure)

lemma rea_top: "\<^bold>\<top>\<^bsub>REA\<^esub> = ($wait \<and> II)"
proof -
  have "\<^bold>\<top>\<^bsub>REA\<^esub> = RP(false)"
    by (simp add: rea_utp_theory_mono.healthy_top, simp add: rea_hcond_def)
  also have "... = ($wait \<and> II)"
    by (rel_auto, metis minus_zero_eq)
  finally show ?thesis .
qed

lemma rea_top_left_zero:
  assumes "P is RP"
  shows "(\<^bold>\<top>\<^bsub>REA\<^esub> ;; P) = \<^bold>\<top>\<^bsub>REA\<^esub>"
proof -
  have "(\<^bold>\<top>\<^bsub>REA\<^esub> ;; P) = (($wait \<and> II) ;; R3(P))"
    by (metis (no_types, lifting) Healthy_def R1_R2c_is_R2 R2_R3_commute R3_idem RP_def assms rea_top)
  also have "... = ($wait \<and> R3(P))"
    by (rel_auto)
  also have "... = ($wait \<and> II)"
    by (metis R3_skipr wait_R3)
  also have "... = \<^bold>\<top>\<^bsub>REA\<^esub>"
    by (simp add: rea_top)
  finally show ?thesis .
qed

lemma rea_bottom: "\<^bold>\<bottom>\<^bsub>REA\<^esub> = R1($wait \<Rightarrow> II)"
proof -
  have "\<^bold>\<bottom>\<^bsub>REA\<^esub> = RP(true)"
    by (simp add: rea_utp_theory_mono.healthy_bottom, simp add: rea_hcond_def)
  also have "... = R1($wait \<Rightarrow> II)"
    by (rel_auto, metis minus_zero_eq)
  finally show ?thesis .
qed

subsection {* Reactive parallel-by-merge *}

text {* We show closure of parallel by merge under the reactive healthiness conditions by means
  of suitable restrictions on the merge predicate. We first define healthiness conditions
  for R1 and R2 merge predicates. *}

definition R1m :: "('t :: trace, '\<alpha>) rp merge \<Rightarrow> ('t, '\<alpha>) rp merge"
  where [upred_defs]: "R1m(M) = (M \<and> $tr\<^sub>< \<le>\<^sub>u $tr\<acute>)"

definition R1m' :: "('t :: trace, '\<alpha>) rp merge \<Rightarrow> ('t, '\<alpha>) rp merge"
  where [upred_defs]: "R1m'(M) = (M \<and> $tr\<^sub>< \<le>\<^sub>u $tr\<acute> \<and> $tr\<^sub>< \<le>\<^sub>u $0-tr \<and> $tr\<^sub>< \<le>\<^sub>u $1-tr)"

text {* A merge predicate can access the history through $tr$, as usual, but also through $0.tr$ and
  $1.tr$. Thus we have to remove the latter two histories as well to satisfy R2 for the overall
  construction. *}

term "M\<lbrakk>0,x,k/y,z,a\<rbrakk>"
  
term "M\<lbrakk>0,$tr\<acute> - $tr\<^sub><,$0-tr - $tr\<^sub><,$1-tr - $tr\<^sub></$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>"
  
definition R2m :: "('t :: trace, '\<alpha>) rp merge \<Rightarrow> ('t, '\<alpha>) rp merge"
  where [upred_defs]: "R2m(M) = R1m(M\<lbrakk>0,$tr\<acute> - $tr\<^sub><,$0-tr - $tr\<^sub><,$1-tr - $tr\<^sub></$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>)"

definition R2m' :: "('t :: trace, '\<alpha>) rp merge \<Rightarrow> ('t, '\<alpha>) rp merge"
  where [upred_defs]: "R2m'(M) = R1m'(M\<lbrakk>0,$tr\<acute> - $tr\<^sub><,$0-tr - $tr\<^sub><,$1-tr - $tr\<^sub></$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>)"

definition R2cm :: "('t :: trace, '\<alpha>) rp merge \<Rightarrow> ('t, '\<alpha>) rp merge"
  where [upred_defs]: "R2cm(M) = M\<lbrakk>0,$tr\<acute> - $tr\<^sub><,$0-tr - $tr\<^sub><,$1-tr - $tr\<^sub></$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk> \<triangleleft> $tr\<^sub>< \<le>\<^sub>u $tr\<acute> \<triangleright> M"

lemma R2m'_form:
  "R2m'(M) =
  (\<^bold>\<exists> (tt\<^sub>p, tt\<^sub>0, tt\<^sub>1) \<bullet> M\<lbrakk>0,\<guillemotleft>tt\<^sub>p\<guillemotright>,\<guillemotleft>tt\<^sub>0\<guillemotright>,\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>
                    \<and> $tr\<acute> =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>p\<guillemotright>
                    \<and> $0-tr =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>0\<guillemotright>
                    \<and> $1-tr =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>1\<guillemotright>)"
  by (rel_auto, metis diff_add_cancel_left')

lemma R1m_idem: "R1m(R1m(P)) = R1m(P)"
  by (rel_auto)

lemma R1m_seq_lemma: "R1m(R1m(M) ;; R1(P)) = R1m(M) ;; R1(P)"
  by (rel_auto)

lemma R1m_seq [closure]:
  assumes "M is R1m" "P is R1"
  shows "M ;; P is R1m"
proof -
  from assms have "R1m(M ;; P) = R1m(R1m(M) ;; R1(P))"
    by (simp add: Healthy_if)
  also have "... = R1m(M) ;; R1(P)"
    by (simp add: R1m_seq_lemma)
  also have "... = M ;; P"
    by (simp add: Healthy_if assms)
  finally show ?thesis
    by (simp add: Healthy_def)
qed

lemma R2m_idem: "R2m(R2m(P)) = R2m(P)"
  by (rel_auto)

lemma R2m_seq_lemma: "R2m'(R2m'(M) ;; R2(P)) = R2m'(M) ;; R2(P)"
  apply (simp add: R2m'_form R2_form)
  apply (rel_auto)
  apply (metis (no_types, lifting) add.assoc)+
done

lemma R2m'_seq [closure]:
  assumes "M is R2m'" "P is R2"
  shows "M ;; P is R2m'"
  by (metis Healthy_def' R2m_seq_lemma assms(1) assms(2))

lemma R1_par_by_merge [closure]:
  "M is R1m \<Longrightarrow> (P \<parallel>\<^bsub>M\<^esub> Q) is R1"
  by (rel_blast)
    
lemma R2_R2m'_pbm: "R2(P \<parallel>\<^bsub>M\<^esub> Q) = (R2(P) \<parallel>\<^bsub>R2m'(M)\<^esub> R2(Q))"
proof -
  have "(R2(P) \<parallel>\<^bsub>R2m'(M)\<^esub> R2(Q)) = ((R2(P) \<parallel>\<^sub>s R2(Q)) ;;
                   (\<^bold>\<exists> (tt\<^sub>p, tt\<^sub>0, tt\<^sub>1) \<bullet> M\<lbrakk>0,\<guillemotleft>tt\<^sub>p\<guillemotright>,\<guillemotleft>tt\<^sub>0\<guillemotright>,\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>
                                     \<and> $tr\<acute> =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>p\<guillemotright>
                                     \<and> $0-tr =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>0\<guillemotright>
                                     \<and> $1-tr =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>1\<guillemotright>))"
    by (simp add: par_by_merge_def R2m'_form)
  also have "... = (\<^bold>\<exists> (tt\<^sub>p, tt\<^sub>0, tt\<^sub>1) \<bullet> ((R2(P) \<parallel>\<^sub>s R2(Q)) ;; (M\<lbrakk>0,\<guillemotleft>tt\<^sub>p\<guillemotright>,\<guillemotleft>tt\<^sub>0\<guillemotright>,\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>
                                                  \<and> $tr\<acute> =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>p\<guillemotright>
                                                  \<and> $0-tr =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>0\<guillemotright>
                                                  \<and> $1-tr =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>1\<guillemotright>)))"
    by (rel_blast)
  also have "... = (\<^bold>\<exists> (tt\<^sub>p, tt\<^sub>0, tt\<^sub>1) \<bullet> (((R2(P) \<parallel>\<^sub>s R2(Q)) \<and> $0-tr\<acute> =\<^sub>u $tr\<^sub><\<acute> + \<guillemotleft>tt\<^sub>0\<guillemotright> \<and> $1-tr\<acute> =\<^sub>u $tr\<^sub><\<acute> + \<guillemotleft>tt\<^sub>1\<guillemotright>) ;;
                                      (M\<lbrakk>0,\<guillemotleft>tt\<^sub>p\<guillemotright>,\<guillemotleft>tt\<^sub>0\<guillemotright>,\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk> \<and> $tr\<acute> =\<^sub>u $tr\<^sub>< + \<guillemotleft>tt\<^sub>p\<guillemotright>)))"
    by (rel_blast)
  also have "... = (\<^bold>\<exists> (tt\<^sub>p, tt\<^sub>0, tt\<^sub>1) \<bullet> (((R2(P) \<parallel>\<^sub>s R2(Q)) \<and> $0-tr\<acute> =\<^sub>u $tr\<^sub><\<acute> + \<guillemotleft>tt\<^sub>0\<guillemotright> \<and> $1-tr\<acute> =\<^sub>u $tr\<^sub><\<acute> + \<guillemotleft>tt\<^sub>1\<guillemotright>) ;;
                                      (M\<lbrakk>0,\<guillemotleft>tt\<^sub>p\<guillemotright>,\<guillemotleft>tt\<^sub>0\<guillemotright>,\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>)) \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>p\<guillemotright>)"
    by (rel_blast)
  also have "... = (\<^bold>\<exists> (tt\<^sub>p, tt\<^sub>0, tt\<^sub>1) \<bullet> (((R2(P) \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>0\<guillemotright>) \<parallel>\<^sub>s (R2(Q) \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright>)) ;;
                                      (M\<lbrakk>0,\<guillemotleft>tt\<^sub>p\<guillemotright>,\<guillemotleft>tt\<^sub>0\<guillemotright>,\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>)) \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>p\<guillemotright>)"
    by (rel_auto, blast, metis le_add trace_class.add_diff_cancel_left)
  also have "... = (\<^bold>\<exists> (tt\<^sub>p, tt\<^sub>0, tt\<^sub>1) \<bullet> ((   ((\<^bold>\<exists> tt\<^sub>0' \<bullet> P\<lbrakk>0,\<guillemotleft>tt\<^sub>0'\<guillemotright>/$tr,$tr\<acute>\<rbrakk> \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>0'\<guillemotright>) \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>0\<guillemotright>)
                                       \<parallel>\<^sub>s ((\<^bold>\<exists> tt\<^sub>1' \<bullet> Q\<lbrakk>0,\<guillemotleft>tt\<^sub>1'\<guillemotright>/$tr,$tr\<acute>\<rbrakk> \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1'\<guillemotright>) \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright>)) ;;
                                      (M\<lbrakk>0,\<guillemotleft>tt\<^sub>p\<guillemotright>,\<guillemotleft>tt\<^sub>0\<guillemotright>,\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>)) \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>p\<guillemotright>)"
    by (simp add: R2_form usubst)
  also have "... = (\<^bold>\<exists> (tt\<^sub>p, tt\<^sub>0, tt\<^sub>1) \<bullet> ((   (P\<lbrakk>0,\<guillemotleft>tt\<^sub>0\<guillemotright>/$tr,$tr\<acute>\<rbrakk>  \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>0\<guillemotright>)
                                       \<parallel>\<^sub>s (Q\<lbrakk>0,\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr,$tr\<acute>\<rbrakk> \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>1\<guillemotright>)) ;;
                                      (M\<lbrakk>0,\<guillemotleft>tt\<^sub>p\<guillemotright>,\<guillemotleft>tt\<^sub>0\<guillemotright>,\<guillemotleft>tt\<^sub>1\<guillemotright>/$tr\<^sub><,$tr\<acute>,$0-tr,$1-tr\<rbrakk>)) \<and> $tr\<acute> =\<^sub>u $tr + \<guillemotleft>tt\<^sub>p\<guillemotright>)"
    by (rel_auto, metis left_cancel_monoid_class.add_left_imp_eq, blast)
  also have "... = R2(P \<parallel>\<^bsub>M\<^esub> Q)"
    by (rel_auto, blast, metis diff_add_cancel_left')
  finally show ?thesis ..
qed

lemma R2m_R2m'_pbm: "(R2(P) \<parallel>\<^bsub>R2m(M)\<^esub> R2(Q)) = (R2(P) \<parallel>\<^bsub>R2m'(M)\<^esub> R2(Q))"
  by (rel_blast)

lemma R2_par_by_merge [closure]:
  assumes "P is R2" "Q is R2" "M is R2m"
  shows "(P \<parallel>\<^bsub>M\<^esub> Q) is R2"
  by (metis Healthy_def' R2_R2m'_pbm R2m_R2m'_pbm assms(1) assms(2) assms(3))

lemma R2_par_by_merge' [closure]:
  assumes "P is R2" "Q is R2" "M is R2m'"
  shows "(P \<parallel>\<^bsub>M\<^esub> Q) is R2"
  by (metis Healthy_def' R2_R2m'_pbm assms(1) assms(2) assms(3))
  
lemma R1m_skip_merge: "R1m(skip\<^sub>m) = skip\<^sub>m"
  by (rel_auto)

lemma R1m_disj: "R1m(P \<or> Q) = (R1m(P) \<or> R1m(Q))"
  by (rel_auto)

lemma R1m_conj: "R1m(P \<and> Q) = (R1m(P) \<and> R1m(Q))"
  by (rel_auto)

lemma R2m_skip_merge: "R2m(skip\<^sub>m) = skip\<^sub>m"
  apply (rel_auto) using minus_zero_eq by blast

lemma R2m_disj: "R2m(P \<or> Q) = (R2m(P) \<or> R2m(Q))"
  by (rel_auto)

lemma R2m_conj: "R2m(P \<and> Q) = (R2m(P) \<and> R2m(Q))"
  by (rel_auto)

definition R3m :: "('t :: trace, '\<alpha>) rp merge \<Rightarrow> ('t, '\<alpha>) rp merge" where
  [upred_defs]: "R3m(M) = skip\<^sub>m \<triangleleft> $wait\<^sub>< \<triangleright> M"

lemma R3_par_by_merge:
  assumes
    "P is R3" "Q is R3" "M is R3m"
  shows "(P \<parallel>\<^bsub>M\<^esub> Q) is R3"
proof -
  have "(P \<parallel>\<^bsub>M\<^esub> Q) = ((P \<parallel>\<^bsub>M\<^esub> Q)\<lbrakk>true/$wait\<rbrakk> \<triangleleft> $wait \<triangleright> (P \<parallel>\<^bsub>M\<^esub> Q))"
    by (metis cond_L6 cond_var_split in_var_uvar wait_vwb_lens)
  also have "... = (((R3 P)\<lbrakk>true/$wait\<rbrakk> \<parallel>\<^bsub>(R3m M)\<lbrakk>true/$wait\<^sub><\<rbrakk>\<^esub> (R3 Q)\<lbrakk>true/$wait\<rbrakk>) \<triangleleft> $wait \<triangleright> (P \<parallel>\<^bsub>M\<^esub> Q))"
    by (subst_tac, simp add: Healthy_if assms)
  also have "... = ((II\<lbrakk>true/$wait\<rbrakk> \<parallel>\<^bsub>skip\<^sub>m\<lbrakk>true/$wait\<^sub><\<rbrakk>\<^esub> II\<lbrakk>true/$wait\<rbrakk>) \<triangleleft> $wait \<triangleright> (P \<parallel>\<^bsub>M\<^esub> Q))"
    by (simp add: R3_def R3m_def usubst)
  also have "... = ((II \<parallel>\<^bsub>skip\<^sub>m\<^esub> II)\<lbrakk>true/$wait\<rbrakk> \<triangleleft> $wait \<triangleright> (P \<parallel>\<^bsub>M\<^esub> Q))"
    by (subst_tac)
  also have "... = (II \<triangleleft> $wait \<triangleright> (P \<parallel>\<^bsub>M\<^esub> Q))"
    by (simp add: cond_var_subst_left par_by_merge_skip)
  also have "... = R3(P \<parallel>\<^bsub>M\<^esub> Q)"
    by (simp add: R3_def)
  finally show ?thesis
    by (simp add: Healthy_def)
qed

lemma SymMerge_R1_true [closure]:
  "M is SymMerge \<Longrightarrow> M ;; R1(true) is SymMerge"
  by (rel_auto)

subsection {* Reactive Relations *}
   
text {* Predicate calculus for R1-R2 predicates as an extension of the standard alphabetised
  predicate calculus. *}
  
named_theorems rpred
  
abbreviation rea_true ("true\<^sub>r") where "true\<^sub>r \<equiv> R1(true)"     

definition rea_not :: "('t::trace,'\<alpha>,'\<beta>) rel_rp \<Rightarrow> ('t,'\<alpha>,'\<beta>) rel_rp" ("\<not>\<^sub>r _" [40] 40) 
where [upred_defs]: "(\<not>\<^sub>r P) = R1(\<not> P)"

definition rea_diff :: "('t::trace,'\<alpha>,'\<beta>) rel_rp \<Rightarrow> ('t,'\<alpha>,'\<beta>) rel_rp \<Rightarrow> ('t,'\<alpha>,'\<beta>) rel_rp" (infixl "-\<^sub>r" 65)
where [upred_defs]: "rea_diff P Q = (P \<and> \<not>\<^sub>r Q)"
  
definition rea_impl :: 
  "('t::trace,'\<alpha>,'\<beta>) rel_rp \<Rightarrow> ('t,'\<alpha>,'\<beta>) rel_rp \<Rightarrow> ('t,'\<alpha>,'\<beta>) rel_rp" (infixr "\<Rightarrow>\<^sub>r" 25) 
where [upred_defs]: "(P \<Rightarrow>\<^sub>r Q) = (\<not>\<^sub>r P \<or> Q)"

lemma R1_rea_not: "R1(\<not>\<^sub>r P) = (\<not>\<^sub>r P)"
  by rel_auto
    
lemma R1_rea_not': "R1(\<not>\<^sub>r P) = (\<not>\<^sub>r R1(P))"
  by rel_auto  
  
lemma R2c_rea_not: "R2c(\<not>\<^sub>r P) = (\<not>\<^sub>r R2c(P))"
  by rel_auto
  
lemma R1_rea_impl: "R1(P \<Rightarrow>\<^sub>r Q) = (P \<Rightarrow>\<^sub>r R1(Q))"
  by (rel_auto)

lemma R1_rea_impl': "R1(P \<Rightarrow>\<^sub>r Q) = (R1(P) \<Rightarrow>\<^sub>r R1(Q))"
  by (rel_auto)
    
lemma R2c_rea_impl: "R2c(P \<Rightarrow>\<^sub>r Q) = (R2c(P) \<Rightarrow>\<^sub>r R2c(Q))"
  by (rel_auto)
  
lemma rea_true_R1 [closure]: "true\<^sub>r is R1"
  by (rel_auto)
  
lemma rea_true_R2c [closure]: "true\<^sub>r is R2c"
  by (rel_auto)
    
lemma rea_not_R1 [closure]: "\<not>\<^sub>r P is R1"
  by (rel_auto)

lemma rea_not_R2c [closure]: "P is R2c \<Longrightarrow> \<not>\<^sub>r P is R2c"
  by (simp add: Healthy_def rea_not_def R1_R2c_commute[THEN sym] R2c_not)
   
lemma rea_not_R2_closed [closure]:
  "P is R2 \<Longrightarrow> (\<not>\<^sub>r P) is R2"
  by (simp add: Healthy_def' R1_rea_not' R2_R2c_def R2c_rea_not)
    
lemma rea_impl_R1 [closure]: 
  "Q is R1 \<Longrightarrow> (P \<Rightarrow>\<^sub>r Q) is R1"
  by (rel_blast)

lemma rea_impl_R2c [closure]: 
  "\<lbrakk> P is R2c; Q is R2c \<rbrakk> \<Longrightarrow> (P \<Rightarrow>\<^sub>r Q) is R2c"
  by (simp add: rea_impl_def Healthy_def rea_not_def R1_R2c_commute[THEN sym] R2c_not R2c_disj)
    
lemma rea_true_unrest [unrest]:
  "\<lbrakk> x \<bowtie> ($tr)\<^sub>v; x \<bowtie> ($tr\<acute>)\<^sub>v \<rbrakk> \<Longrightarrow> x \<sharp> true\<^sub>r"
  by (simp add: R1_def unrest lens_indep_sym)

lemma rea_not_unrest [unrest]:
  "\<lbrakk> x \<bowtie> ($tr)\<^sub>v; x \<bowtie> ($tr\<acute>)\<^sub>v; x \<sharp> P \<rbrakk> \<Longrightarrow> x \<sharp> \<not>\<^sub>r P"
  by (simp add: rea_not_def R1_def unrest lens_indep_sym)

lemma rea_impl_unrest [unrest]:
  "\<lbrakk> x \<bowtie> ($tr)\<^sub>v; x \<bowtie> ($tr\<acute>)\<^sub>v; x \<sharp> P; x \<sharp> Q \<rbrakk> \<Longrightarrow> x \<sharp> (P \<Rightarrow>\<^sub>r Q)"
  by (simp add: rea_impl_def unrest)
    
lemma rea_true_usubst [usubst]:
  "\<lbrakk> $tr \<sharp> \<sigma>; $tr\<acute> \<sharp> \<sigma> \<rbrakk> \<Longrightarrow> \<sigma> \<dagger> true\<^sub>r = true\<^sub>r"
  by (simp add: R1_def usubst)
  
lemma rea_not_usubst [usubst]:
  "\<lbrakk> $tr \<sharp> \<sigma>; $tr\<acute> \<sharp> \<sigma> \<rbrakk> \<Longrightarrow> \<sigma> \<dagger> (\<not>\<^sub>r P) = (\<not>\<^sub>r \<sigma> \<dagger> P)"
  by (simp add: rea_not_def R1_def usubst)

lemma rea_impl_usubst [usubst]:
  "\<lbrakk> $tr \<sharp> \<sigma>; $tr\<acute> \<sharp> \<sigma> \<rbrakk> \<Longrightarrow> \<sigma> \<dagger> (P \<Rightarrow>\<^sub>r Q) = (\<sigma> \<dagger> P \<Rightarrow>\<^sub>r \<sigma> \<dagger> Q)"
  by (simp add: rea_impl_def usubst)
    
lemma rea_true_conj [rpred]: 
  assumes "P is R1"
  shows "(true\<^sub>r \<and> P) = P" "(P \<and> true\<^sub>r) = P"
  using assms
  by (simp_all add: Healthy_def R1_def utp_pred_laws.inf_commute) 

lemma rea_true_disj [rpred]: 
  assumes "P is R1"
  shows "(true\<^sub>r \<or> P) = true\<^sub>r" "(P \<or> true\<^sub>r) = true\<^sub>r"
  using assms by (metis Healthy_def R1_disj disj_comm true_disj_zero)+
  
lemma rea_not_not [rpred]: "P is R1 \<Longrightarrow> (\<not>\<^sub>r \<not>\<^sub>r P) = P"
  by (simp add: rea_not_def R1_negate_R1 Healthy_if)
    
lemma rea_not_rea_true [simp]: "(\<not>\<^sub>r true\<^sub>r) = false"
  by (simp add: rea_not_def R1_negate_R1 R1_false)
    
lemma rea_not_false [simp]: "(\<not>\<^sub>r false) = true\<^sub>r"
  by (simp add: rea_not_def)
    
lemma rea_true_impl [simp]:
  "(true\<^sub>r \<Rightarrow>\<^sub>r P) = P"
  by (simp add: rea_not_def rea_impl_def R1_negate_R1 R1_false)

lemma rea_true_impl' [simp]:
  "(true \<Rightarrow>\<^sub>r P) = P"
  by (simp add: rea_not_def rea_impl_def R1_negate_R1 R1_false)
    
lemma rea_false_impl [rpred]:
  "P is R1 \<Longrightarrow> (false \<Rightarrow>\<^sub>r P) = true\<^sub>r"
  by (simp add: rea_impl_def rpred)
   
lemma rea_impl_true [simp]: "(P \<Rightarrow>\<^sub>r true\<^sub>r) = true\<^sub>r"
  by (rel_auto)
    
lemma rea_impl_false [simp]: "(P \<Rightarrow>\<^sub>r false) = (\<not>\<^sub>r P)"
  by (rel_simp)
    
lemma rea_not_true [simp]: "(\<not>\<^sub>r true) = false"
  by (rel_auto)
    
lemma rea_not_demorgan1 [simp]:
  "(\<not>\<^sub>r (P \<and> Q)) = (\<not>\<^sub>r P \<or> \<not>\<^sub>r Q)"
  by (rel_auto)

lemma rea_not_demorgan2 [simp]:
  "(\<not>\<^sub>r (P \<or> Q)) = (\<not>\<^sub>r P \<and> \<not>\<^sub>r Q)"
  by (rel_auto)

lemma rea_not_or [rpred]:
  "P is R1 \<Longrightarrow> (P \<or> \<not>\<^sub>r P) = true\<^sub>r"
  by (rel_blast)

lemma rea_not_and [simp]:
  "(P \<and> \<not>\<^sub>r P) = false"
  by (rel_auto)
    
lemma rea_not_INFIMUM [simp]:
  "(\<not>\<^sub>r (\<Squnion>i\<in>A. Q(i))) = (\<Sqinter>i\<in>A. \<not>\<^sub>r Q(i))"
  by (rel_auto)

lemma rea_not_USUP [simp]:
  "(\<not>\<^sub>r (\<Squnion>i\<in>A \<bullet> Q(i))) = (\<Sqinter>i\<in>A \<bullet> \<not>\<^sub>r Q(i))"
  by (rel_auto)
    
lemma rea_not_SUPREMUM [simp]:
  "A \<noteq> {} \<Longrightarrow> (\<not>\<^sub>r (\<Sqinter>i\<in>A. Q(i))) = (\<Squnion>i\<in>A. \<not>\<^sub>r Q(i))"
  by (rel_auto)

lemma rea_not_UINF [simp]:
  "A \<noteq> {} \<Longrightarrow> (\<not>\<^sub>r (\<Sqinter>i\<in>A \<bullet> Q(i))) = (\<Squnion>i\<in>A \<bullet> \<not>\<^sub>r Q(i))"
  by (rel_auto)

lemma USUP_mem_rea_true [simp]: "A \<noteq> {} \<Longrightarrow> (\<Squnion> i \<in> A \<bullet> true\<^sub>r) = true\<^sub>r"
  by (rel_auto)

lemma USUP_ind_rea_true [simp]: "(\<Squnion> i \<bullet> true\<^sub>r) = true\<^sub>r"
  by (rel_auto)
    
text {* Healthiness Condition for Reactive Conditions *}
    
definition [upred_defs]: "RC1(P) = P ;; true\<^sub>r"
  
definition [upred_defs]: "RC = RC1 \<circ> R2c \<circ> R1"
  
lemma RC1_idem: "RC1(RC1(P)) = RC1(P)"
  by (metis (no_types, hide_lams) R1_true_comp RC1_def seqr_assoc)
  
lemma RC1_mono: "P \<sqsubseteq> Q \<Longrightarrow> RC1(P) \<sqsubseteq> RC1(Q)"
  by (simp add: RC1_def seqr_mono)
      
lemma RC1_trace_ext_prefix:
  "out\<alpha> \<sharp> e \<Longrightarrow> RC1($tr ^\<^sub>u e \<le>\<^sub>u $tr\<acute>) = ($tr ^\<^sub>u e \<le>\<^sub>u $tr\<acute>)"
  by (rel_auto, metis (no_types, lifting) dual_order.trans)
    
lemma RC1_disj: "RC1(P \<or> Q) = (RC1(P) \<or> RC1(Q))"
  by (rel_blast)
    
lemma RC_implies_RC1: "P is RC \<Longrightarrow> P is RC1"
  by (metis (no_types, hide_lams) Healthy_def RC1_idem RC_def comp_apply)
    
lemma rea_true_RC [closure]: "true\<^sub>r is RC"
  by (metis (no_types, lifting) Healthy_def R1_idem R1_true_comp RC1_def RC_def comp_apply rea_true_R2c)

lemma false_RC [closure]: "false is RC"
  by (rel_auto)
   
lemma disj_RC_closed [closure]: "\<lbrakk> P is RC; Q is RC \<rbrakk> \<Longrightarrow> (P \<or> Q) is RC"
  by (simp add: Healthy_def R1_disj R2c_disj RC1_disj RC_def)
    
lemma trace_ext_prefix_RC [closure]: 
  "\<lbrakk> $tr \<sharp> e; out\<alpha> \<sharp> e \<rbrakk> \<Longrightarrow> $tr ^\<^sub>u e \<le>\<^sub>u $tr\<acute> is RC"
  apply (rel_auto)
  apply (metis (no_types, lifting) Prefix_Order.same_prefix_prefix dual_order.trans less_eq_list_def prefix_concat_minus self_append_conv2 zero_list_def)
  apply (metis append_minus list_append_prefixD order_refl trace_class.diff_zero)
done
    
end