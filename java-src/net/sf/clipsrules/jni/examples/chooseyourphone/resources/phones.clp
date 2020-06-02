(defmodule MAIN (export ?ALL))

;;*****************
;;* INITIAL STATE *
;;*****************

(deftemplate MAIN::attribute
   (slot name)
   (slot value)
   (slot certainty (default 100.0)))

(defrule MAIN::start
  (declare (salience 10000))
  =>
  (set-fact-duplication TRUE)
  (focus CHOOSE-QUALITIES PHONES))

(defrule MAIN::combine-certainties ""
  (declare (salience 100)
           (auto-focus TRUE))
  ?rem1 <- (attribute (name ?rel) (value ?val) (certainty ?per1))
  ?rem2 <- (attribute (name ?rel) (value ?val) (certainty ?per2))
  (test (neq ?rem1 ?rem2))
  =>
  (retract ?rem1)
  (modify ?rem2 (certainty (/ (- (* 100 (+ ?per1 ?per2)) (* ?per1 ?per2)) 100))))
  
 
;;******************
;; The RULES module
;;******************

(defmodule RULES (import MAIN ?ALL) (export ?ALL))

(deftemplate RULES::rule
  (slot certainty (default 100.0))
  (multislot if)
  (multislot then))

(defrule RULES::throw-away-ands-in-antecedent
  ?f <- (rule (if and $?rest))
  =>
  (modify ?f (if ?rest)))

(defrule RULES::throw-away-ands-in-consequent
  ?f <- (rule (then and $?rest))
  =>
  (modify ?f (then ?rest)))

(defrule RULES::remove-is-condition-when-satisfied
  ?f <- (rule (certainty ?c1) 
              (if ?attribute is ?value $?rest))
  (attribute (name ?attribute) 
             (value ?value) 
             (certainty ?c2))
  =>
  (modify ?f (certainty (min ?c1 ?c2)) (if ?rest)))

(defrule RULES::remove-is-not-condition-when-satisfied
  ?f <- (rule (certainty ?c1) 
              (if ?attribute is-not ?value $?rest))
  (attribute (name ?attribute) (value ~?value) (certainty ?c2))
  =>
  (modify ?f (certainty (min ?c1 ?c2)) (if ?rest)))

(defrule RULES::perform-rule-consequent-with-certainty
  ?f <- (rule (certainty ?c1) 
              (if) 
              (then ?attribute is ?value with certainty ?c2 $?rest))
  =>
  (modify ?f (then ?rest))
  (assert (attribute (name ?attribute) 
                     (value ?value)
                     (certainty (/ (* ?c1 ?c2) 100)))))

(defrule RULES::perform-rule-consequent-without-certainty
  ?f <- (rule (certainty ?c1)
              (if)
              (then ?attribute is ?value $?rest))
  (test (or (eq (length$ ?rest) 0)
            (neq (nth$ 1 ?rest) with)))
  =>
  (modify ?f (then ?rest))
  (assert (attribute (name ?attribute) (value ?value) (certainty ?c1))))

;;*******************************
;;* CHOOSE PHONE QUALITIES RULES *
;;*******************************

(defmodule CHOOSE-QUALITIES (import RULES ?ALL)
                            (import MAIN ?ALL))

(defrule CHOOSE-QUALITIES::startit => (focus RULES))

(deffacts the-phone-rules

  (rule (if preferred-system is android)
        (then best-system is android))
  (rule (if preferred-system is ios)
        (then best-system is ios))
  (rule (if preferred-system is unknown)
        (then best-system is android with certainty 20 and
               best-system is ios with certainty 20))

  (rule (if preferred-dual-sim is yes)
        (then best-dual-sim is yes))
  (rule (if preferred-dual-sim is no)
        (then best-dual-sim is no))
  (rule (if preferred-dual-sim is unknown)
        (then best-dual-sim is yes with certainty 20 and
               best-dual-sim is no with certainty 20))

  (rule (if preferred-screen-size is big)
        (then best-screen-size is big))
  (rule (if preferred-screen-size is small)
        (then best-screen-size is small))
  (rule (if preferred-screen-size is unknown)
        (then best-screen-size is big with certainty 20 and
                 best-screen-size is small with certainty 20))
)

;;************************
;;* PHONE SELECTION RULES *
;;************************

(defmodule PHONES (import MAIN ?ALL)
                 (export deffunction get-phone-list))

(deffacts any-attributes
  (attribute (name best-system) (value any))
  (attribute (name best-dual-sim) (value any))
  (attribute (name best-screen-size) (value any))
 )

(deftemplate PHONES::phone
  (slot name (default ?NONE))
  (multislot system (default any))
  (multislot dual-sim(default any))
  (multislot screen-size(default any))
  (multislot size(default any))
)


(deffacts PHONES::the-phone-list
    (phone (name "Xiaomi Redmi Note 8 Pro") (system android) (dual-sim yes) (screen-size 6.53))
    (phone (name "Samsung Galaxy A10") (system android) (dual-sim yes) (screen-size 6.2))
    (phone (name "Apple iPhone 6s") (system ios) (dual-sim no) (screen-size 4.7))
)

(defrule PHONES::generate-phones
  (phone (name ?name)
        (system $? ?c $?)
        (dual-sim $? ?s $?)
        (screen-size $? ?scr $?)
        (size $? ?si $?))


  (attribute (name best-system) (value ?c) (certainty ?certainty-1))
  (attribute (name best-dual-sim) (value ?s) (certainty ?certainty-2))
  (attribute (name best-screen-size) (value ?si) (certainty ?certainty-3))
  =>
  (assert (attribute (name phone) (value ?name)
                     (certainty (min ?certainty-1 ?certainty-2 ?certainty-3)))))

(deffunction PHONES::phone-sort (?w1 ?w2)
   (< (fact-slot-value ?w1 certainty)
      (fact-slot-value ?w2 certainty)))
      
(deffunction PHONES::get-phone-list ()
  (bind ?facts (find-all-facts ((?f attribute))
                              (and (eq ?f:name phone)
                              (>= ?f:certainty 0))))
  (sort phone-sort ?facts))
  

