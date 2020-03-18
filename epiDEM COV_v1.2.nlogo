globals
[
  nb-infected-previous ;; Number of infected people at the previous tick
  nb-infected-previous-p1 ; For country 1
  nb-infected-previous-p2 ; For country 2
  border               ;; The patches representing the yellow border
  angle                ;; Heading for individuals
  beta-n               ;; The average number of new secondary infections per infected this tick
  beta-n-p1
  beta-n-p2
  gamma                ;; The average number of new recoveries per infected this tick
  gamma-p1
  gamma-p2
  r0                   ;; The number of secondary infections that arise due to a single infective introduced in a wholly susceptible population
  r0-p1
  r0-p2
  muertes-p1
  muertes-p2
  ;por-riesgo-p1               ;percent of people in a risk group (senior, diabetes, heart condition, etc.)
  ;por-riesgo-p2
]

turtles-own
[
  infected?            ;; If true, the person is infected.
  cured?               ;; If true, the person has lived through an infection. They cannot be re-infected.
  inoculated?          ;; If true, the person has been inoculated.
  isolated?            ;; If true, the person is isolated, unable to infect anyone.
  hospitalized?        ;; If true, the person is hospitalized and will recovery in half the tiempo-prom-recuperacion.
  infection-length     ;; How long the person has been infected.
  recovery-time        ;; Time (in hours) it takes before the person has a chance to recover from the infection
  tendencia-cuarentena   ;; Chance the person will self-quarantine during any day being infected.
  tendencia-hospitalizacion ;; Chance that an infected person will go to the hospital when infected
  f-medidas-personales   ;; factor de contagio si la persona toma medidas personales de precaución
  continent            ;; Which continent a person lives one, people on continent 1 are squares, people on continent 2 are circles.
  ambulance?           ;; If true, the person is an ambulance and will transport infected people to the hospital.
  susceptible?         ;; Tracks whether the person was initially susceptible
  nb-infected          ;; Number of secondary infections caused by an infected person at the end of the tick
  nb-recovered         ;; Number of recovered people at the end of the tick
  salud                ;; Estado de salud de la persona
  riesgo?               ;; está en un grupo de riesgo


]

breed [p1s p1]
breed [p2s p2]



;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  setup-globals
  crear-poblacion
  setup-people
  infeccion-inicial
  ;setup-ambulance
  reset-ticks
end

to setup-globals
  if hospitales? [
  ask patch (- max-pxcor / 2 ) max-pycor [ set pcolor blue set plabel "H"]
  ask patch (max-pxcor / 2 ) max-pycor [ set pcolor blue set plabel "H"]
  ]

  set border patches with [(pxcor =  0 and abs (pycor) >= 0)]
  ask border [ set pcolor white ]

end

;; Create poblacion number of people.
;; Those that live on the left are squares; those on the right, circles.

to crear-poblacion
  set-default-shape turtles "person"

  ;ask n-of (p1-poblacion / 4) (patches with [pxcor < (min-pxcor / 1.5)]) [sprout-p1s 1]
  ask n-of (p1-poblacion / 4) (patches with [pxcor < (min-pxcor / 2 - 2) and pycor < (-2)]) [sprout-p1s 1]
  ask n-of (p1-poblacion / 4) (patches with [pxcor < (min-pxcor / 1.8) and pycor > (2)]) [sprout-p1s 1]
  ask n-of (p1-poblacion / 4) (patches with [pxcor < (0) and pxcor > (min-pxcor / 2 + 2) and pycor > (2)]) [sprout-p1s 1]
  ask n-of (p1-poblacion / 4) (patches with [pxcor < (0) and pxcor > (min-pxcor / 2 + 2) and pycor < (-2)]) [sprout-p1s 1]

  ;ask n-of (p2-poblacion) (patches with [pxcor > 0]) [sprout-p2s 1]
  ask n-of (p2-poblacion / 4) (patches with [pxcor > (max-pxcor / 2 + 2) and pycor > (2)]) [sprout-p2s 1]
  ask n-of (p2-poblacion / 4) (patches with [pxcor > (max-pxcor / 1.8) and pycor < (-2)]) [sprout-p2s 1]
  ask n-of (p2-poblacion / 4) (patches with [pxcor > (0) and pxcor < (max-pxcor / 2 - 2) and pycor > (2)]) [sprout-p2s 1]
  ask n-of (p2-poblacion / 4) (patches with [pxcor > (0) and pxcor < (max-pxcor / 2 - 2) and pycor < (-2)]) [sprout-p2s 1]

