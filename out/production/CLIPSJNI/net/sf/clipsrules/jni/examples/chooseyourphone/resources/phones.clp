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

  ; system
  (rule (if preferred-system is android)
        (then best-system is android))
  (rule (if preferred-system is ios)
        (then best-system is ios))
  (rule (if preferred-system is unknown)
        (then best-system is android with certainty 20 and
               best-system is ios with certainty 20))

  ; dual-sim
  (rule (if preferred-dual-sim is yes)
        (then best-dual-sim is yes))
  (rule (if preferred-dual-sim is no)
        (then best-dual-sim is no))
  (rule (if preferred-dual-sim is unknown)
        (then best-dual-sim is yes with certainty 20 and
               best-dual-sim is no with certainty 20))

  ; screen-size
  (rule (if preferred-screen-size is big)
        (then best-screen-size is big))
  (rule (if preferred-screen-size is small)
        (then best-screen-size is small))
  (rule (if preferred-screen-size is unknown)
        (then best-screen-size is big with certainty 20 and
                 best-screen-size is small with certainty 20))

  ; price
  (rule (if preferred-price is big)
          (then best-price is big))
  (rule (if preferred-price is medium)
          (then best-price is medium))
  (rule (if preferred-price is small)
          (then best-price is small))
  (rule (if preferred-price is unknown)
          (then best-price is small with certainty 20 and
                   best-price is medium with certainty 20 and
                   best-price is big with certainty 20))

  ; for gamers
  (rule (if preferred-games is yes)
        (then best-screen-size is big with certainty 80 and
              best-ram-size is big with certainty 70 and
              best-battery is big with certainty 80))
  (rule (if preferred-games is no)
          (then best-screen-size is big with certainty 1 and
                best-ram-size is big with certainty 1 and
                best-battery is big with certainty 1))


  ; for photos
  (rule (if preferred-photos is yes)
          (then best-front-camera is big with certainty 80 and
                best-back-camera is big with certainty 90 and
                best-memory-size is big with certainty 70))
  (rule (if preferred-photos is no)
            (then best-front-camera is big with certainty 20 and
                  best-front-camera is small with certainty 20 and
                  best-back-camera is big with certainty 20 and
                  best-back-camera is small with certainty 20))

  ; capacious battery
  (rule (if preferred-battery is yes)
            (then best-battery is big))
  (rule (if preferred-battery is no)
              (then best-battery is big with certainty 20 and
                    best-battery is small with certainty 20))

  ; difficult conditions
  (rule (if preferred-ip is yes)
              (then best-ip is yes))
  (rule (if preferred-ip is no)
                (then best-ip is none with certainty 40 and
                    best-ip is yes with certainty 20))

  ; multiple apps
  (rule (if preferred-multiple-apps is yes)
              (then best-memory-size is big with certainty 80 and
                    best-ram-size is big with certainty 60))
  (rule (if preferred-multiple-apps is no)
                (then best-ram-size is small with certainty 20 and
                      best-ram-size is big with certainty 20))

  ; big memory
  (rule (if preferred-big-memory is yes)
                (then best-memory-size is big))
  (rule (if preferred-big-memory is no)
                  (then best-memory-size is small with certainty 20 and
                  best-memory-size is big with certainty 20))

  ; for watching
  (rule (if preferred-movies is yes)
          (then best-screen-size is big with certainty 80 and
                best-memory-size is big with certainty 70 and
                best-battery is big with certainty 70))

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
  (attribute (name best-ram-size) (value any))
  (attribute (name best-front-camera) (value any))
  (attribute (name best-back-camera) (value any))
  (attribute (name best-memory-size) (value any))
  (attribute (name best-ip) (value any))
  (attribute (name best-battery) (value any))
)

(deftemplate PHONES::phone
  (slot name (default ?NONE))
  (multislot price (default any))
  (multislot price-final (default any))
  (multislot system (default any))
  (multislot dual-sim(default any))
  (multislot screen-size(default any))
  (multislot screen-size-final(default any))
  (multislot front-camera(default any))
  (multislot front-camera-final(default any))
  (multislot back-camera(default any))
  (multislot back-camera-final(default any))
  (multislot ram(default any))
  (multislot ram-final(default any))
  (multislot ip(default any))
  (multislot battery(default any))
  (multislot battery-final(default any))
  (multislot memory(default any))
  (multislot memory-final(default any))

)


