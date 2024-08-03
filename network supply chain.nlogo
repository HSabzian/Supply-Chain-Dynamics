breed [ players player]
breed [ Drs  Dr]
breed [ patients patient]
breed [ visitors visitor]

globals [ demand-today colors]

directed-link-breed [demand-links demand-link]
demand-links-own [ orders-placed back-orders]

directed-link-breed [supply-links supply-link]
supply-links-own [ orders-filled pair-demand-link]

directed-link-breed [enduser-links enduser-link]


players-own [

role
id-number

pen-color
base-stock
on-hand  ;; stock in the inventory
backlog   ;; orders that have not been satisfied
inventory-position  ;; status of inventory ( on-hand + pipeline - backlog)
cost
demand-history
revenue
safety-factor  ;; parameter determining to what extent the player want to keep safety inventory against demand uncertainty

last-received
current-supplier
]

DrS-own [
id-number
]

patients-own
[
id-number
]


visitors-own [
  role
]


to setup
ca
random-seed seed
ask patches [ set pcolor white]
set-default-shape links "arc"
set colors (sentence (range 5 145 5) 67 117 28 18 37) ;; 33 items as limiters of number of distributers and retailers
set colors shuffle colors

if on-click-setup? [

layout-supplier
layout-distributer
layout-retailer
layout-doctors
layout-patients

set-demand-link
set-supply-link

initialize
resize-shape
reset-plots
  ]
reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Players

to layout-supplier
let index 0
create-players num-of-suppliers [
set color item index [red gray blue]
set index index + 1
if color = red [ setxy -40 0   set role "supplier" set size 5 set shape "dist0"]
if color = gray [ setxy -40 5  set role "supplier" set size 5 set shape "dist0"]
if color = blue [ setxy -40 10  set role "supplier" set size 5 set shape "dist0"]

]
end

to layout-distributer
   ask patches with [ pxcor = -15 and ( member? pycor y-locations num-of-distributers) ][
    sprout-players 1 [ set color blue set role "distributer" set size 2 set shape "dist1"]
  ]
  ;  assign id-number for each distributer
   let d-number 1
  foreach sort players with [ role = "distributer"] [ i -> ask i [
       set label word "D-" d-number
       set id-number d-number
       set d-number d-number + 1
    ]
  ]
end

to layout-retailer

  ask patches with [ pxcor = 10  and ( member? pycor y-locations num-of-retailers) ][
    sprout-players 1 [ set color gray set role "retailer" set size 1 set shape "dist2"]
  ]
    ;; assign id-number for each retailer
   let r-number 1
   foreach sort players with [ role = "retailer"] [ i -> ask i [
   set label word "R-" r-number
   set id-number r-number
   set r-number r-number + 1
   ]
   ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Doctors
to layout-doctors

  ask patches with [ pxcor = 47  and ( member? pycor y-locations num-of-doctors) ][
    sprout-Drs 1 [ set color one-of colors  set size 2 set shape "house"]
  ]
     ;; assign id-number for each end-user
   let dr-number 1
   foreach sort Drs [ i -> ask i [
  set label word "dr-" dr-number set label-color white
   set id-number dr-number
   set dr-number dr-number + 1
   ]
   ]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;patients
to layout-patients

  ask patches with [ pxcor = one-of [30 31 32 33]  and ( member? pycor y-locations num-of-patients) ][
    sprout-patients 1 [ set color violet  set size 1.5 set shape "person"

      let target one-of Drs
      if target != nobody [ set heading towards target]
      show target
    ]
  ]
    ;; assign id-number for each end-user
let eu-number 1
   foreach sort patients [ i -> ask i [
   ;;set label word "P-" eu-number
   set id-number eu-number
   set eu-number eu-number + 1
   ]
   ]

end



to-report y-locations [number]
  let y-list []

  let interval round ((2 * (max-pycor - 3) + 1) / (number + 1))

  let current-pos (- max-pycor + 3 + interval)

  repeat number [
    set y-list lput current-pos y-list
    set current-pos current-pos + interval
  ]
  report y-list
end



to set-demand-link

   ask players with [ role = "distributer" ] [
    create-demand-links-to players with [role = "supplier"] [ set color orange ]      ;; upstream demand links

  ]


  ask players with [ role = "retailer" ] [
 create-demand-links-to players with [role = "distributer"] [ set color orange]  ;; upstream demand links
  ]


;  ]