end
to setup-people

 ask turtles [

    set cured? false
    set isolated? false
    set hospitalized? false
    set ambulance? false
    set infected? false
    set susceptible? true
    set riesgo? false
    set f-medidas-personales 1
    set salud random-normal 7 2
    if salud <= 0 [set salud 1]

    set size 1

      ]

  assign-tendency

  if vinculos? [ make-network ]
end

to infeccion-inicial
  ask n-of p1-infectados-inicial p1s
    [ set infected? true
      set susceptible? false
      set infection-length random recovery-time
    ]

    ask n-of p2-infectados-inicial p2s
    [ set infected? true
      set susceptible? false
      set infection-length random recovery-time
    ]

  ask turtles [
        ifelse (not infected?) and (random-float 100 < probabilidad-vacuna)
        [ set inoculated? true
          set susceptible? false ]
        [ set inoculated? false ]

      assign-color
  ]

end

;to setup-ambulance
;  create-turtles ambulancias
;  [
;    ifelse random 2 < 1
;    [
;      set continent 1
;      setxy (- max-pxcor / 2) 0
;    ]
;    [
;      set continent 2
;      setxy (max-pxcor / 2) 0
;    ]
;
;    set cured? false
;    set isolated? false
;    set hospitalized? false
;    set infected? false
;    set inoculated? false
;    set susceptible? false
;
;    set ambulance? true
;
;    set shape "person"
;    set color yellow
;  ]
;end

to assign-tendency ;; Turtle procedure

  ask p1s [
    if (random-float 100 < p1-med-personales) [ set f-medidas-personales (1 / efectividad-mp)]
    set tendencia-cuarentena random-normal p1-tend-cuarentena (p1-tend-cuarentena / 4)
    set tendencia-hospitalizacion random-normal p1-tendencia-hospitalizacion (p1-tendencia-hospitalizacion / 4)
    if (random-float 100 < por-riesgo-p1) [ set riesgo? true]
      ]


    ask p2s [
    if (random-float 100 < p2-med-personales) [ set f-medidas-personales (1 / efectividad-mp)]
    set tendencia-cuarentena random-normal P2-tend-cuarentena (P2-tend-cuarentena / 4)
    set tendencia-hospitalizacion random-normal p2-tendencia-hospitalizacion (p2-tendencia-hospitalizacion / 4)
    if (random-float 100 < por-riesgo-p1) [ set riesgo? true]
      ]

  ask turtles [
  set recovery-time random-normal tiempo-prom-recuperacion (tiempo-prom-recuperacion / 4)

  ;; Make sure recovery-time lies between 0 and 2x tiempo-prom-recuperacion
  if recovery-time > tiempo-prom-recuperacion * 2 [ set recovery-time (tiempo-prom-recuperacion * 2) ]
  if recovery-time < 0 [ set recovery-time 0 ]

  ;; Similarly for isolation and hospital going tendencies
  if tendencia-cuarentena > tendencia-cuarentena * 2 [ set tendencia-cuarentena (tendencia-cuarentena * 2) ]
  if tendencia-cuarentena < 0 [ set tendencia-cuarentena 0 ]

  if tendencia-hospitalizacion > tendencia-hospitalizacion * 2 [ set tendencia-hospitalizacion (tendencia-hospitalizacion * 2) ]
  if tendencia-hospitalizacion < 0 [ set tendencia-hospitalizacion 0 ]

  ]
end


;; Different people are displayed in 5 different colors depending on health
;; green is a survivor of the infection
;; blue is a successful innoculation
;; red is an infected person
;; white is neither infected, innoculated, nor cured
;; yellow is an ambulance
to assign-color ;; turtle procedure

  ifelse cured?
    [ set color green ]
    [ ifelse inoculated?
      [ set color blue ]
      [ ifelse infected?
        [set color yellow
        if salud < 2 [ set color red ]
      ]
        [set color white]]]
  ;if ambulance?
  ;[ set color yellow ]


