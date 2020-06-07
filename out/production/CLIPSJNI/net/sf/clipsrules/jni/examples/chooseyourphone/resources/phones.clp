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

  (rule (if preferred-price is big)
          (then best-price is big))
  (rule (if preferred-price is medium)
          (then best-price is medium))
  (rule (if preferred-price is low)
          (then best-price is low))
  (rule (if preferred-price is unknown)
          (then best-price is low with certainty 20 and
                   best-price is medium with certainty 20 and
                   best-price is high with certainty 20))
)

;;************************
;;* PHONE SELECTION RULES *
;;************************

(defmodule PHONES (import MAIN ?ALL)
                 (export deffunction get-phone-list))

(deffacts any-attributes
  (attribute (name best-price) (value any))
  (attribute (name best-system) (value any))
  (attribute (name best-dual-sim) (value any))
  (attribute (name best-screen-size) (value any))
)

(deftemplate PHONES::phone
  (slot name (default ?NONE))
  (multislot price (default any))
  (multislot price-final (default any))
  (multislot system (default any))
  (multislot dual-sim(default any))
  (multislot screen-size(default any))
  (multislot size(default any))
  (multislot front-camera(default any))
  (multislot back-camera(default any))
  (multislot ram(default any))
  (multislot ip(default any))
  (multislot battery(default any))
  (multislot memory(default any))

)


(deffacts PHONES::the-phone-list
    (phone (name "Xiaomi Redmi Note 8 Pro") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Samsung Galaxy A10") (price 699) (system android) (front-camera 5) (back-camera 13) (ram 3) (screen-size 6.2) (dual-sim yes) (ip none) (battery 3400) (memory 32))
    (phone (name "Nokia 5.1 Plus") (price 599) (system android) (front-camera 8) (back-camera 13) (ram 3) (screen-size 5.8) (dual-sim yes) (ip none) (battery 3060) (memory 16))
    (phone (name "Cavion Base 5.0 LTE") (price 189) (system android) (front-camera 2) (back-camera 5) (ram 1) (screen-size 5.0) (dual-sim yes) (ip none) (battery 1950) (memory 8))
    (phone (name "Huawei Y5") (price 299) (system android) (front-camera 5) (back-camera 8) (ram 2) (screen-size 5.45) (dual-sim yes) (ip none) (battery 3020) (memory 16))
    (phone (name "Xiaomi Redmi 7A") (price 450) (system android) (front-camera 5) (back-camera 13) (ram 2) (screen-size 5.45) (dual-sim yes) (ip none) (battery 4000) (memory 16))
    (phone (name "Samsung Galaxy A40") (price 999) (system android) (front-camera 25) (back-camera 16) (ram 4) (screen-size 5.9) (dual-sim yes) (ip none) (battery 3100) (memory 64))
    (phone (name "LG Q60") (price 789) (system android) (front-camera 13) (back-camera 16) (ram 3) (screen-size 6.26) (dual-sim yes) (ip MIL-STD-810G) (battery 3500) (memory 64))
    (phone (name "LG K40") (price 520) (system android) (front-camera 8) (back-camera 16) (ram 2) (screen-size 5.7) (dual-sim yes) (ip MIL-STD-810G) (battery 3000) (memory 32))
    (phone (name "Honor 9X") (price 899) (system android) (front-camera 16) (back-camera 48) (ram 4) (screen-size 6.59) (dual-sim yes) (ip none) (battery 4000) (memory 64))
    (phone (name "Samsung Galaxy A50") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Motorola One Hyper") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Xiaomi Mi 9 Lite") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "LG G8s ThinQ") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Samsung Galaxy J5") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Huawei P30 Lite") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Huawei P20") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Apple iPhone 6s") (price 999) (system ios) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Apple iPhone 7") (price 999) (system ios) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Xiaomi Mi 8") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Samsung Galaxy S10e") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Sony Xperia XZ2 Compact") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Asus ROG Phone") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Apple iPhone SE") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Apple iPhone XS") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Xiaomi Mi Note 10") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "OnePlus 7T") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Huawei P30 Pro") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Apple iPhone 11") (price 999) (system ios) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))
    (phone (name "Huawei Mate 30 Pro") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 64) (screen-size 6.53) (dual-sim yes) (ip IP52) (battery 4500) (memory 64))

)

(defrule PHONES::check-phones-screen
    ?ph <- (phone (name ?name)
            (screen-size $? ?scr $?)
            (size $? ?ss $?))
     =>
     (if (> ?scr 5) then
           (modify ?ph (size big))
     else (modify ?ph (size small)))
)

(defrule PHONES::check-phones-price
    ?ph <- (phone (name ?name)
            (price $? ?price $?)
            (price-final $? ?price-final $?))
     =>
    (if (> ?price 1000) then
        (if (> ?price 2000) then
            (modify ?ph (price-final high))
        else (modify ?ph (price-final medium)))
    else (modify ?ph (price-final low)))
)
(defrule PHONES::generate-phones
  (phone (name ?name)
        (price-final $? ?price-final $?)
        (system $? ?c $?)
        (dual-sim $? ?s $?)
        (size $? ?scr $?))
  (attribute (name best-price) (value ?price-final) (certainty ?certainty-1))
  (attribute (name best-system) (value ?c) (certainty ?certainty-2))
  (attribute (name best-dual-sim) (value ?s) (certainty ?certainty-3))
  (attribute (name best-screen-size) (value ?scr) (certainty ?certainty-4))
  =>
  (assert (attribute (name phone) (value ?name)
                     (certainty (min ?certainty-1 ?certainty-2 ?certainty-3 ?certainty-4))))
)

(deffunction PHONES::phone-sort (?w1 ?w2)
   (< (fact-slot-value ?w1 certainty)
      (fact-slot-value ?w2 certainty)))

(deffunction PHONES::get-phone-list ()
  (bind ?facts (find-all-facts ((?f attribute))
                              (and (eq ?f:name phone)
                              (>= ?f:certainty 0))))
  (sort phone-sort ?facts))

