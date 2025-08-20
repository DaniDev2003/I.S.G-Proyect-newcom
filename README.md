# newcon

Proyecto hecho en flutter para practicas profesionalizantes por el 2do año de tecnicatura 
superior en desarrollo de software del instituto superior goya.

## Getting Started

- Flujo normal de uso

  - Cargar los datos: Se ingresan los jugadores disponibles, indicando su género, rol y puntaje.
  - Elegir jugadores: Se selecciona el grupo de personas que participará en el sorteo.
  - Realizar el sorteo: La app reparte automáticamente a los jugadores entre los equipos.
  - Jugar: Ya con los equipos balanceados, se puede comenzar la partida.
  - Gestión en vivo:
      - Si un jugador se va, la app propone un suplente adecuado.
      - Si un jugador entra, se lo asigna al equipo más conveniente según reglas de equilibrio.

- Prioridades del sorteo

  - El sistema no asigna jugadores al azar, sino que sigue un orden de prioridades para mantener equidad y diversión:
  - Género → Intenta que haya la misma cantidad de hombres y mujeres en los equipos.
  - Roles → Se asegura de que cada equipo tenga representación de los distintos roles (ej: arquero, defensor, delantero).
  - Puntaje → Equilibra el nivel de habilidad, para que los equipos queden parejos.
  - Suplentes → Si sobran jugadores, se asignan como suplentes.
  
- Escenario 1: Un jugador se va

  - La app busca un suplente de cualquier equipo que:
  - Mantenga el equilibrio de género.
  - Cubra el rol faltante.
  - No desbalancee el puntaje entre equipos.
  - Si hay varias opciones, elige la más conveniente y asigna este jugador al equipo del cual salio el jugador titula como nuevo titular.
  
- Escenario 2: Llega un nuevo jugador

  - Se revisa cuál equipo está más débil (según puntaje, género o rol).
  - El nuevo jugador se asigna a ese equipo como suplente.
  - Se revisa el nuevo equilibrio y busca intercambios de suplentes inteligentes para volver a equilibrar los puntajes y roles.
  
- Escenario 3: Cambios múltiples

  - Si salen y entran varios jugadores, el sistema vuelve a balancear automáticamente manteniendo las reglas.