end


to make-network
  ask turtles
  [
    create-links-with turtles-on neighbors
  ]
end


;;;
;;; GO PROCEDURES
;;;


to go
  if all? turtles [ not infected? ]
    [ stop ]
  ask turtles
    [ clear-count ]

  ask turtles
    [ if not isolated? and not hospitalized? and not ambulance?
        [ move ] ]

  ask turtles
    [ if infected? and not isolated? and not hospitalized?
         [ infect ] ]

  ;; isolation depends on tendencia-cuarentena and infection length (when simptoms appear Backer et al., 2020)
  ask turtles
    [ if not isolated? and not hospitalized? and infected? and (random 100 < tendencia-cuarentena) and
      (infection-length >= random-normal 6 2)
        [ isolate ] ]

  if hospitales? [
    ask turtles
    [ if not isolated? and not hospitalized? and infected? and (random 100 < tendencia-hospitalizacion)
      [ hospitalize ]
    ]
  ]


;  ask turtles
;  [
;    if ambulance?
;    [
;      move
;      ask turtles-on neighbors
;      [
;        if (ambulance? = false) and (infected? = true)
;        [ hospitalize ]
;      ]
;    ]
;  ]

  ask turtles
    [ if infected?
       [ maybe-recover ]
    ]

  ask turtles
    [ if (isolated? or hospitalized?) and cured?
        [ unisolate ] ]

  ask turtles
  [ calcular-salud]

    ask turtles
    [ assign-color
      calculate-r0
      calculate-r0-p1
      calculate-r0-p2
  ]

  tick
end

to calcular-salud

  if infected?[
    ifelse hospitalized?[
      ifelse riesgo?
      [set salud salud - 0.2]    ;riesgo, hospitalizado
      [set salud salud - 0.05]   ;no riesgo, hospitalizado
    ]
    [ifelse riesgo?
      [set salud salud - 0.5]    ;riesgo, no hospitalizado
      [set salud salud - 0.02]   ;riesgo, no hospitalizado
    ]
   ]

  if salud <= 0 [
    if breed = p1s [set muertes-p1 (muertes-p1  + 1)]
    if breed = p2s [set muertes-p2 (muertes-p2  + 1)]
    die
  ]

  if (cured? and salud < 10)
    [set salud salud + 0.1]

end


to move  ;; turtle procedure
  if viajes-int?
  [
    if random 1000 < (mobilidad-internacional) and not ambulance?  ;; up to 1% chance of travel
    [ set xcor (- xcor) ]
  ]

  ifelse breed = p1s
  [
    ifelse xcor > (- 2)  ;; and near border patch
    [
      set angle random-float 180
      let new-patch patch-at-heading-and-distance angle (-1)
      if new-patch != nobody
      [
        move-to new-patch
      ]
    ]
    [ ;; if in continent 1 and not on border
      ifelse xcor < (min-pxcor + 0.5)  ;; at the edge of world
      [
        set angle random-normal 180 10
      ]
      [
        set angle random-normal 0 90  ;; inside world
      ]
      rt angle

      ifelse ambulance?
      [
        fd p1-mobilidad-local * 5  ;; ambulances move 5 times as fast than the ppl
      ]
      [
        fd random-normal p1-mobilidad-local p1-mobilidad-local / 2
      ]
    ]

  ]
  [ ;; in continent 2
    ifelse xcor < 2  ;; and on border patch
    [
      set angle random-float 180
      let new-patch patch-at-heading-and-distance angle (1)
      if new-patch != nobody
      [
        move-to new-patch
      ]
    ]
    [ ;; if in continent 2 and not on border
      ifelse xcor > (max-pxcor - 1) ;; at the edge of world
      [
        set angle random-float 180
      ]
      [
        set angle random-normal 0 90
      ]
      lt angle

      ifelse ambulance?
      [
        fd p2-mobilidad-local * 5
      ]
      [
       fd random-normal p2-mobilidad-local p2-mobilidad-local / 2
      ]
    ]

  ]
