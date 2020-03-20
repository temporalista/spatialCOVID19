globals
[
  nb-infected-previous ;; Number of infected people at the previous tick
  border               ;; The patches representing the yellow border
  angle                ;; Heading for individuals
  beta-n               ;; The average number of new secondary infections per infected this tick
  gamma                ;; The average number of new recoveries per infected this tick
  r0                   ;; The number of secondary infections that arise due to a single infective introduced in a wholly susceptible population
  muertes
  incubation-time
  hospitales?
  p-tendencia-hospitalizacion
  ;Vulnerables               ;percent of people in a risk group (senior, diabetes, heart condition, etc.)
  ;por-riesgo-p2
  capacidad-hospital
]

turtles-own
[
  infected?            ;; If true, the person is infected.
  cured?               ;; If true, the person has lived through an infection. They cannot be re-infected.
  isolated?            ;; If true, the person is isolated, unable to infect anyone.
  hospitalized?        ;; If true, the person is hospitalized and will recovery in half the tiempo-recuperacion.
  infection-length     ;; How long the person has been infected.
  recovery-time        ;; Time (in hours) it takes before the person has a chance to recover from the infection
  por-deteccion   ;; Chance the person will self-quarantine during any day being infected.
  tendencia-hospitalizacion ;; Chance that an infected person will go to the hospital when infected
  f-medidas-personales   ;; factor de contagio si la persona toma medidas personales de precaución
  continent            ;; Which continent a person lives one, people on continent 1 are squares, people on continent 2 are circles.
  susceptible?         ;; Tracks whether the person was initially susceptible
  nb-infected          ;; Number of secondary infections caused by an infected person at the end of the tick
  nb-recovered         ;; Number of recovered people at the end of the tick
  salud                ;; Estado de salud de la persona
  vulnerable?               ;; está en un grupo de riesgo
  detected?            ;; diagnosed


]

patches-own
[
  hospital?
]
;breed [p1s p1]
;breed [p2s p2]



;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  setup-globals
  crear-poblacion
  setup-people
  infeccion-inicial
  reset-ticks
end

to setup-globals
  ask patches [set pcolor white set hospital? false]
  set hospitales? true
  set incubation-time 5.5  ;Baum et al.https://www.jwatch.org/na51083/2020/03/13/covid-19-incubation-period-update

  if hospitales? [
    set capacidad-hospital camas
    ask patches with [pxcor >= 0 and pxcor < capacidad-hospital and pycor = max-pycor ]
    [ set pcolor blue set hospital? true]
    set p-tendencia-hospitalizacion 50
  ]


end

;; Create poblacion number of people.
;; Those that live on the left are squares; those on the right, circles.

to crear-poblacion
  set-default-shape turtles "circle"

  ask n-of (poblacion) (patches) [sprout 1]

end
to setup-people

 ask turtles [

    set cured? false
    set isolated? false
    set hospitalized? false
    set infected? false
    set susceptible? true
    set vulnerable? false
    set detected? false
    set f-medidas-personales 1
    set salud random-normal 7 2
    if salud <= 0 [set salud 1]

    set size 0.7

    assign-tendency
  ]

end

to infeccion-inicial
  ask n-of infectados turtles
  [ set infected? true
    set susceptible? false
    set infection-length random recovery-time
    if random-float 100 < por-deteccion [set detected? true]
  ]


  ask turtles [
    assign-color
  ]

end


to assign-tendency ;; Turtle procedure

    if (random-float 100 < precauciones-per) [ set f-medidas-personales (1 / efecto-precauciones-per)]
    set tendencia-hospitalizacion random-normal p-tendencia-hospitalizacion (p-tendencia-hospitalizacion / 4)
    if (random-float 100 < Vulnerables) [ set vulnerable? true]
    set por-deteccion tasa-deteccion


  set recovery-time random-normal tiempo-recuperacion (tiempo-recuperacion / 4)

  ;; Make sure recovery-time lies between 0 and 2x tiempo-recuperacion
  if recovery-time > tiempo-recuperacion * 2 [ set recovery-time (tiempo-recuperacion * 2) ]
  if recovery-time < 0 [ set recovery-time 0 ]

  ;; Similarly for isolation and hospital going tendencies

  if tendencia-hospitalizacion > tendencia-hospitalizacion * 2 [ set tendencia-hospitalizacion (tendencia-hospitalizacion * 2) ]
  if tendencia-hospitalizacion < 0 [ set tendencia-hospitalizacion 0 ]

