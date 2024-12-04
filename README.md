# Blockchain en Elixir
- Flores Linares Oscar Daniel: 320208591 
- Márquez Corona Danna Lizette: 320279991

Este proyecto consiste en desarrollar una **blockchain** funcional para un sistema de criptomonedas, implementada en **Elixir**. 

El sistema puede manejar múltiples procesos que representan a los usuarios. Entre sus funcionalidades principales se incluyen: 
- Envío de mensajes entre usuarios.
- Alcance de un consenso distribuido.
- Detección y eliminación de procesos maliciosos que intenten alterar la blockchain.

En este proyecto implementamos el algoritmo de consenso PBFT, el cual consta de 3 fases las cuales son: 
- Pre-preparación: El líder propone un bloque a todos los nodos, quienes verifican si el mensaje es válido antes de proceder.
- Preparación: Los nodos envían mensajes de preparación para confirmar que el bloque recibido en Pre-Prepare es consistente y válido.
- Compromiso: Los nodos intercambian mensajes de compromiso, asegurando que la mayoría acepta el bloque antes de agregarlo a la blockchain.

Mismas que se verán reflejadas en una simulación implementada en nuestro Main para mostrar explícitamente cada fase. Finalizando por una fase de
conseso final el cual mostrará la información detallada de todos los nodos, tanto los bizantinos como los honestos.

Toda la información en base a la decisión de hacer el algoritmo PBFT se encuentra en nuestra primera parte del proyecto, del cual cabe recalcar una adición de un módulo más
para poder manejar de manera eficiente la parte de los nodos. Este módulo es llamado `NodoPBFT`. El cuál explicamos su funcionamiento en la documentación del código y en este mismo Readme.

## Requisitos

- Elixir 1.12 o superior.

## Características Principales

1. **Crypto**
   - Módulo encargado de realizar hasheos usando SHA-256.

2. **Block**
   - Representa un bloque en la blockchain.
   - Contiene los atributos: `data`, `timestamp`, `prev_hash`, y `hash`.
   - Funciones principales:
     - `new/2`: Crea un bloque nuevo.
     - `valid?/1`: Valida que un bloque sea consistente.
     - `valid?/2`: Valida que dos bloques sean secuenciales.

3. **Blockchain**
   - Representa la blockchain como una lista de bloques.
   - Funciones principales:
     - `new/0`: Inicializa una blockchain con un bloque génesis.
     - `insert/2`: Agrega un bloque nuevo.
     - `valid?/1`: Verifica que toda la blockchain sea válida.

4. **ConsensusManager**
   - Gestiona el proceso de consenso en un sistema PBFT.  
   - Contiene los atributos: `id_nodo`, `vista`, `bloque_actual`, `estado`, `fase`, `votos_preparacion`, `votos_compromiso`, `f`, y `total_nodos`.  
   - Funciones principales:  
     - `inicial/3`: Inicializa el gestor de consenso para un nodo.  
     - `iniciar_consenso/2`: Comienza el consenso para un bloque.  
     - `manejar_voto_preparacion/3`: Procesa votos en la fase de preparación.  
     - `manejar_voto_compromiso/3`: Maneja votos en la fase de compromiso.  
     - `quorum_alcanzado?/3`: Verifica si se alcanzó el quorum.  
     - `rotar_lider/2`: Determina el nuevo líder según la vista actual.

5. **NetworkManager**  
   - Gestiona las conexiones y la comunicación entre nodos.  
   - Contiene los atributos: `id_nodo` y `peer` (pares conectados).  
   - Funciones principales:  
     - `inicial/2`: Inicializa un gestor de red para un nodo.  
     - `conectar_peer/3`: Conecta un nuevo par al gestor de red.  
     - `enviar_mensaje/3`: Envía un mensaje a un nodo específico.