end

to set-supply-link

   ask players with [ role = "distributer" ] [
    create-supply-links-from players with [role = "supplier"] [ set color green]  ;; downstream supply links

  ]

  ask players with [ role = "retailer" ] [
 create-supply-links-from players with [role = "distributer"] [ set color green]  ;; downstream supply links
  ]



 ;;Pair demand links

ask supply-links [ set pair-demand-link demand-links with [ end1 = [end2] of myself and end2 = [end1] of myself] ]
end


to initialize   ;;; Pen-color, on-hand, base-stock, orders-placed, back-orders, orders-filled, backlog, inventory-position, cost, revenue, safety-factors, demand-history

;;;;; assigning different plot pen color to each distributer and retailer

let index 0
 foreach sort players with [ role = "distributer" or role = "retailer"] [ i -> ask i  [ set pen-color item index colors set index index + 1 ] ]


  ask players [

    if role = "supplier" [ set on-hand 10000 ]

    if role = "distributer" [
                 set base-stock initial-stock-distributer                             ;;; BASE-STOCK
                 set on-hand initial-stock-distributer                                ;;; ON-HAND

                 ask my-out-demand-links [ set orders-placed 0 set back-orders 0  ]     ;;;;;;;;;;ORDERS-PLACES & BACK-ORDERS

                 ask my-in-supply-links [ set orders-filled n-values lead-time-supplier-to-distributer [0]  ]   ;;;ORDERS-FILLED
    ]

   if role = "retailer" [
                 set base-stock initial-stock-retailer                             ;;;; BASE-STOCK
                 set on-hand initial-stock-retailer                                ;;;; ON-HAND

                 ask my-out-demand-links [ set orders-placed 0 set back-orders 0  ]    ;;;;;;;;;;ORDERS-PLACES & BACK-ORDERS

                 ask my-in-supply-links [ set orders-filled n-values lead-time-distributer-to-retailer [0]  ]   ;;;ORDERS-FILLED
    ]

              set backlog 0                                                           ;;;;; BACKLOG
              set inventory-position on-hand - backlog                                ;;;; INVENTORY-POSITION
              set cost 0                                                              ;;;; COST
              set revenue 0                                                           ;;;; REVENUE
              set safety-factor 1.5 + random-float 1                                  ;;; ;; the higher safety factor  means that the player is willing to keep higher safety inventory against the demand uncertainty
              set demand-history n-values record-length [""]                          ;;;; set the demand history as a list with empty elements, with the length equals to "record-length"
  ]


end

to resize-shape

  ask players with [ role = "distributer" or role = "retailer"]
  [ set size 0.5 * (sqrt on-hand)]

end

  ;;;; for plotting

to reset-plots
  clear-all-plots
  ;;;;;;;;;;;;;;;;;;; For individuals
  ask players with [ role = "distributer" or role = "retailer"] [
    create-plot-pens
  ]
  ;;;;;;;;;;;;;;;;;; For whole
  plot-whole
end

to create-plot-pens
  create-plot-pen "total profit of each player"
  create-plot-pen "on-hand inventory of each player"
end

to create-plot-pen [my-plot]
  set-current-plot my-plot
  create-temporary-plot-pen label
  set-plot-pen-color pen-color
end

;;;;;;;;;;;;;;;;For whole SC
to plot-whole

set-current-plot "whole distributers"

set-current-plot-pen "total-profit"
plot sum [revenue - cost] of players with [role = "distributer"]
set-plot-pen-color blue

set-current-plot-pen "on-hand"
plot sum [on-hand] of players with [role = "distributer"]
set-plot-pen-color red


set-current-plot "whole retailers"

set-current-plot-pen "total-profit"
plot sum [revenue - cost] of players with [role = "retailer"]
set-plot-pen-color blue