end


;; Different people are displayed in 5 different colors depending on health

to assign-color ;; turtle procedure


  ifelse vulnerable?
  [set color 45]
  [set color 85]

  ifelse cured?
  [ set color green ]
  [ if infected?
    [ifelse salud <= 4
      [set color red]
      [ifelse detected?
          [ifelse hospitalized?
            [set color white]
            [set color blue]
        ]
      [set color 115]
    ]
  ]
  ]



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
    [ if infected? and not isolated? and not hospitalized?
         [ infect ] ]

  ;; isolation depends on por-deteccion and infection length (when simptoms appear Backer et al., 2020)
  ask turtles
    [ if not isolated? and not hospitalized?
      and (infection-length >= random-normal incubation-time incubation-time / 2 )
      and infected?
      and detected?
        [ isolate ] ]

  if hospitales? [
    ask turtles
    [ if not hospitalized?
      and infected?
      and salud < 2
      and (random 100 < tendencia-hospitalizacion)
      and capacidad-hospital > 0
      [ hospitalize ]
    ]
  ]

  ask turtles
    [ if infected?
       [ maybe-recover ]
    ]

  ask turtles
    [ if (isolated? or hospitalized?
      ) and cured?
        [ unisolate ] ]


  ask turtles
    [ if not isolated? and not hospitalized?
        [ move ] ]

  ask turtles
  [ calcular-salud]

    ask turtles
    [ assign-color
      calculate-r0
  ]

  tick
end

to calcular-salud

  if infected?[
    ifelse hospitalized?[
      ifelse vulnerable?
      [set salud salud - 0.1]    ;riesgo, hospitalizado
      [set salud salud - 0.05]   ;no riesgo, hospitalizado
    ]
    [ifelse vulnerable?
      [set salud salud - 0.5]    ;riesgo, no hospitalizado
      [set salud salud - 0.02]   ;riesgo, no hospitalizado
    ]
   ]

  if salud <= 0 [
    set muertes (muertes  + 1)
    ask (patch-at 0 0) [
      ifelse hospital? = true
      [set pcolor blue ]
      [set pcolor white ]
    ]
    if hospitalized? = true [
    set hospitalized? false
    set capacidad-hospital capacidad-hospital + 1
  ]

    die
    ]

  if (cured? and salud < 10)
    [set salud salud + 0.1]

end


to move  ;; turtle procedure

