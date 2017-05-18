section {* Mini-mondex example *}

theory utp_csp_mini_mondex
  imports "../theories/utp_csp"
begin

text {* This example is a modified version of the Mini-Mondex card example taken from the 2014
  paper "Contracts in CML" by Woodcock et al. *}
  
subsection {* Types and Statespace *}
  
type_synonym index = nat -- {* Card identifiers *}
type_synonym money = int -- {* Monetary amounts. *}

text {* In the paper money is represented as a nat, here we use an int so that we have the option
  of modelling negative balances. This also eases proof as integers form an algebraic ring. *}
  
alphabet st_mdx =
  valueseq :: "money list" -- {* Index record of each card's balance *}
  
datatype ch_mdx = 
  pay "index \<times> index \<times> money" | -- {* Request a payment between two cards *}
  transfer "index \<times> index \<times> money" | -- {* Effect the transfer *}
  accept index | -- {* Accept the payment *}
  reject index -- {* Reject it *}
  
type_synonym action_mdx = "(st_mdx, ch_mdx) action"
  
subsection {* Actions *}
  
text {* The Pay action describes the protocol when a payment of $n$ is requested between two cards,
  $i$ and $j$. It is slightly modified from the paper, as we firstly do not use operations but effect
  the transfer using indexed assignments directly, and secondly because before the transfer can proceed
  we need to check the balance is both sufficient, and that the transfer amount is greater than 0. It
  should also be noted that the indexed assignments give rise to preconditions that the list is
  defined at the given index. In other words, the given card records must be present. *}
  
definition Pay :: "index \<Rightarrow> index \<Rightarrow> money \<Rightarrow> action_mdx" where
"Pay i j n = 
  pay.(\<guillemotleft>i\<guillemotright>).(\<guillemotleft>j\<guillemotright>).(\<guillemotleft>n\<guillemotright>) \<^bold>\<rightarrow> 
    ((reject.(\<guillemotleft>i\<guillemotright>) \<^bold>\<rightarrow> Skip) 
      \<triangleleft> \<guillemotleft>n\<guillemotright> \<le>\<^sub>u 0 \<or> \<guillemotleft>n\<guillemotright> >\<^sub>u &valueseq\<lparr>\<guillemotleft>i\<guillemotright>\<rparr>\<^sub>u \<triangleright>\<^sub>R 
    ({valueseq[\<guillemotleft>i\<guillemotright>]} :=\<^sub>C (&valueseq\<lparr>\<guillemotleft>i\<guillemotright>\<rparr>\<^sub>u - \<guillemotleft>n\<guillemotright>) ;;
     {valueseq[\<guillemotleft>j\<guillemotright>]} :=\<^sub>C (&valueseq\<lparr>\<guillemotleft>j\<guillemotright>\<rparr>\<^sub>u + \<guillemotleft>n\<guillemotright>) ;;
     accept.(\<guillemotleft>i\<guillemotright>) \<^bold>\<rightarrow> Skip))"
    
text {* The Cycle action just repeats the payments over and over for any extant and different card
  indices. *}

definition Cycle :: "index \<Rightarrow> action_mdx" where
"Cycle cardNum = (\<mu> X \<bullet> (\<Sqinter> (i, j, n) | \<guillemotleft>i\<guillemotright> <\<^sub>u \<guillemotleft>cardNum\<guillemotright> \<and> \<guillemotleft>j\<guillemotright> <\<^sub>u \<guillemotleft>cardNum\<guillemotright> \<and> \<guillemotleft>i\<guillemotright> \<noteq>\<^sub>u \<guillemotleft>j\<guillemotright> \<bullet> Pay i j n) ;; X)"

text {* The Mondex action is a sample setup. It requires creates $cardNum$ cards each with 100 units
  present. *}

definition Mondex :: "index \<Rightarrow> action_mdx" where
"Mondex(cardNum) = (valueseq :=\<^sub>C \<guillemotleft>replicate cardNum 100\<guillemotright> ;; Cycle(cardNum))"

subsection {* Pre/peri/post calculations *}

lemma Pay_CSP [closure]: "Pay i j n is CSP"
  by (simp add: Pay_def closure)
 
text {* The precondition of pay requires that, under the assumption that a payment was requested
  by the environment (pay is present at the trace head), and that the given amount can be honoured by
  the sending card, then the two cards must exist. This arises directly from the indexed assignment
  preconditions. *}
  
lemma preR_Pay [rdes]:
  "pre\<^sub>R(Pay i j n) = 
    ($tr ^\<^sub>u \<langle>(pay\<cdot>\<guillemotleft>(i, j, n)\<guillemotright>)\<^sub>u\<rangle> \<le>\<^sub>u $tr\<acute> \<and> 0 <\<^sub>u \<guillemotleft>n\<guillemotright> \<and> \<guillemotleft>n\<guillemotright> \<le>\<^sub>u $st:valueseq\<lparr>\<guillemotleft>i\<guillemotright>\<rparr>\<^sub>u \<Rightarrow> {\<guillemotleft>i\<guillemotright>,\<guillemotleft>j\<guillemotright>}\<^sub>u \<subseteq>\<^sub>u dom\<^sub>u($st:valueseq))"
  apply (simp add: Pay_def closure rdes unrest alpha usubst wp)
  apply (rel_auto) using dual_order.trans by blast
 
text {* The pericondition has three cases: (1) nothing has happened and we are not refusing the
  payment request, (2) the payment request happened, but there isn't enough (or non-positive) money
  and reject is being offered, or (3) there was enough money and accept is being offered. *}
    
lemma periR_Pay [rdes]:
  "peri\<^sub>R(Pay i j n) = 
    (pre\<^sub>R(Pay i j n) \<Rightarrow> $tr\<acute> =\<^sub>u $tr \<and> (pay\<cdot>\<guillemotleft>(i, j, n)\<guillemotright>)\<^sub>u \<notin>\<^sub>u $ref\<acute>
                     \<or> $tr\<acute> =\<^sub>u $tr ^\<^sub>u \<langle>(pay\<cdot>\<guillemotleft>(i, j, n)\<guillemotright>)\<^sub>u\<rangle> \<and> (\<guillemotleft>n\<guillemotright> \<le>\<^sub>u 0 \<or> \<guillemotleft>n\<guillemotright> >\<^sub>u $st:valueseq\<lparr>\<guillemotleft>i\<guillemotright>\<rparr>\<^sub>u) \<and> (reject\<cdot>\<guillemotleft>i\<guillemotright>)\<^sub>u \<notin>\<^sub>u $ref\<acute>
                     \<or> $tr\<acute> =\<^sub>u $tr ^\<^sub>u \<langle>(pay\<cdot>\<guillemotleft>(i, j, n)\<guillemotright>)\<^sub>u\<rangle> \<and> 0 <\<^sub>u \<guillemotleft>n\<guillemotright> \<and> \<guillemotleft>n\<guillemotright> \<le>\<^sub>u $st:valueseq\<lparr>\<guillemotleft>i\<guillemotright>\<rparr>\<^sub>u \<and> (accept\<cdot>\<guillemotleft>i\<guillemotright>)\<^sub>u \<notin>\<^sub>u $ref\<acute>)"
  by (simp add: Pay_def closure rdes unrest alpha usubst wp, rel_auto)
    
text {* The postcondition has two options. Firstly, the amount was wrong, and so the trace was extended
  by both pay and reject, with the state remaining unchanged. Secondly, the payment was fine and so
  the trace was extended by pay and accept, and the states of the two cards was updated appropriately. *}
    
lemma postR_Pay [rdes]:
  "i \<noteq> j \<Longrightarrow> 
   post\<^sub>R(Pay i j n) = 
    (pre\<^sub>R(Pay i j n) \<Rightarrow> $tr\<acute> =\<^sub>u $tr ^\<^sub>u \<langle>(pay\<cdot>\<guillemotleft>(i, j, n)\<guillemotright>)\<^sub>u,(reject\<cdot>\<guillemotleft>i\<guillemotright>)\<^sub>u\<rangle> \<and> (\<guillemotleft>n\<guillemotright> \<le>\<^sub>u 0 \<or> \<guillemotleft>n\<guillemotright> >\<^sub>u $st:valueseq\<lparr>\<guillemotleft>i\<guillemotright>\<rparr>\<^sub>u) \<and> $st\<acute> =\<^sub>u $st
                     \<or> $tr\<acute> =\<^sub>u $tr ^\<^sub>u \<langle>(pay\<cdot>\<guillemotleft>(i, j, n)\<guillemotright>)\<^sub>u,(accept\<cdot>\<guillemotleft>i\<guillemotright>)\<^sub>u\<rangle> \<and> 0 <\<^sub>u \<guillemotleft>n\<guillemotright> \<and> \<guillemotleft>n\<guillemotright> \<le>\<^sub>u $st:valueseq\<lparr>\<guillemotleft>i\<guillemotright>\<rparr>\<^sub>u 
                       \<and> \<lceil>valueseq := &valueseq(\<guillemotleft>i\<guillemotright> \<mapsto> &valueseq\<lparr>\<guillemotleft>i\<guillemotright>\<rparr>\<^sub>u - \<guillemotleft>n\<guillemotright>, \<guillemotleft>j\<guillemotright> \<mapsto> &valueseq\<lparr>\<guillemotleft>j\<guillemotright>\<rparr>\<^sub>u + \<guillemotleft>n\<guillemotright>)\<^sub>u\<rceil>\<^sub>S)"
  by (simp add: Pay_def closure rdes unrest alpha usubst wp, rel_simp, safe, simp_all, blast+)    

subsection {* Verification *}

text {* We first show that any payment leaves the total value shared between the cards unchanged.
  This is under the assumption that at least two cards exist. The contract has as its precondition
  that initially the number of cards is $cardNum$. The pericondition is $true$ as we don't
  care about intermediate behaviour here. The postcondition has that the summation of the 
  sequence of card values remains the same, though of course individual records will change. *}
  
theorem money_constant:
  assumes "i < cardNum" "j < cardNum" "i \<noteq> j"
  shows "[#\<^sub>u(&valueseq) =\<^sub>u \<guillemotleft>cardNum\<guillemotright> \<turnstile> true | sum\<^sub>u($valueseq) =\<^sub>u sum\<^sub>u($valueseq\<acute>)]\<^sub>R \<sqsubseteq> Pay i j n"
-- {* We first apply the reactive design contract introduction law and discharge well-formedness of Pay *}
proof (rule RD_contract_refine, simp add: closure)

  -- {* Three proof obligations result for the pre/peri/postconditions. The first requires us to
    show that the contract's precondition is weakened by the implementation precondition. 
    It is because the implementation's precondition is under the assumption of receiving an
    input and the money amount constraints. We discharge by first calculating the precondition, 
    as done above, and then using the relational calculus tactic. *}

  from assms show "`\<lceil>#\<^sub>u(&valueseq) =\<^sub>u \<guillemotleft>cardNum\<guillemotright>\<rceil>\<^sub>S\<^sub>< \<Rightarrow> pre\<^sub>R (Pay i j n)`"
    by (rdes_calc, rel_auto)

  -- {* The second is trivial as we don't care about intermediate states. *}
      
  show "`\<lceil>#\<^sub>u(&valueseq) =\<^sub>u \<guillemotleft>cardNum\<guillemotright>\<rceil>\<^sub>S\<^sub>< \<and> peri\<^sub>R (Pay i j n) \<Rightarrow> \<lceil>true\<rceil>\<^sub>S\<^sub><\<lbrakk>x\<rightarrow>tt\<rbrakk>`"
    by rel_auto

  -- {* The third requires that we show that the postcondition implies that the total amount remains
    unaltered. We calculate the postcondition, and then use relational calculus. In this case, this
    is not enough and an additional property of lists is required (@{thm listsum_update}) that can
    be retrieved by sledgehammer. However, we actually had to prove that property first and add it to our library. *}
      
  from assms
  show " `\<lceil>#\<^sub>u(&valueseq) =\<^sub>u \<guillemotleft>cardNum\<guillemotright>\<rceil>\<^sub>S\<^sub>< \<and> post\<^sub>R (Pay i j n) \<Rightarrow> \<lceil>sum\<^sub>u($valueseq) =\<^sub>u sum\<^sub>u($valueseq\<acute>)\<rceil>\<^sub>S\<lbrakk>x\<rightarrow>tt\<rbrakk>`"
    by (rdes_calc, rel_auto, simp add: listsum_update)
qed

text {* The next property is that no card value can go below 0, assuming it was non-zero to start
  with. *}
  
theorem no_overdrafts:
  assumes "i < cardNum" "j < cardNum" "i \<noteq> j"
  shows "[#\<^sub>u(&valueseq) =\<^sub>u \<guillemotleft>cardNum\<guillemotright> \<turnstile> true | (\<^bold>\<forall> k \<bullet> \<guillemotleft>k\<guillemotright> <\<^sub>u \<guillemotleft>cardNum\<guillemotright> \<and> $valueseq\<lparr>\<guillemotleft>k\<guillemotright>\<rparr>\<^sub>u \<ge>\<^sub>u 0 \<Rightarrow> $valueseq\<acute>\<lparr>\<guillemotleft>k\<guillemotright>\<rparr>\<^sub>u \<ge>\<^sub>u 0)]\<^sub>R \<sqsubseteq> Pay i j n"
  apply (rule RD_contract_refine)
  apply (simp add: Pay_def closure)
  apply (simp add: rdes)
  using assms
  apply (rel_auto)
  apply (simp add: usubst alpha rdes)
  apply (simp add: usubst alpha rdes)
  apply (simp add: rdes assms usubst)
  using assms apply (rel_auto)
  apply (auto simp add: nth_list_update)
done
  
text {* The next property shows liveness of transfers. If a payment is accepted, and we have enough
  money, then the acceptance of the transfer cannot be refused. Unlike the previous two examples,
  this is specified using the pericondition as we are talking about intermediate states and refusals. *}
  
theorem transfer_live:
  assumes "i < cardNum" "j < cardNum" "i \<noteq> j" "n > 0"
  shows "[#\<^sub>u(&valueseq) =\<^sub>u \<guillemotleft>cardNum\<guillemotright> 
         \<turnstile> \<guillemotleft>trace\<guillemotright> \<noteq>\<^sub>u \<langle>\<rangle> \<and> last\<^sub>u(\<guillemotleft>trace\<guillemotright>) =\<^sub>u (pay\<cdot>(\<guillemotleft>(i,j,k)\<guillemotright>))\<^sub>u \<and> \<guillemotleft>n\<guillemotright> \<le>\<^sub>u &valueseq\<lparr>\<guillemotleft>i\<guillemotright>\<rparr>\<^sub>u \<Rightarrow> (accept\<cdot>(\<guillemotleft>(i)\<guillemotright>))\<^sub>u \<notin>\<^sub>u \<guillemotleft>refs\<guillemotright>
         | true]\<^sub>C \<sqsubseteq> Pay i j n"
  apply (rule_tac CRD_contract_refine)
  apply (simp add: Pay_def closure)
  apply (simp add: rdes)
  using assms apply (rel_auto)
  apply (simp add: rdes)    
  using assms apply (rel_auto)
  apply (simp add: zero_list_def)
  apply (rel_auto)
done
    
end