end

to clear-count
  set nb-infected 0
  set nb-recovered 0
end

to maybe-recover
  set infection-length infection-length + 1

      ;; If people have been infected for more than the recovery-time
      ;; then there is a chance for recovery
      ifelse not hospitalized?
      [
        if infection-length > recovery-time
        [
          if random-float 100 < prob-recuperacion
          [
            set infected? false
            set cured? true
            set nb-recovered (nb-recovered + 1)
          ]
        ]
      ]

      [ ;; If hospitalized, recover in a half of the recovery time
        if infection-length > (recovery-time / 1)
        [
          if random-float 100 < prob-recuperacion
          [
            set infected? false
            set cured? true
            set nb-recovered (nb-recovered + 1)
          ]
        ]
      ]
end

;; To better show that isolation has occurred, the patch below the person turns gray
to isolate ;; turtle procedure
  set isolated? true
  move-to patch-here ;; move to center of patch
  ask (patch-at 0 0) [ set pcolor gray - 3 ]
end

;; After unisolating, patch turns back to normal color
to unisolate  ;; turtle procedure
  set isolated? false
  set hospitalized? false

  ask (patch-at 0 0) [ set pcolor black ]

  ask border [ set pcolor white ]                      ;; patches on the border stay yellow
  ask (patch-set patches with [plabel = "H"]) [ set pcolor blue ]  ;; hospital patch on the left stays white
  ;ask (patch (max-pxcor / 2) 0) [ set pcolor blue ]    ;; hospital patch on the right stays white
end

;; To hospitalize, move to hospital patch in the continent of current residence
to hospitalize ;; turtle procedure
  set hospitalized? true
  set pcolor black
  ifelse breed = p1s
  [
    move-to one-of patch-set patches with [plabel = "H" and pxcor < 0 ]
  ]
  [
    move-to one-of patch-set patches with [plabel = "H" and pxcor > 0 ]
  ]
  set pcolor white
end

;; Infected individuals who are not isolated or hospitalized have a chance of transmitting their disease to their susceptible neighbors.
;; If the neighbor is linked, then the chance of disease transmission doubles.

to infect  ;; turtle procedure

    let caller self

    let nearby-uninfected (turtles-on neighbors)
    with [ not infected? and not cured? and not inoculated? ]
    if nearby-uninfected != nobody
    [
       ask nearby-uninfected
       [
           ifelse link-neighbor? caller
           [
             if random 100 < prob-contagio * f-medidas-personales * 2 ;; twice as likely to infect a linked person
             [
               set infected? true
               set nb-infected (nb-infected + 1)
             ]
           ]
           [
             if random 100 < prob-contagio * f-medidas-personales
             [
               set infected? true
               set nb-infected (nb-infected + 1)
             ]
           ]
       ]

    ]

end


to calculate-r0

  let new-infected sum [ nb-infected ] of turtles
  let new-recovered sum [ nb-recovered ] of turtles
  set nb-infected-previous (count turtles with [ infected? ] + new-recovered - new-infected)  ;; Number of infected people at the previous tick
  let susceptible-t (count turtles - (count turtles with [ infected? ]) - (count turtles with [ cured? ]))  ;; Number of susceptibles now
  let s0 count turtles with [ susceptible? ] ;; Initial number of susceptibles

  ifelse nb-infected-previous < 10
  [ set beta-n 0 ]
  [
    set beta-n (new-infected / nb-infected-previous)       ;; This is the average number of new secondary infections per infected this tick
  ]

  ifelse nb-infected-previous < 5
  [ set gamma 0 ]
  [
    set gamma (new-recovered / nb-infected-previous)     ;; This is the average number of new recoveries per infected this tick
  ]

  if ((count turtles - susceptible-t) != 0 and (susceptible-t != 0))   ;; Prevent from dividing by 0
  [
    ;; This is derived from integrating dI / dS = (beta*SI - gamma*I) / (-beta*SI)
    ;; Assuming one infected individual introduced in the beginning, and hence counting I(0) as negligible,
    ;; we get the relation
    ;; N - gamma*ln(S(0)) / beta = S(t) - gamma*ln(S(t)) / beta, where N is the initial 'susceptible' population.
    ;; Since N >> 1
    ;; Using this, we have R_0 = beta*N / gamma = N*ln(S(0)/S(t)) / (K-S(t))
    set r0 (ln (s0 / susceptible-t) / (count turtles - susceptible-t))
    set r0 r0 * s0 ]