set-current-plot-pen "on-hand"
plot sum [on-hand] of players with [role = "retailer"]
set-plot-pen-color red



set-current-plot "whole supply chain"

set-current-plot-pen "total-profit"
plot sum [revenue - cost] of players with [role = "distributer" or role = "retailer"]
set-plot-pen-color blue

set-current-plot-pen "on-hand"
plot sum [on-hand] of players with [role = "distributer" or role = "retailer"]
set-plot-pen-color red

end

;;;;;; iteration step

to plot-profit
  set-current-plot "total profit of each player"
  set-current-plot-pen label
  plot revenue - cost
end

to plot-on-hand-inventory
  set-current-plot "on-hand inventory of each player"
  set-current-plot-pen label
  plot on-hand
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Iteration Block


to go

if ticks >= days-of-simulation [ stop]

if ticks < 20 * count players with [ role = "supplier"]  [make-visitors ] ;; eacg supplier has 20 medreps

move-visitors

if all? visitors [ color = green] [
set demand-today daily-demand ;; it is a statistical function
place-order-to-up
receive-shipment-from-up
process-demand-from-down
summarize
statistics
update-policy
resize-shape

move-patients
]
  tick

end



to make-visitors

ask players with [ role = "supplier"] [
hatch-visitors 1 [
                  set shape "person"
                  set size 1.5
      set color [color] of myself
                  set heading ifelse-value (random 100 < 50) [180] [0]
      fd 2
    ]

  ]
end




to move-visitors


  ask visitors with [ color != green] [

          fd 2

          if patch-ahead 1 = nobody [ set heading 90 fd 2]

          if heading = 90 and patch-ahead 4 = nobody [set heading towards one-of Drs fd 1]



  ]

  ask visitors [

    if any? Drs-here [ set color green]

  ]


end




to-report daily-demand                ;; we design five mechanisms for generating the daily demand, which can be chosen in the chooser
  if distribution = "deterministic"
    [report deterministic-demand]     ;; deterministic demand means the demand is constant, there is no uncertainty

  if distribution = "poisson"         ;; poisson demand means that the daily demand follows Poisson distribution
    [report random-poisson mean-for-poisson]

  if distribution = "normal"          ;; normal demand means that the daily demand follows truncated normal distribution (modified in this model)
    [report truncated-normal mean-for-normal std-for-normal lower-bound-for-normal upper-bound-for-normal]

    if distribution = "exponential"         ;; exponential demand means that the daily demand follows exponential distribution
    [report random-exponential mean-for-exponential]

   if distribution = "gamma"         ;; exponential demand means that the daily demand follows exponential distribution
    [report random-gamma alpha-for-gamma lambda-for-gamma]

end

to-report truncated-normal [mean-value std-value min-value max-value]    ;; there are 4 parameters for the truncated normal distribution
  let random-num random-normal mean-value std-value                      ;; we first generate a random-normal number according to the mean value and standard-deviation value
  ifelse random-num > max-value or random-num < min-value
  [report round (min-value + random-float (max-value - min-value))]      ;; if the value is beyond the min-value and max-value, report a random number within the range
  [report round random-num]                                              ;; if the value is within the min-value and max-value, report the rounding of this number
end


to  place-order-to-up

  ask players with [ role = "distributer" or role = "retailer"] [

    let amount-to-order max (list ( base-stock - inventory-position) 0)

    ask my-out-demand-links [ set orders-placed 0]

    ask who-to-order [ set orders-placed amount-to-order]
  ]

end

to-report who-to-order  ;; report the demand link that has the lowest back-orders, so that the player will choose to order from this one
  let min-back-order min [back-orders] of my-out-demand-links  ;; find out the minimum back-order

  let sorted-links []                         ;; prepare an empty list

  foreach sort my-out-demand-links [ i ->          ;; if the back-orders of the demand links equals to the minimum back-order
    ask i [                                   ;; add the demand link to sorted-links list
      if back-orders = min-back-order [set sorted-links lput self sorted-links]
    ]
  ]

  ifelse member? current-supplier sorted-links [   ;; if the current-supplier (actually the corresponding demand link) is among the demand links with the minimum back-order
    report current-supplier                        ;; choose the current supplier due to customer loyalty
  ][
  let chosen-one one-of sorted-links               ;; if not, choose one from the demand links with the minimum back-order
  set current-supplier chosen-one                  ;; then transfer the supplier to this one
  report chosen-one
  ]