(deffacts PHONES::the-phone-list
    (phone (name "Xiaomi Redmi Note 8 Pro") (price 999) (system android) (front-camera 20) (back-camera 64) (ram 6) (screen-size 6.53) (dual-sim yes) (ip yes) (battery 4500) (memory 64))
    (phone (name "Samsung Galaxy A10") (price 699) (system android) (front-camera 5) (back-camera 13) (ram 3) (screen-size 6.2) (dual-sim yes) (ip none) (battery 3400) (memory 32))
    (phone (name "Nokia 5.1 Plus") (price 599) (system android) (front-camera 8) (back-camera 13) (ram 3) (screen-size 4.8) (dual-sim yes) (ip none) (battery 3060) (memory 16))
    (phone (name "Cavion Base 5.0 LTE") (price 189) (system android) (front-camera 2) (back-camera 5) (ram 1) (screen-size 5.0) (dual-sim yes) (ip none) (battery 1950) (memory 8))
    (phone (name "Huawei Y5") (price 299) (system android) (front-camera 5) (back-camera 8) (ram 2) (screen-size 5.45) (dual-sim yes) (ip none) (battery 3020) (memory 16))
    (phone (name "Xiaomi Redmi 7A") (price 450) (system android) (front-camera 5) (back-camera 13) (ram 2) (screen-size 5.45) (dual-sim yes) (ip none) (battery 4000) (memory 16))
    (phone (name "Samsung Galaxy A40") (price 999) (system android) (front-camera 25) (back-camera 16) (ram 4) (screen-size 5.9) (dual-sim yes) (ip none) (battery 3100) (memory 64))
    (phone (name "LG Q60") (price 789) (system android) (front-camera 13) (back-camera 16) (ram 3) (screen-size 6.26) (dual-sim yes) (ip yes) (battery 3500) (memory 64))
    (phone (name "LG K40") (price 520) (system android) (front-camera 8) (back-camera 16) (ram 2) (screen-size 5.7) (dual-sim yes) (ip yes) (battery 3000) (memory 32))
    (phone (name "Honor 9X") (price 899) (system android) (front-camera 16) (back-camera 48) (ram 4) (screen-size 6.59) (dual-sim yes) (ip none) (battery 4000) (memory 64))
    (phone (name "Samsung Galaxy A50") (price 1399) (system android) (front-camera 25) (back-camera 25) (ram 4) (screen-size 6.4) (dual-sim yes) (ip none) (battery 4000) (memory 128))
    (phone (name "Motorola One Hyper") (price 1549) (system android) (front-camera 32) (back-camera 64) (ram 4) (screen-size 6.5) (dual-sim yes) (ip none) (battery 4000) (memory 128))
    (phone (name "Xiaomi Mi 9 Lite") (price 1499) (system android) (front-camera 32) (back-camera 48) (ram 6) (screen-size 6.21) (dual-sim yes) (ip none) (battery 4030) (memory 128))
    (phone (name "LG G8s ThinQ") (price 1899) (system android) (front-camera 8) (back-camera 12) (ram 6) (screen-size 6.21) (dual-sim no) (ip yes) (battery 3550) (memory 128))
    (phone (name "Samsung Galaxy J5") (price 1199) (system android) (front-camera 13) (back-camera 13) (ram 2) (screen-size 5.2) (dual-sim yes) (ip none) (battery 3000) (memory 16))
    (phone (name "Huawei P30 Lite") (price 1199) (system android) (front-camera 24) (back-camera 48) (ram 4) (screen-size 6.15) (dual-sim yes) (ip none) (battery 3340) (memory 128))
    (phone (name "Huawei P20") (price 1799) (system android) (front-camera 24) (back-camera 20) (ram 4) (screen-size 5.8) (dual-sim yes) (ip yes) (battery 3400) (memory 128))
    (phone (name "Apple iPhone 6s") (price 1399) (system ios) (front-camera 5) (back-camera 12) (ram 2) (screen-size 4.7) (dual-sim no) (ip none) (battery 1715) (memory 32))
    (phone (name "Apple iPhone 7") (price 1499) (system ios) (front-camera 7) (back-camera 12) (ram 2) (screen-size 4.7) (dual-sim no) (ip yes) (battery 1960) (memory 32))
    (phone (name "Xiaomi Mi 8") (price 1899) (system android) (front-camera 20) (back-camera 12) (ram 6) (screen-size 6.21) (dual-sim yes) (ip none) (battery 3400) (memory 128))
    (phone (name "Samsung Galaxy S10e") (price 3199) (system android) (front-camera 10) (back-camera 16) (ram 6) (screen-size 5.8) (dual-sim yes) (ip yes) (battery 3100) (memory 128))
    (phone (name "Sony Xperia XZ2 Compact") (price 2299) (system android) (front-camera 5) (back-camera 19) (ram 4) (screen-size 5.0) (dual-sim yes) (ip yes) (battery 2870) (memory 64))
    (phone (name "Asus ROG Phone") (price 2199) (system android) (front-camera 8) (back-camera 12) (ram 8) (screen-size 6.0) (dual-sim yes) (ip none) (battery 4000) (memory 128))
    (phone (name "Apple iPhone SE") (price 2499) (system ios) (front-camera 7) (back-camera 12) (ram 3) (screen-size 4.7) (dual-sim yes) (ip yes) (battery 1821) (memory 128))
    (phone (name "Apple iPhone XS") (price 3099) (system ios) (front-camera 7) (back-camera 12) (ram 4) (screen-size 5.8) (dual-sim yes) (ip yes) (battery 3300) (memory 64))
    (phone (name "Xiaomi Mi Note 10") (price 2099) (system android) (front-camera 32) (back-camera 108) (ram 6) (screen-size 6.47) (dual-sim yes) (ip none) (battery 5260) (memory 128))
    (phone (name "OnePlus 7T") (price 2499) (system android) (front-camera 16) (back-camera 48) (ram 8) (screen-size 6.55) (dual-sim yes) (ip none) (battery 3800) (memory 128))
    (phone (name "Huawei P30 Pro") (price 2799) (system android) (front-camera 32) (back-camera 40) (ram 8) (screen-size 6.47) (dual-sim yes) (ip yes) (battery 4200) (memory 128))
    (phone (name "Apple iPhone 11") (price 3499) (system ios) (front-camera 12) (back-camera 12) (ram 4) (screen-size 6.1) (dual-sim yes) (ip yes) (battery 3110) (memory 64))
    (phone (name "Huawei Mate 30 Pro") (price 2999) (system android) (front-camera 32) (back-camera 40) (ram 8) (screen-size 6.53) (dual-sim yes) (ip yes) (battery 4500) (memory 128))
)