;      ifelse xcor < (min-pxcor + 0.5)  ;; at the edge of world
;      [
;        set angle random-normal 180 10
;      ]
      rt random-normal 0 90
      fd random-normal movilidad movilidad / 2
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
  [ ifelse salud < 4
    [        if infection-length > recovery-time * 2 ; severe and critical cases twice recovery time
      [
        if random-float 100 < (probabilidad-recuperacion)
        [
          set infected? false
          set cured? true
          set nb-recovered (nb-recovered + 1)
        ]
      ]
    ]
    [if infection-length > recovery-time
      [
        if random-float 100 < probabilidad-recuperacion
        [
          set infected? false
          set cured? true
          set nb-recovered (nb-recovered + 1)
        ]
      ]
    ]
  ]

  [ ;; If hospitalized, recover in a half of the recovery time
    if infection-length > (recovery-time / 2)
    [
      if random-float 100 < probabilidad-recuperacion
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
  ask (patch-at 0 0) [ set pcolor gray + 3]
end

;; After unisolating, patch turns back to normal color
to unisolate  ;; turtle procedure
  set isolated? false
  ask (patch-here)
  [ifelse hospital? = true
    [set pcolor blue]
    [set pcolor white]
  ]
  if hospitalized? = true [
    set hospitalized? false
    set capacidad-hospital capacidad-hospital + 1
    ask patch-here [set pcolor blue]
  ]

end

;; To hospitalize, move to one of the hospital patches
to hospitalize ;; turtle procedure
  set hospitalized? true
  set capacidad-hospital capacidad-hospital - 1
  if isolated? [
    ask patch-here [set pcolor white]
  ]
  move-to one-of patch-set patches with [hospital? = true and pcolor = blue]
  ask patch-here [set pcolor blue   + 3]
end

;; Infected individuals who are not isolated or hospitalized have a chance of transmitting their disease to their susceptible neighbors.
;; If the neighbor is linked, then the chance of disease transmission doubles.

to infect  ;; turtle procedure

  let caller self

  let nearby-uninfected (turtles-on neighbors) with [ not infected? and not cured?]
  if nearby-uninfected != nobody
  [
    ask nearby-uninfected
    [
      ifelse link-neighbor? caller ;; twice as likely to infect a linked person
      [
        if random 100 < probabilidad-contagio * f-medidas-personales * 2
        [
          set infected? true
          if random-float 100 < por-deteccion [set detected? true]
          set nb-infected (nb-infected + 1)
        ]
      ]
      [
        if random 100 < probabilidad-contagio * f-medidas-personales
        [
          set infected? true
          if random-float 100 < por-deteccion [set detected? true]
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




; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
375
65
793
484
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
days
15.0

BUTTON
475
10
560
43
Generar Mundo
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
560
10
647
43
Iniciar
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
0
10
92
43
Poblacion
Poblacion
0
1000
600.0
20
1
NIL
HORIZONTAL

SLIDER
180
45
285
78
Tasa-Deteccion
Tasa-Deteccion
0
50
0.0
1
1
NIL
HORIZONTAL

PLOT
0
155
370
435
Poblacion infectada
dias
# personas
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"Infectados" 1.0 0 -11783835 true "" "plot (count turtles with [ infected?])"

SLIDER
5
450
145
483
probabilidad-contagio
probabilidad-contagio
1
50
26.0
1
1
NIL
HORIZONTAL

SLIDER
145
485
285
518
probabilidad-recuperacion
probabilidad-recuperacion
10
50
10.0
1
1
NIL
HORIZONTAL

SLIDER
180
80
285
113
movilidad
movilidad
0
2
1.0
0.2
1
NIL
HORIZONTAL

SLIDER
145
450
285
483
tiempo-recuperacion
tiempo-recuperacion
10
60
10.0
5
1
NIL
HORIZONTAL

BUTTON
645
10
725
43
+1 día
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
0
45
92
78
Infectados
Infectados
0
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
550
485
615
530
Infectados
count turtles with [ infected?]
0
1
11

SLIDER
180
10
285
43
precauciones-per
precauciones-per
0
100
0.0
5
1
NIL
HORIZONTAL

SLIDER
5
485
145
518
efecto-precauciones-per
efecto-precauciones-per
1
10
2.0
1
1
NIL
HORIZONTAL

PLOT
5
525
370
740
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
"% infectados" 1.0 0 -11783835 true "" "plot (((count turtles with [ cured? ] + count turtles with [ infected? ] + muertes) / count turtles) * 100)"
"% recuperados" 1.0 0 -10899396 true "" "plot ((count turtles with [ cured? ] / count turtles) * 100)"

MONITOR
730
530
790
575
Fallecidos
muertes
0
1
11

TEXTBOX
5
435
155
453
Características del virus
12
0.0
1

SLIDER
0
80
92
113
Vulnerables
Vulnerables
0
50
20.0
1
1
NIL
HORIZONTAL

MONITOR
670
485
740
530
Detectados
count turtles with [detected?]
0
1
11

TEXTBOX
380
485
565
580
Celeste = Sanos\nAmarillo = Vulnerables\nVioleta = Infectados no aislados\nRecuadro  = Infectados aislados\nRojo  = En estado crítico\nVerde = Recuperados
11
0.0
1

MONITOR
740
485
790
530
Críticos
count turtles with [ salud <= 2]
0
1
11

TEXTBOX
95
15
145
41
Poblacion Total
11
0.0
1

TEXTBOX
95
50
170
75
Infectados iniciales
11
0.0
1

TEXTBOX
95
80
160
110
% en grupos de riesgo
11
0.0
1

TEXTBOX
290
15
365
45
% que adopta precauciones
11
0.0
1

TEXTBOX
290
50
365
76
% detección y aislamiento
11
0.0
1

TEXTBOX
290
85
365
115
Movilidad de la población
11
0.0
1

MONITOR
550
530
645
575
Hospitalizados
count turtles with [hospitalized? = true]
0
1
11

MONITOR
645
530
730
575
capacidad hosp
capacidad-hospital
0
1
11

SLIDER
0
115
92
148
camas
camas
0
10
3.0
1
1
NIL
HORIZONTAL

TEXTBOX
95
115
150
141
Camas de \nHospital
11
0.0
1

MONITOR
615
485
672
530
Acum
(count turtles with [ cured? ] + count turtles with [ infected? ] + muertes)
0
1
11

TEXTBOX
580
50
630
68
HOSPITAL
11
0.0
1

PLOT
390
575
790
740
Sistema de Salud
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
"Capacidad Hospitalaria" 1.0 0 -16777216 true "" "plot camas"
"Hospitalizados" 1.0 0 -14070903 true "" "plot count turtles with [hospitalized?]"

MONITOR
315
475
372
520
R0
R0
2
1
11

@#$#@#$#@
# Dispersión espacial y prevención de epidemias

WORK IN PROGRESS

v0.9

para más información:
Daniel Orellana V. Universidad de Cuenca
daniel.orelana@ucuenca.edu.ec
https://www.twitter.com/temporalista

## De qué se trata?

Este modelo simula la propagación espacial de un virus en una población bajo una serie de condiciones, tales como mobilidad interna, predisposición a la cuarentena, medidas personales de sanidad, etc. El modelo no busca realizar predicciones sino ilustrar cómo afectan los cambios de estas medidas en la propagación del virus. Es una ampliación del modelo epiDEM desarrolado por Yang, C. and Wilensky, U. (2011).

En general, el modelo permite a los usuarios:
1) Entender la dinámica de una enfermedad emergente como el COVID-19 en relación a medidas de control, cuarentenas, prohibición de viajes, etc.
2) Experimentar la comparación de medidas
3) Entender el concepto de #AplanarLaCurva para evitar el colapso del sistema de salud
4) Explorar el impacto en la saturación de los hospitales.


## Cómo Funciona?

Las personas se movilizan libremente dentro del territorio. Surge un virus que infecta a un número reducido de personas (ej 5). El virus se transmite por contacto directo, por lo tanto, cuando una persona sana entra en contacto con alguien infectado, tiene una probabilidad de contagiarse ("probabilidad-contagio").

Una vez infectada, la persona sigue su rutina normal con probabilidad de contagiar a otras personas. Cuando presenta síntomas, puede ser detectada según el % de la tasa de detección que tenga el sistema de salud y será aislado. La infección dura en promedio un tiempo determinado (tiempo-recuperacion) luego de lo cual, cada día hay la probabilidad de curarse (probabilidad-recuperacion). Las personas pueden cambiar su comportamiento y tomar medidas personales (p-medidas-personales) como lavarse las manos, mantener distancia social, etc. Estas medidas puueden tienen un factor de eficacia (emp) que disminuye la probabilidad de contagio).

Cada persona tiene un índice de salud de 0 a 10. La enfermedad disminuirá su salud. Además si es vulnerable, su salud disminuirá más rápido. Las personas en estado crítico serán trasladadas al hospital donde ocuparán una cama disponible y tendrán mayor probabilidad de recuperarse. Si ya no hay camas disponibles no podrán ingresar al hospital.

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
<experiments>
  <experiment name="experiment deteccion 10 80" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count p2s with [ infected?]</metric>
    <metric>count p2s with [ cured? ]</metric>
    <metric>muertes-p2</metric>
    <steppedValueSet variable="p2-por-deteccion" first="5" step="5" last="80"/>
    <steppedValueSet variable="p2-mobilidad-local" first="0.5" step="0.1" last="1"/>
  </experiment>
</experiments>
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