end


to receive-shipment-from-up
  ask players [
    if role = "distributer" or role = "retailer" [

      set last-received sum [first orders-filled] of my-in-supply-links     ;; take out the first item in the supply-link pipeline
      ask my-in-supply-links [set orders-filled but-first orders-filled]    ;; remove it from the pipeline
      set on-hand on-hand + last-received                                   ;; add it to the current on-hand inventory

    ]

    if role = "supplier" [set on-hand 10000]                                ;; we assume the supplier has unlimited supply
  ]
end


to process-demand-from-down

  ask players [

    let new-orders 0                                        ;; for distributers and suppliers, new orders equal to the sum of the orders-placed of all in-demand-links
    if role = "supplier" or role = "distributer" [set new-orders sum [orders-placed] of my-in-demand-links]
    if role = "retailer" [set new-orders demand-today]      ;; for retailers, new orders simply equal to today's demand


    set demand-history lput new-orders demand-history       ;; record the new-order in the demand history
    set demand-history but-first demand-history             ;; delete the earliest demand history on the record, in order to keep the record length the same


    let all-requested-orders new-orders + backlog               ;; besides new orders, back-orders also need to be satisfied
    let orders-to-ship min list all-requested-orders on-hand    ;; if there is sufficient inventory, ship the requested amount
                                                            ;; if not sufficient inventory, ship whatever on-hand

    if role = "distributer" [set revenue revenue + revenue-coeff-distributer * orders-to-ship]    ;; revenue for distributers  for each unit shipped
    if role = "retailer" [set revenue revenue + revenue-coeff-retailer * orders-to-ship]       ;; revenue for each unit shipped



    set backlog max list 0 (backlog - on-hand + new-orders)    ;; the unsatisfied demand is counted as backlog (or back-orders)


;;;;; Allocating an amount to each dowstream node

    let amount orders-to-ship       ;; allocate total shipping amount to each downstream node

    foreach sort my-out-supply-links [ i ->
      ask i [                                    ;; quota to each supply link is proportional the sum of back-orders and new orders of the pair demand link
        let quota sum [back-orders] of pair-demand-link + sum [orders-placed] of pair-demand-link
        let ship-to-this-link 0                  ;; if no order, ship nothing, and put 0 in the supply link
        if all-requested-orders > 0 [                ;; if positive order, ship according to the quota
          set ship-to-this-link min list ceiling (quota * orders-to-ship / all-requested-orders) amount
        ]                                        ;; note that we use ceiling to guarantee the integrity of the shipping quantity
        set amount amount - ship-to-this-link
        set orders-filled lput ship-to-this-link orders-filled    ;; put the ship quantity at the last place of the supply pipeline
        ask pair-demand-link [set back-orders max list 0 (quota - ship-to-this-link)]  ;; update the back-orders in the pair demand link
      ]
    ]

    set on-hand on-hand - orders-to-ship    ;; reduce the shipped quantity from the on-hand inventory
  ]
end

to summarize
  ask players [

    let pipeline sum [sum orders-filled] of my-in-supply-links    ;; calculate the pipeline inventory (inventory in-transit) for each player


    set inventory-position on-hand + pipeline - backlog           ;; recalculate the inventory position

    let cost-add (0.5 * on-hand + 2 * backlog)                    ;; calculate inventory holding cost and backlog penalty

    set cost cost + cost-add                                      ;; update the cost
  ]
end

to statistics

;;;;;; plots for each player

 ask players with [role = "distributer" or role = "retailer"] [
    plot-on-hand-inventory
    plot-profit
  ]

;;;;;; Whole plotting

 plot-whole

 ;;;;;;;;; Tables and Data