end

to calculate-r0-p1

  let new-infected-p1 sum [ nb-infected ] of p1s
  let new-recovered-p1 sum [ nb-recovered ] of p1s
  set nb-infected-previous-p1 (count p1s with [ infected? ] + new-recovered-p1 - new-infected-p1)  ;; Number of infected people at the previous tick
  let susceptible-t-p1 (count(p1s) - (count p1s with [ infected? ]) - (count p1s with [ cured? ]))  ;; Number of susceptibles now
  let s0-p1 count p1s with [ susceptible? ] ;; Initial number of susceptibles

  ifelse nb-infected-previous-p1 < 10
  [ set beta-n-p1 0 ]
  [
    set beta-n-p1 (new-infected-p1 / nb-infected-previous-p1)       ;; This is the average number of new secondary infections per infected this tick
  ]

  ifelse nb-infected-previous-p1 < 5
  [ set gamma-p1 0 ]
  [
    set gamma-p1 (new-recovered-p1 / nb-infected-previous-p1)     ;; This is the average number of new recoveries per infected this tick
  ]

  if ((count(p1s) - susceptible-t-p1) != 0 and (susceptible-t-p1 != 0))   ;; Prevent from dividing by 0
  [
    ;; This is derived from integrating dI / dS = (beta*SI - gamma*I) / (-beta*SI)
    ;; Assuming one infected individual introduced in the beginning, and hence counting I(0) as negligible,
    ;; we get the relation
    ;; N - gamma*ln(S(0)) / beta = S(t) - gamma*ln(S(t)) / beta, where N is the initial 'susceptible' population.
    ;; Since N >> 1
    ;; Using this, we have R_0 = beta*N / gamma = N*ln(S(0)/S(t)) / (K-S(t))
    set r0-p1 (ln (s0-p1 / susceptible-t-p1) / (count(p1s) - susceptible-t-p1))
    set r0-p1 r0-p1 * s0-p1 ]

end

to calculate-r0-p2

  let new-infected-p2 sum [ nb-infected ] of p2s
  let new-recovered-p2 sum [ nb-recovered ] of p2s
  set nb-infected-previous-p2 (count p2s with [ infected? ] + new-recovered-p2 - new-infected-p2)  ;; Number of infected people at the previous tick
  let susceptible-t-p2 (count(p2s) - (count p2s with [ infected? ]) - (count p2s with [ cured? ]))  ;; Number of susceptibles now
  let s0-p2 count p2s with [ susceptible? ] ;; Initial number of susceptibles

  ifelse nb-infected-previous-p2 < 10
  [ set beta-n-p2 0 ]
  [
    set beta-n-p2 (new-infected-p2 / nb-infected-previous-p2)       ;; This is the average number of new secondary infections per infected this tick
  ]

  ifelse nb-infected-previous-p2 < 5
  [ set gamma-p2 0 ]
  [
    set gamma-p2 (new-recovered-p2 / nb-infected-previous-p2)     ;; This is the average number of new recoveries per infected this tick
  ]

  if ((count(p2s) - susceptible-t-p2) != 0 and (susceptible-t-p2 != 0))   ;; Prevent from dividing by 0
  [
    ;; This is derived from integrating dI / dS = (beta*SI - gamma*I) / (-beta*SI)
    ;; Assuming one infected individual introduced in the beginning, and hence counting I(0) as negligible,
    ;; we get the relation
    ;; N - gamma*ln(S(0)) / beta = S(t) - gamma*ln(S(t)) / beta, where N is the initial 'susceptible' population.
    ;; Since N >> 1
    ;; Using this, we have R_0 = beta*N / gamma = N*ln(S(0)/S(t)) / (K-S(t))
    set r0-p2 (ln (s0-p2 / susceptible-t-p2) / (count(p2s) - susceptible-t-p2))
    set r0-p2 r0-p2 * s0-p2 ]

