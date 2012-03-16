theory utp_typed_pred
imports "../utp_sorts" utp_gen_pred utp_gen_eval utp_complex_value
begin

section {* Typed Predicates *}

subsection {* Well-typed Bindings *}

definition WT_BINDING :
"WT_BINDING type_rel = {b . (\<forall> v . type_rel (b v) (VAR.var_type v))}"

subsection {* Standard Locale *}

locale TYPED_PRED =
  COMPLEX_VALUE "base_type_rel" "base_value_ref" +
  GEN_PRED "WT_BINDING (lift_type_rel_complex base_type_rel)"
for base_type_rel :: "'BASE_VALUE :: BASIC_SORT \<Rightarrow> 'BASE_TYPE \<Rightarrow> bool" and
  base_value_ref :: "'BASE_VALUE :: BASIC_SORT \<Rightarrow> 'BASE_VALUE \<Rightarrow> bool"

subsection {* Theorems *}

theorem WT_BINDING_non_empty [intro!, simp] :
"VALUE type_rel \<Longrightarrow>
 WT_BINDING type_rel \<noteq> {}"
apply (simp add: WT_BINDING)
apply (rule_tac x = "(\<lambda> v . (SOME x . type_rel x (snd v)))" in exI)
apply (clarify)
apply (drule_tac t = "snd v" in VALUE.type_non_empty)
apply (clarify)
apply (rule_tac a = "x" in someI2)
apply (assumption)+
done

theorem WT_BINDING_override [intro!, simp] :
"\<lbrakk>b1 \<in> WT_BINDING type_rel;
 b2 \<in> WT_BINDING type_rel\<rbrakk> \<Longrightarrow>
 (b1 \<oplus> b2 on a) \<in> WT_BINDING type_rel"
apply (simp add: WT_BINDING)
apply (clarify)
apply (case_tac "v \<in> a")
apply (auto)
done

text {* The following theorem facilitates interpretation proofs. *}

theorem TYPED_PRED_inst [intro!, simp] :
"VALUE base_type_rel \<Longrightarrow>
 TYPED_PRED base_type_rel"
apply (simp add: TYPED_PRED_def)
apply (simp add: GEN_PRED_def)
apply (auto)
done
end