let sorted-retailers sort-on [id-number] players with [role = "retailer" ]
let sorted-distributer sort-on [id-number] players with [role = "distributer"]
foreach sorted-retailers [ i -> ask i [outputing] ]
foreach sorted-distributer [ i -> ask i [outputing] ]
end

to outputing
output-print (list (word "time =" ticks) (word "my-role & Id = " role " " id-number) (word "myrev = " revenue) (word "mycost = " cost) (word "myprofit = " (revenue - cost)))
end


to update-policy             ;; the players can update their inventory policy according to their demand record
  ask players with [role = "distributer"][
    set base-stock cal-base-stock-level demand-history lead-time-supplier-to-distributer
  ]
  ask players with [role = "retailer"][
    set base-stock cal-base-stock-level demand-history lead-time-distributer-to-retailer
  ]
end

to-report cal-base-stock-level [demand-list delay]     ;; calculate base-stock based on demand-history
  let numbers filter is-number? demand-list            ;; during the first few days, not all the elements in the demand history are numbers, but ""
  let mean-value-of-demands mean numbers                          ;; calculate mean value

  let std 0
  if length numbers >= 2[                              ;; calculate the standard deviation of the demand history
    set std standard-deviation numbers
  ]
                                                       ;; according to inventory theories, the base-stock level is usually calculated according to mean and std and supply delays
  report round (mean-value-of-demands * (delay + 1) + safety-factor * std * (sqrt (delay + 1)))  ;; "+1" because of the order processing delay
end


