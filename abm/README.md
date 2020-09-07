# Dispersión Espacial de Virus y Medidas de Prevención

WORK IN PROGRESS

v1.1

para más información:

Daniel Orellana V. Universidad de Cuenca

daniel.orelana@ucuenca.edu.ec

[https://www.twitter.com/temporalista](https://www.twitter.com/temporalista)

![interfaz](https://raw.githubusercontent.com/temporalista/spatialCOVID19/master/virus_spread_interface.png "Interface del modelo")




## De qué se trata?

Este modelo simula la propagación espacial de un virus, como COVID-19 en dos poblaciones semi-cerradas bajo una serie de condiciones, tales como mobilidad interna, predisposición a la cuarentena, medidas personales de sanidad, etc. El modelo **no busca realizar predicciones** sino ilustrar cómo afectan los cambios de estas medidas en la propagación del virus. Es una ampliación del modelo epiDEM desarrolado por Yang, C. and Wilensky, U. (2011).

En general, el modelo permite a los usuarios:
1) Entender la dinámica de una enfermedad emergente como el COVID-19 en relación a medidas de control, cuarentenas, prohibición de viajes, etc.
2) Experimentar la comparación de medidas entre dos poblaciones similares
3) Entender el concepto de #AplanarLaCurva para evitar el colapso del sistema de salud
4) (por desarrollar) Explorar el impacto de comportamientos de pánico en algunos comportamientos emergentes: desabastecimiento,  saturación de los hospitales, etc.

## Como Iniciarlo?
Puede [lanzar el modelo directamente en el navegador](https://temporalista.github.io/spatialCOVID19/epiDEM%20COV_v1.1.html) (la simulación puede ser un poco lenta):

Para mayor velocidad y funcionalidades adicionales, [descargar](https://github.com/temporalista/spatialCOVID19/raw/master/epiDEM%20COV_v1.1.nlogo.zip) y descomprimir el modelo  y abrirlo en [NetLogo](https://ccl.northwestern.edu/netlogo/)

## Cómo Funciona?

Existen dos países p1 y p2 divididos por una frontera que no se puede cruzar. Las personas se movilizan libremente dentro de cada país. Dentro de la población surge un virus que infecta a un número reducido de personas (ej 5). El virus se transmite por contacto directo, por lo tanto, cuando una persona sana entra en contacto con alguien infectado, tiene una probabilidad de contagiarse ("probabilidad-contagio").

Una vez infectada, la persona sigue su rutina normal con probabilidad de contagiar a otras persoans, o puede auto-aislarse (tendencia-cuarentena). La infección dura en promedio un tiempo determinado (tiempo-promedio-recuperacion) luego de lo cual, cada día hay la probabilidad de curarse (probabilidad-recuperacion). Las personas pueden cambiar su comportamiento y tomar medidas personales (p-medidas-personales) como lavarse las manos, mantener distancia social, etc. Estas medidas puueden tienen un factor de eficacia (emp) que disminuye la probabilidad de contagio).

Los gráficos representan entre otros datos, el número de infectados en cada país a lo largo del tiempo.


## Instrucciones de uso
La primera vez se puede iniciar el modelo con los parámetros por defecto. 

Al hacer click en "Inicializar" se creará un mundo con dos países con una poblaciones definidas por el control *poblacion*. Además en cada país aparecerá inicialmente un número de personas infectadas (control *infectados-inicial*) que aparecerán en color amarillo. Cada persona  tendrá asignado un índice que representa su estado general de salud en una escala de 0 a 10 asignada con una distribución normal (media=7, SD=2). Además, un porcentaje de la población (por-riesgo) se considerará grupo de riesgo debido a su edad o condiciones previas. 

### Movilidad y contagio
Al hacer click en "Ejecutar" iniciará el modelo. Las personas se movilizan libremente por su país en una distancia definida por el control *movilidad-local* (distribución normal, med=movilidad local, SD=movilidad local /4). Cuando una persona se encuentra con alguien infectado, tiene una probabilidad de contagiarse (control *prob-contagio*), en caso de contagiarse, su color cambia a rojo y puede a su vez contagiar a otras personas. La persona infectada permanecerá enferma durante un tiempo promedio (control *tiempo-promedio-recuperacion*), a partir del cual tendrá diariamente una probabilidad de recuperarse (control *prob-recuperacion*). Las personas que se hayan curado cambian de color a verde y se asume que son inmunes a nuevos contagios (lo cual puede cambiar para el covid-19). La simulación termina cuando no existan más personas infectadas.

### Afectación a la salud
Mientras están infectadas, el índice de salud de una persona disminuirá a una tasa de 0.5/día si pertenece a un grupo de riesgo o de 0.02/día de lo contrario. En caso de hospitalizarse, las salud de las personas del grupo de riesgo disminuirá 0.2/día y 0.01 los demás. Cuando el índice de salud baja por debajo de 2, se considera en estado crítico y su color cambia a rojo. Al llegar a 0 la persona fallece. Cuando la persona se recupera de la enfermedad, su estado de salud aumenta a razón de 0.1/día hasta llegar a 10 (o el estado inicial en futuras versiones).

### Medidas de prevención
Cada país puede tomar algunas medidas de prevención. Por ejemplo se puede restringir la movilidad local de las personas (*mobilidad-local*), solicitar a las personas que hagan cuarentena cuando presentan síntomas (*tend-cuarentena*) o implementar campañas de publicidad para que las personas adquieran comportamientos de prevención (*med-personales*).

El usuario puede modificar estos valores en ambos países y comparar los resultados en una nueva simulación.


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


## Aspectos a considerar


## Posibles experimentos


## Expansión del modelo
Futuras versiones incorporarán las siguientes funcionalidades:
- Asignar rangos de edad a los agentes
- Simular comportamientos de pánico (compras impulsivas y desabastecimiento)
- Modelar el "respeto parcial" de la cuarentena (añadir probabilidades de  reducción del tiempo de distanciamiento social de los agentes)

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