end


; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
405
10
1013
520
-1
-1
9.84
1
10
1
1
1
0
0
0
1
-30
30
-25
25
1
1
1
days
30.0

BUTTON
140
230
223
263
Inicializar
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
225
230
315
263
Ejecutar
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

SLIDER
140
20
265
53
p1-poblacion
p1-poblacion
50
500
300.0
10
1
NIL
HORIZONTAL

SLIDER
140
160
265
193
p1-tend-cuarentena
p1-tend-cuarentena
0
50
0.0
5
1
NIL
HORIZONTAL

PLOT
0
270
395
475
Poblacion infectada
dias
# personas
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"País 1" 1.0 0 -13210332 true "" "plot count p1s with [ infected?]"
"País 2" 1.0 0 -10022847 true "" "plot count p2s with [ infected?]"

SLIDER
100
800
255
833
probabilidad-vacuna
probabilidad-vacuna
0
50
0.0
5
1
NIL
HORIZONTAL

SLIDER
100
835
255
868
ambulancias
ambulancias
0
4
0.0
1
1
NIL
HORIZONTAL

SLIDER
395
840
545
873
p1-tendencia-hospitalizacion
p1-tendencia-hospitalizacion
0
50
0.0
5
1
NIL
HORIZONTAL

PLOT
670
640
950
786
Tasas de infección y recuperación
dias
tasa
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Ti" 1.0 0 -2674135 true "" "plot (beta-n * nb-infected-previous)"
"Tr" 1.0 0 -10899396 true "" "plot (gamma * nb-infected-previous)"

SLIDER
5
20
135
53
prob-contagio
prob-contagio
1
50
15.0
1
1
NIL
HORIZONTAL

SLIDER
5
125
135
158
prob-recuperacion
prob-recuperacion
10
100
10.0
5
1
NIL
HORIZONTAL

SWITCH
260
800
362
833
vinculos?
vinculos?
1
1
-1000

SLIDER
140
125
265
158
p1-mobilidad-local
p1-mobilidad-local
0
1
0.3
0.1
1
NIL
HORIZONTAL

SWITCH
5
160
135
193
viajes-int?
viajes-int?
1
1
-1000

SLIDER
5
195
135
228
mobilidad-internacional
mobilidad-internacional
0
1
0.5
.05
1
NIL
HORIZONTAL

SLIDER
5
90
135
123
tiempo-prom-recuperacion
tiempo-prom-recuperacion
10
60
30.0
5
1
NIL
HORIZONTAL

BUTTON
315
230
395
263
1 paso
go
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
140
90
265
123
p1-infectados-inicial
p1-infectados-inicial
0
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
515
520
580
565
Infectados
count p1s with [ infected?]
0
1
11

SLIDER
270
160
395
193
p2-tend-cuarentena
p2-tend-cuarentena
0
50
0.0
5
1
NIL
HORIZONTAL

SLIDER
560
840
700
873
p2-tendencia-hospitalizacion
p2-tendencia-hospitalizacion
0
50
0.0
1
1
NIL
HORIZONTAL

SLIDER
140
194
265
227
p1-med-personales
p1-med-personales
0
100
0.0
15
1
NIL
HORIZONTAL

SLIDER
270
194
395
227
p2-med-personales
p2-med-personales
0
100
0.0
5
1
NIL
HORIZONTAL

TEXTBOX
145
0
180
18
País 1
11
52.0
1

TEXTBOX
275
0
315
18
País 2
11
123.0
1

SLIDER
270
125
395
158
p2-mobilidad-local
p2-mobilidad-local
0
1
0.7
0.1
1
NIL
HORIZONTAL

MONITOR
790
520
855
565
Infectados
count p2s with [infected?]
0
1
11

SLIDER
270
90
395
123
p2-infectados-inicial
p2-infectados-inicial
0
10
5.0
1
1
NIL
HORIZONTAL

TEXTBOX
105
785
255
803
POR DESARROLLAR
11
0.0
1

