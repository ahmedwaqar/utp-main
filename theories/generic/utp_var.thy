(******************************************************************************)
(* Project: Mechanisation of the UTP                                          *)
(* File: utp/generic/utp_var.thy                                              *)
(* Author: Frank Zeyda, University of York                                    *)
(******************************************************************************)

header {* Variables *}

theory utp_var
imports utp_name
begin

types 'TYPE VAR = "NAME \<times> 'TYPE"

abbreviation var_name :: "'TYPE VAR \<Rightarrow> NAME" ("name") where
"var_name \<equiv> fst"

abbreviation var_type :: "'TYPE VAR \<Rightarrow> 'TYPE" ("type") where
"var_type \<equiv> snd"

subsection {* Locale @{term "VAR"} *}

locale VAR =
-- {* The type universe is fixed to determine @{typ "'TYPE"}. *}
  fixes var_type_univ :: "'TYPE set"
begin

subsection {* Constructors *}

definition MkVar :: "NAME \<Rightarrow> 'TYPE \<Rightarrow> 'TYPE VAR" where
"MkVar n t = (n, t)"

definition MkPlain :: "string \<Rightarrow> 'TYPE \<Rightarrow> 'TYPE VAR" where
"MkPlain s t = MkVar \<lparr>name_str = s, dashes = 0, subscript = NoSub\<rparr> t"

subsection {* Operators *}

definition dash :: "'TYPE VAR \<Rightarrow> 'TYPE VAR" where
"dash v = (
   \<lparr>name_str = name_str (name v),
   dashes = dashes (name v) + 1,
   subscript = subscript (name v)\<rparr>, type v)"

definition undash :: "'TYPE VAR \<Rightarrow> 'TYPE VAR" where
"undash v = (
   \<lparr>name_str = name_str (name v),
   dashes = dashes (name v) - 1,
   subscript = subscript (name v)\<rparr>, type v)"

subsection {* Restrictions *}

definition UNDASHED :: "'TYPE VAR set" where
"UNDASHED = {v . dashes (name v) = 0}"

definition DASHED :: "'TYPE VAR set" where
"DASHED = {v . dashes (name v) = 1}"

definition DASHED_TWICE :: "'TYPE VAR set" where
"DASHED_TWICE = {v . dashes (name v) = 2}"

definition PLAIN :: "'TYPE VAR set" where
"PLAIN = {v . v \<in> UNDASHED \<and> subscript (name v) = NoSub}"

subsection {* Properties *}

lemma inj_dash: "inj dash"
  apply(auto simp add:inj_on_def dash_def)
  apply(case_tac x)
  apply(case_tac y)
  apply(simp)
done

lemma inj_dashed_undash: "inj_on undash DASHED"
  apply(auto simp add:inj_on_def undash_def DASHED_def)
  apply(case_tac x)
  apply(case_tac y)
  apply(simp)
done

lemma inj_dashed2_undash: "inj_on undash DASHED_TWICE"  
  apply(auto simp add:inj_on_def undash_def DASHED_TWICE_def)
  apply(case_tac x)
  apply(case_tac y)
  apply(simp)
done

end
end