(defrule PHONES::check-phones-screen
    ?ph <- (phone (name ?name)
            (screen-size $? ?scr $?))
     =>
     (if (> ?scr 5.9) then
           (modify ?ph (screen-size-final big))
     else (modify ?ph (screen-size-final small)))
)

(defrule PHONES::check-phones-price
    ?ph <- (phone (name ?name)
            (price $? ?price $?))
     =>
    (if (> ?price 1000) then
        (if (> ?price 2000) then
            (modify ?ph (price-final big))
        else (modify ?ph (price-final medium)))
    else (modify ?ph (price-final small)))
)

(defrule PHONES::check-battery-size
    ?ph <- (phone (name ?name)
            (battery $? ?bat $?))
     =>
     (if (> ?bat 3100) then
           (modify ?ph (battery-final big))
     else (modify ?ph (battery-final small)))
)

(defrule PHONES::check-ram-size
    ?ph <- (phone (name ?name)
            (ram $? ?r $?))
     =>
     (if (> ?r 3) then
           (modify ?ph (ram-final big))
     else (modify ?ph (ram-final small)))
)

(defrule PHONES::check-front-camera
    ?ph <- (phone (name ?name)
            (front-camera $? ?fc $?))
     =>
     (if (> ?fc 20) then
           (modify ?ph (front-camera-final big))
     else (modify ?ph (front-camera-final small)))
)

(defrule PHONES::check-back-camera
    ?ph <- (phone (name ?name)
            (back-camera $? ?bc $?))
     =>
     (if (> ?bc 20) then
           (modify ?ph (back-camera-final big))
     else (modify ?ph (back-camera-final small)))
)

(defrule PHONES::check-memory
    ?ph <- (phone (name ?name)
            (memory $? ?mem $?))
     =>
     (if (>= ?mem 32) then
           (modify ?ph (memory-final big))
     else (modify ?ph (memory-final small)))
)

(defrule PHONES::generate-phones
  (phone (name ?name)
        (price-final $? ?price-final $?)
        (system $? ?c $?)
        (dual-sim $? ?s $?)
        (ram $? ?r $?)
        (ram-final $? ?rf $?)
        (front-camera $? ?fc $?)
        (front-camera-final $? ?fcf $?)
        (back-camera $? ?bc $?)
        (back-camera-final $? ?bcf $?)
        (memory $? ?mem $?)
        (memory-final $? ?memf $?)
        (battery $? ?bat $?)
        (battery-final $? ?batf $?)
        (ip $? ?ip $?)
        (screen-size $? ?scr $?)
        (screen-size-final $? ?scrf $?)
  )
  (attribute (name best-price) (value ?price-final) (certainty ?certainty-1))
  (attribute (name best-system) (value ?c) (certainty ?certainty-2))
  (attribute (name best-dual-sim) (value ?s) (certainty ?certainty-3))
  (attribute (name best-ram-size) (value ?rf) (certainty ?certainty-4))
  (attribute (name best-front-camera) (value ?fcf) (certainty ?certainty-5))
  (attribute (name best-back-camera) (value ?bcf) (certainty ?certainty-6))
  (attribute (name best-memory-size) (value ?memf) (certainty ?certainty-7))
  (attribute (name best-battery) (value ?batf) (certainty ?certainty-8))
  (attribute (name best-ip) (value ?ip) (certainty ?certainty-9))
  (attribute (name best-screen-size) (value ?scrf) (certainty ?certainty-10))
  =>
  (assert (attribute (name phone) (value ?name)
                     (certainty (/ (+ (+ (+ (+ (+ (+ (+ (+ ( + ?certainty-1 ?certainty-2) ?certainty-3) ?certainty-4) ?certainty-5)
                     ?certainty-6) ?certainty-7) ?certainty-8) ?certainty-9) ?certainty-10) 10 ))))
)

(deffunction PHONES::phone-sort (?w1 ?w2)
   (< (fact-slot-value ?w1 certainty)
      (fact-slot-value ?w2 certainty)))

(deffunction PHONES::get-phone-list ()
  (bind ?facts (find-all-facts ((?f attribute))
                              (and (eq ?f:name phone)
                              (>= ?f:certainty 0))))
  (sort phone-sort ?facts))