SLIDER
5
55
135
88
efectividad-mp
efectividad-mp
1
10
3.0
1
1
NIL
HORIZONTAL

MONITOR
640
520
690
565
R0 P1
r0-p1
2
1
11

MONITOR
915
520
975
565
R0 P2
r0-p2
2
1
11

PLOT
395
640
670
785
Infectados y Recuperados (Acumulativo)
dias
% total pob.
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"% inf p1" 1.0 0 -15973838 true "" "plot (((count p1s with [ cured? ] + count p1s with [ infected? ]) / count p1s) * 100)"
"% rec p1" 1.0 0 -10899396 true "" "plot ((count p1s with [ cured? ] / count p1s) * 100)"
"% inf p2" 1.0 0 -12186836 true "" "plot (((count p2s with [ cured? ] + count p2s with [ infected? ]) / count p2s) * 100)"
"% rec p2" 1.0 0 -5825686 true "" "plot ((count p2s with [ cured? ] / count p2s) * 100)"

SWITCH
395
800
495
833
hospitales?
hospitales?
1
1
-1000

MONITOR
580
520
640
565
Fallecidos
muertes-p1
0
1
11

MONITOR
855
520
915
565
Fallecidos
Muertes-P2
0
1
11

SLIDER
270
20
395
53
p2-poblacion
p2-poblacion
0
500
300.0
10
1
NIL
HORIZONTAL

TEXTBOX
5
0
155
18
Variables Globales
12
0.0
1

TEXTBOX
420
525
500
543
País 1
14
52.0
1

TEXTBOX
700
525
770
543
País 2
14
122.0
1

PLOT
0
475
395
625
Histograma Estado de salud de la Población
NIL
NIL
0.0
10.0
0.0
50.0
false
true
"set-current-plot-pen \"p1\"\nset-plot-pen-mode 1\nset-histogram-num-bars 10\n\n\nset-current-plot-pen \"p2\"\nset-plot-pen-mode 1\nset-histogram-num-bars 10\n" ""
PENS
"p1" 1.0 0 -14333415 true "" "histogram [salud] of p1s"
"p2" 1.0 0 -10022847 true "" "histogram [salud] of p2s"

SLIDER
140
55
265
88
por-riesgo-p1
por-riesgo-p1
0
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
270
55
395
88
por-riesgo-p2
por-riesgo-p2
0
20
5.0
1
1
NIL
HORIZONTAL

MONITOR
460
520
517
565
Pob
count p1s
0
1
11

MONITOR
742
520
792
565
pob
count p2s
0
1
11

@#$#@#$#@
# Dispersión espacial y prevención COVID 19 

WORK IN PROGRESS

v0.9

para más información:
Daniel Orellana V. Universidad de Cuenca
daniel.orelana@ucuenca.edu.ec
https://www.twitter.com/temporalista

## De qué se trata?

Este modelo simula la propagación espacial de un virus en dos poblaciones semi-cerradas bajo una serie de condiciones, tales como mobilidad interna, predisposición a la cuarentena, medidas personales de sanidad, etc. El modelo no busca realizar predicciones sino ilustrar cómo afectan los cambios de estas medidas en la propagación del virus. Es una ampliación del modelo epiDEM desarrolado por Yang, C. and Wilensky, U. (2011).

En general, el modelo permite a los usuarios:
1) Entender la dinámica de una enfermedad emergente como el COVID-19 en relación a medidas de control, cuarentenas, prohibición de viajes, etc.
2) Experimentar la comparación de medidas entre dos poblaciones similares
3) Entender el concepto de #AplanarLaCurva para evitar el colapso del sistema de salud
4) (por desarrollar) Explorar el impacto de comportamientos de pánico en algunos comportamientos emergentes: desabastecimiento,  saturación de los hospitales, etc.


## Cómo Funciona?

Existen dos países p1 y p2 divididos por una frontera que no se puede cruzar. Las personas se movilizan libremente dentro de cada país. Dentro de la población surge un virus que infecta a un número reducido de personas (ej 5). El virus se transmite por contacto directo, por lo tanto, cuando una persona sana entra en contacto con alguien infectado, tiene una probabilidad de contagiarse ("probabilidad-contagio").