to move-patients
  ask patients
  [
    fd 1
    if patch-ahead 7 = nobody [
      let target one-of players with [ role = "retailer"]
      if target != nobody [ set heading towards target]
    ]


    if [pxcor] of patch-ahead 1 = dist [

 let target one-of Drs
      if target != nobody [ set heading towards target]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
199
10
914
474
-1
-1
7.0
1
10
1
1
1
0
0
0
1
-50
50
-32
32
1
1
1
ticks
30.0

SLIDER
7
159
177
192
num-of-distributers
num-of-distributers
0
11
4.0
1
1
NIL
HORIZONTAL

SLIDER
8
202
175
235
num-of-retailers
num-of-retailers
0
22
12.0
1
1
NIL
HORIZONTAL

BUTTON
5
483
176
517
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
191
575
288
608
hide demand links
ask links with [ color = orange] [ hide-link]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
293
575
404
610
hide supply  link
ask links with [ color = green] [ hide-link]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
2
321
175
354
initial-stock-distributer
initial-stock-distributer
0
1000
260.0
1
1
NIL
HORIZONTAL

SLIDER
3
633
177
666
lead-time-supplier-to-distributer
lead-time-supplier-to-distributer
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
4
361
174
394
initial-stock-retailer
initial-stock-retailer
0
100
90.0
1
1
NIL
HORIZONTAL

SLIDER
3
671
176
704
lead-time-distributer-to-retailer
lead-time-distributer-to-retailer
0
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
4
404
175
437
record-length
record-length
0
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
6
76
177
109
days-of-simulation
days-of-simulation
0
10000000
1.0E7
1
1
NIL
HORIZONTAL

CHOOSER
655
575
827
620
distribution
distribution
"deterministic" "poisson" "normal" "gamma" "exponential"
1

SLIDER
660
646
832
679
deterministic-demand
deterministic-demand
0
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
655
708
827
741
mean-for-poisson
mean-for-poisson
0
14
9.0
1
1
NIL
HORIZONTAL

SLIDER
654
770
826
803
mean-for-normal
mean-for-normal
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
656
807
828
840
std-for-normal
std-for-normal
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
654
851
828
884
lower-bound-for-normal
lower-bound-for-normal
0
10
0.0
1
1
NIL
HORIZONTAL

SLIDER
656
890
830
923
upper-bound-for-normal
upper-bound-for-normal
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
656
954
828
987
mean-for-exponential
mean-for-exponential
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
656
994
828
1027
alpha-for-gamma
alpha-for-gamma
0
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
657
1033
830
1066
lambda-for-gamma
lambda-for-gamma
0
100
50.0
1
1
NIL
HORIZONTAL

PLOT
946
10
1568
281
total profit of each player
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
948
292
1569
550
on-hand inventory of each player
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

BUTTON
2
522
95
555
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
194
618
630
663
NIL
demand-today
17
1
11

BUTTON
98
523
174
556
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
4
711
176
744
revenue-coeff-distributer
revenue-coeff-distributer
0
10
2.0
0.5
1
NIL
HORIZONTAL

SLIDER
4
753
175
786
revenue-coeff-retailer
revenue-coeff-retailer
0
10
3.0
0.5
1
NIL
HORIZONTAL

SLIDER
6
242
174
275
num-of-patients
num-of-patients
0
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
191
489
283
522
NIL
layout-supplier
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
387
534
461
567
NIL
initialize
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
467
535
547
568
NIL
resize-shape
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
553
535
664
568
NIL
reset-plots
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
290
490
389
523
NIL
layout-distributer
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
392
491
485
524
NIL
layout-retailer
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
193
531
282
568
NIL
set-demand-link
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
293
534
380
567
NIL
set-supply-link
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
412
577
526
610
show demand links
ask links with [ color = orange] [ show-link]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
535
575
633
610
show supply
ask links with [ color = green] [ show-link]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
593
490
709
523
NIL
 layout-patients
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
3
596
172
629
dist
dist
10
max-pxcor
10.0
1
1
NIL
HORIZONTAL

SWITCH
5
445
175
478
on-click-setup?
on-click-setup?
0
1
-1000

TEXTBOX
690
553
840
571
Demand Functions 
11
0.0
1

TEXTBOX
661
626
868
654
params of deterministic function
11
0.0
1

TEXTBOX
662
687
812
705
params of poisson function
11
0.0
1

TEXTBOX
658
748
808
766
params of normal function
11
0.0
1

TEXTBOX
661
929
811
947
params of exponential function
11
0.0
1

OUTPUT
3
789
643
1067
7

PLOT
940
896
1580
1061
whole supply chain
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"on-hand" 1.0 0 -16777216 true "" ""
"total-profit" 1.0 0 -7500403 true "" ""

PLOT
950
569
1577
719
whole distributers
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"on-hand" 1.0 0 -16777216 true "" ""
"total-profit" 1.0 0 -7500403 true "" ""

PLOT
944
734
1579
884
whole retailers
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"on-hand" 1.0 0 -16777216 true "" ""
"total-profit" 1.0 0 -7500403 true "" ""

SLIDER
6
116
176
149
num-of-suppliers
num-of-suppliers
1
3
2.0
1
1
NIL
HORIZONTAL

INPUTBOX
5
10
173
70
seed
1.0
1
0
Number

SLIDER
5
281
177
314
num-of-doctors
num-of-doctors
1
20
20.0
1
1
NIL
HORIZONTAL

BUTTON
490
491
586
524
NIL
layout-doctors 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dist0
false
0
Rectangle -7500403 true true 45 225 270 300
Rectangle -16777216 true false 75 270 105 300
Polygon -7500403 true true 30 225 150 165 285 225
Rectangle -16777216 true false 120 270 150 300
Rectangle -16777216 true false 165 270 195 300
Rectangle -16777216 true false 210 270 240 300
Line -16777216 false 30 225 285 225

dist1
false
0
Rectangle -7500403 true true 45 225 255 300
Polygon -7500403 true true 30 225 150 165 270 225
Line -16777216 false 30 225 270 225
Rectangle -16777216 true false 90 255 135 300
Rectangle -16777216 true false 165 255 210 300

dist2
false
0
Rectangle -7500403 true true 45 225 255 300
Line -16777216 false 30 225 270 225
Rectangle -16777216 true false 105 270 135 300
Rectangle -16777216 true false 195 255 240 300
Polygon -7500403 true true 30 225 45 195 255 195 270 225
Rectangle -16777216 true false 60 270 90 300
Rectangle -16777216 true false 150 270 180 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

arc
3.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Polygon -7500403 true true 150 150 105 225 195 225 150 150
@#$#@#$#@
0
@#$#@#$#@