6. **NodoPBFT**  
   - Define el comportamiento de un nodo en el sistema PBFT.  
   - Contiene los atributos: `id`, `blockchain`, `consensus_manager`, `network_manager`, `es_bizantino`.  
   - Funciones principales:  
     - `inicial/4`: Inicializa un nodo PBFT con configuración específica.  
     - `procesar_mensaje/2`: Procesa mensajes según si el nodo es honesto o bizantino.  
     - `manejar_mensaje_normal/2`: Maneja mensajes de pre-preparación, preparación y compromiso para nodos honestos.  
     - `manejar_mensaje_bizantino/2`: Maneja mensajes de pre-preparación, preparación y compromiso para nodos bizantinos.  
     - `comportamiento_malicioso/4`: Simula un comportamiento malicioso en un nodo bizantino.
      
7. **Main**  
   - Simula el algoritmo PBFT entre nodos honestos y bizantinos.  
   - Contiene las siguientes funciones principales:  
     - **`run/2`**: Ejecuta la simulación del algoritmo PBFT. Inicializa los nodos, conecta entre sí, simula las fases de consenso (Pre-Prepare, Prepare y Commit) y muestra el estado final de consenso.  
     - **`simular_consenso/2`**: Simula las fases del consenso PBFT. Durante cada fase (Pre-Prepare, Prepare y Commit), procesa los mensajes de los nodos honestos y bizantinos, mostrando información sobre los bloques y nodos.  
     - **`print_consenso_final/1`**: Imprime el estado final de consenso de todos los nodos, destacando los nodos honestos y bizantinos utilizando colores para facilitar la visualización de los distintos componentes de cada nodo, como el `consensus_manager`, `network_manager` y `es_bizantino`.  

   - **Atributos**:  
     - `n`: Número total de nodos en la red.  
     - `f`: Número máximo de nodos bizantinos tolerados.  
     - `nodos`: Lista de nodos creados para la simulación, algunos marcados como bizantinos.  
   
   - **Fases de consenso simuladas**:  
     - **Pre-Prepare**: Los nodos reciben y procesan el bloque inicial.  
     - **Prepare**: Los nodos honestos envían mensajes de preparación; los nodos bizantinos envían bloques maliciosos.  
     - **Commit**: Los nodos procesan mensajes de compromiso para confirmar el bloque.
    
Nuestro código tratamos de hacerlo lo más completo posible, poniendo los primeros 2 nodos como bizantinos, para que en la simulación se vea reflejado su comportamiento mediante el algoritmo PBFT. A su vez, insertamos un bloque "Bloque 1", para
que también se vea el funcionamiento del hash en los nodos honestos, e insertamos un "Bloque Malicioso" en estos nodos bizantinos. 

Al tratar de mostrar toda la simulación de nuestro algoritmo puede que simular una red pueda mostrar una ejecución algo extensa pero definitivamente con el propósito de mostrar visualmente cada fase de PBFT y la información
detallada de cada nodo, esto hecho a propósito para demostrar un correcto funcionamiento de nuestro código. 

Nota: Algunas funciones recursivas y funciones que complementaron e hicieron más robusto nuestro código fueron generadas por inteligencia artificial, esto para una mayor eficacia en la simulación completa al ejecutar el código, pero siempre cuidando la no dependencia de la misma IA. :)
Adicionalmente, también aclarar que son muchas lineas de código en PBFT, más que nada por la documentación. (Mismo caso para código Main)

## Ejemplo de Uso (para simular una red recomendaría hacerlo con 7 nodos y 2 procesos bizantinos, esto debido a que nos inclinamos a mostrar una simulación completa del código, por lo que intentar con "Main.run(10,2)" podría mostrar una ejecución bastante extensa, peroal final es solo una recomendación, pues de igual manera funciona con 10 nodos ;))

```elixir
# Cargar los códigos PBFT.ex y Main.ex
iex> c("PBFT.ex")
iex> c("Main.ex")

# Inicializa una blockchain
iex> blockchain = Blockchain.new()

# Inserta una transacción
iex> blockchain = Blockchain.insert(blockchain, "Transacción 1")

# Valida la blockchain
iex> Blockchain.valid?(blockchain)
true

# Simula una red con 10 nodos y 2 procesos bizantinos
iex> Main.run(10, 2)
--- Información de Nodos Bizantinos --- ...
