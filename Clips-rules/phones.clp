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
  (focus CHOOSE-QUALITIES WINES))

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

(deffacts the-wine-rules

  ; Rules for picking the best body

  (rule (if preffered_system is android)
        (then best-system is android))

  (rule (if preffered_dual-sim is yes)
        (then best-dual-sim is yes))
)

(defmodule PHONES (import MAIN ?ALL)
                 (export deffunction get-phone-list))

(deftemplate PHONES::phone
  (slot name (default ?NONE))
  (multislot camera_back (default any))
  (multislot camera_front (default any))
  (multislot system (default any))
  (multislot price(default any))
  (multislot ram (default any))
  (multislot screen_size (default any))
  (multislot memory(default any))
  (multislot baterry(default any))
  (multislot dual-sim(default any))
  )

(deffacts PHONES::the-phone-list 
  (phone (name "Xiaomi Redmi Note 8 Pro") (camera_back 64) (camera_front 20) (system android) (screen_size 6.53) (dual-sim 1)
  (baterry 4500) (memory 128) (price 999) (ram 64))
  (phone (name "Samsung Galaxy A10") (camera_back 13) (camera_front 5) (system android) (screen_size 6.2) (dual-sim 1)
  (baterry 3400) (memory 32) (price 699) (ram 3))
)
  
(defrule PHONES::generate-phones
  (phone (name ?name)
        (camera_back $? ?cb $?) 
        (camera_front $? ?cf $?) 
        (system $? ?sys $?) 
        (screen_size $? ?size $?) 
        (dual-sim $? ?ds $?)
        (baterry $? ?bat $?) 
        (memory $? ?mem $?) 
        (price $? ?pr $?) 
        (ram $? ?ram $?))
  (attribute (name best-camera_back) (value ?cb) (certainty ?certainty-1))
  (attribute (name best-camera_front) (value ?cf) (certainty ?certainty-2))
  (attribute (name best-system) (value ?sys) (certainty ?certainty-3))
  (attribute (name best-screen_size) (value ?size) (certainty ?certainty-4))
  (attribute (name best-dual-sim) (value ?ds) (certainty ?certainty-5))
  (attribute (name best-baterru) (value ?bat) (certainty ?certainty-6))
  (attribute (name best-memory) (value ?mem) (certainty ?certainty-7))
  (attribute (name best-price) (value ?pr) (certainty ?certainty-8))
  (attribute (name best-ram) (value ?ram) (certainty ?certainty-9))
  =>
  (assert (attribute (name phone) (value ?name)
                     (certainty (min ?certainty-1 ?certainty-2 ?certainty-3 ?certainty-4 ?certainty-5 ?certainty-6 ?certainty-7 ?certainty-8
                     ?certainty-9)))))

(deffunction PHONES::phone-sort (?w1 ?w2)
   (< (fact-slot-value ?w1 certainty)
      (fact-slot-value ?w2 certainty)))
      
(deffunction PHONES::get-phone-list ()
  (bind ?facts (find-all-facts ((?f attribute))
                               (and (eq ?f:name phone)
                                    (>= ?f:certainty 20))))
  (sort phone-sort ?facts))