Una vez infectada, la persona sigue su rutina normal con probabilidad de contagiar a otras persoans, o puede auto-aislarse (tendencia-cuarentena). La infección dura en promedio un tiempo determinado (tiempo-promedio-recuperacion) luego de lo cual, cada día hay la probabilidad de curarse (probabilidad-recuperacion). Las personas pueden cambiar su comportamiento y tomar medidas personales (p-medidas-personales) como lavarse las manos, mantener distancia social, etc. Estas medidas puueden tienen un factor de eficacia (emp) que disminuye la probabilidad de contagio).

Los gráficos representan entre otros datos, el número de infectados en cada país a lo largo del tiempo.



## Cambios con respecto a Yang, C. and Wilensky, U. (2011)
- Inclusión de una variable que representa el estado de salud general de la persona está representado en una escala del 1 al 10. Al inicio, cada persona recibe un valor de saludo de una distribución normal (media=7 std=2). Durante el período sintomático, el estado de salud se deteriora a una tasa DS hasta curarse o hasta llegar a 0 (fallecimiento).

- Cada "país" tiene sus propias variables, por lo que es posible comparar situaciones y medidas distintas.

-  Código reificado para mejorar la legibilidad y extensibilidad.

- Se introduce el factor de " eficacia de medidas personales",es decir, cada agente tiene una probabilidad de adoptar comportamientos que disminuyen la probabilidad de contagio en un factor de eficacia *emp*

- Se introduce como variables el número inicial diferenciado de infectados en cada país.

- Al inicio, cada persona recibe un valor de saludo de una distribución normal (media=7 std=2). Cuando el estado de salud se deteriora hasta 0, la persona fallece.


- El R0 se calcula para cada país de forma independiente para cada pa'is.	


## Algunas características a tomar en cuenta: 

- No está modelado el supuesto de una recaida y se asume inmunidad completa luego de la recuperación.


## Aspectos a revisar:

Potenciales colaboradores pueden enfocarse en revisar y validar algunos aspectos:

- Suposiciones teóricas: El moelo está basado en Yang, C. and Wilensky, U. (2011). Sin embargo, es necesario revisar estas suposiciones (Ej. el R0 es un resultado del modelo) para el caso del COVID (ej, el R0 es calculado como resultado del modelo)

- Características del COVID-19. El modelo es genérico, pero es posible calibrarlo para algunas características del COVID-19: Período de incubación, período sintomático, retardo del autoaislamiento, etc.





## Cómo Usarlo?



## Aspectos a considerar

As with many epidemiological models, the number of people becoming infected over time, in the event of an epidemic, traces out an "S-curve." It is called an S-curve because it is shaped like a sideways S. By changing the values of the parameters using the slider, try to see what kinds of changes make the S curve stretch or shrink.

Whenever there's a spread of the disease that reaches most of the population, we say that there was an epidemic. The reproduction number serves as an indicator for the likeliness of an epidemic to occur, if it is greater than 1. If it is smaller than 1, then it is likely that the disease spread will stop short, and we call this an endemic.

Notice how the introduction of various human behaviors, such as travel, inoculation, isolation and quarantine, help constrain the spread of the disease, and what changes that brings to the population level in terms of rate and time taken of disease spread, as well as the population affected.

## Posibles experimentos


## Expansión del modelo


## Características de los agentes


## Modelos relacionados

epiDEM basic, HIV, Virus and Virus on a Network are related models.

## Cómo citar

Si desea utilizar este modelo, por favor incluir las siguientes citas:

* Orellana, D. (2020) Exploring preventive measures for spatial dispersion of epidemies: An ABM approach based on epiDEMTravelandControl model. Universidad de Cuenca.


Modelo Original:

* Yang, C. and Wilensky, U. (2011).  NetLogo epiDEM Travel and Control model.  http://ccl.northwestern.edu/netlogo/models/epiDEMTravelandControl.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright de esta version: Daniel Orellana, Universidad de Cuenca

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

Copyright del modelo original: 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Yang, C. -->

## Funciones pendientes
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

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
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
@#$#@#$#@
1
@#$#@#$#@
