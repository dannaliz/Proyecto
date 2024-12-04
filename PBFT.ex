defmodule Crypto do
  @moduledoc """
  Módulo para operaciones criptográficas básicas en la blockchain.
  Proporciona funcionalidades de hashing seguro.
  """
  @doc """
  Genera un hash SHA-256 de los datos proporcionados.
  ## Parámetros
  - data: Los datos a hashear
  ## Retorna
  - Una cadena hexadecimal en minúsculas del hash generado
  """
  def hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end
end

defmodule Block do
  @moduledoc """
  Representa un bloque individual en la blockchain.
  Contiene datos, marca de tiempo, hash previo y hash actual.
  """
  defstruct [:data, :timestamp, :prev_hash, :hash]
  @doc """
  Crea un nuevo bloque con los datos proporcionados y el hash previo.
  ## Parámetros
  - data: Contenido del bloque
  - prev_hash: Hash del bloque anterior en la cadena
  ## Retorna
  - Una estructura de bloque con todos los campos generados
  """
  def new(data, prev_hash) do
    timestamp = :os.system_time(:seconds)
    hash = Crypto.hash("#{data}#{timestamp}#{prev_hash}")
    %Block{data: data, timestamp: timestamp, prev_hash: prev_hash, hash: hash}
  end

  @doc """
  Valida la integridad de un bloque individual.
  ## Parámetros
  - block: Bloque a validar
  ## Retorna
  - Booleano indicando si el bloque es válido
  """
  def valid?(%Block{data: data, timestamp: timestamp, prev_hash: prev_hash, hash: hash}) do
    expected_hash = Crypto.hash("#{data}#{timestamp}#{prev_hash}")
    hash == expected_hash
  end

  @doc """
  Valida la secuencialidad de dos bloques consecutivos.
  ## Parámetros
  - block1: Bloque anterior
  - block2: Bloque actual
  ## Retorna
  - Booleano indicando si los bloques están correctamente enlazados
  """
  def valid?(%Block{} = block1, %Block{} = block2) do
    block2.prev_hash == block1.hash
  end
end

defmodule Blockchain do
  @moduledoc """
  Gestiona la cadena de bloques completa, permitiendo inserción y validación.
  """
  defstruct blocks: []

  @doc """
  Inicializa una nueva blockchain con un bloque génesis.
  ## Retorna
  - Una estructura de blockchain con el bloque inicial
  """
  def new() do
    genesis_block = Block.new("Genesis Block", "0")
    %Blockchain{blocks: [genesis_block]}
  end

  @doc """
  Inserta un nuevo bloque al final de la blockchain.
  ## Parámetros
  - chain: Blockchain actual
  - data: Datos para el nuevo bloque
  ## Retorna
  - Nueva blockchain con el bloque añadido
  """
  def insert(%Blockchain{blocks: blocks} = chain, data) do
    last_block = List.last(blocks)
    new_block = Block.new(data, last_block.hash)
    %Blockchain{blocks: blocks ++ [new_block]}
  end

  @doc """
  Valida la integridad completa de la blockchain.
  ## Parámetros
  - Blockchain a validar
  ## Retorna
  - Booleano indicando si toda la cadena es válida
  """
  def valid?(%Blockchain{blocks: []}), do: false
  def valid?(%Blockchain{blocks: [_]}), do: true
  def valid?(%Blockchain{blocks: [block1, block2 | rest]}) do
    Block.valid?(block1) && Block.valid?(block1, block2) && valid?(%Blockchain{blocks: [block2 | rest]})
  end
end

defmodule ConsensusManager do
  @moduledoc """
  Gestiona el proceso de consenso en un sistema distribuido.
  Implementa la lógica para alcanzar consenso entre múltiples nodos.
  """
  defstruct [id_nodo: nil, vista: 0, bloque_actual: nil, estado: :inicial, votos_preparacion: %{}, votos_compromiso: %{}, f: 0, total_nodos: 0, fase: :inicial]

  @doc """
  Inicializa un nuevo gestor de consenso para un nodo específico.
  ## Parámetros
  - id_nodo: Identificador único del nodo
  - total_nodos: Número total de nodos en la red
  - f: Número de nodos bizantinos tolerados
  ## Retorna
  - Una estructura de ConsensusManager inicializada
  """
  def inicial(id_nodo, total_nodos, f) do
    %ConsensusManager{id_nodo: id_nodo, total_nodos: total_nodos, f: f}
  end

  @doc """
  Inicia el proceso de consenso para un bloque específico.
  ## Parámetros
  - estado: Estado actual del ConsensusManager
  - block: Bloque para iniciar el consenso
  ## Retorna
  - Estado actualizado del ConsensusManager
  """
  def iniciar_consenso(%ConsensusManager{} = estado, block) do
    %{estado | bloque_actual: block, estado: :pre_preparado, fase: :pre_preparacion, votos_preparacion: %{block.hash => [estado.id_nodo]}, votos_compromiso: %{}}
  end

  @doc """
  Maneja los votos de preparación durante el proceso de consenso.
  ## Parámetros
  - estado: Estado actual del ConsensusManager
  - block: Bloque en proceso de consenso
  - emisor: Identificador del nodo que emite el voto
  ## Retorna
  - Estado actualizado del ConsensusManager
  """
  def manejar_voto_preparacion(%ConsensusManager{} = estado, block, emisor) do
    votos = Map.update(estado.votos_preparacion, block.hash, [emisor], fn existentes ->
      if emisor in existentes, do: existentes, else: [emisor | existentes]
    end)

    estado_actualizado = %{estado | votos_preparacion: votos}

    if quorum_alcanzado?(votos, estado.total_nodos, estado.f) do
      %{estado_actualizado | estado: :preparado, fase: :preparacion}
    else
      estado_actualizado
    end
  end

  @doc """
  Maneja los votos de compromiso durante el proceso de consenso.
  ## Parámetros
  - estado: Estado actual del ConsensusManager
  - block: Bloque en proceso de consenso
  - emisor: Identificador del nodo que emite el voto
  ## Retorna
  - Estado actualizado del ConsensusManager
  """
  def manejar_voto_compromiso(%ConsensusManager{} = estado, block, emisor) do
    votos = Map.update(estado.votos_compromiso, block.hash, [emisor], fn existentes ->
      if emisor in existentes, do: existentes, else: [emisor | existentes]
    end)

    estado_actualizado = %{estado | votos_compromiso: votos}

    if quorum_alcanzado?(votos, estado.total_nodos, estado.f) do
      %{estado_actualizado | estado: :comprometido, fase: :compromiso}
    else
      estado_actualizado
    end
  end

  @doc """
  Determina si se ha alcanzado un quorum de votos.
  ## Parámetros
  - votos: Mapa de votos recibidos
  - total_nodos: Número total de nodos en la red
  - f: Número de nodos bizantinos tolerados
  ## Retorna
  - Booleano indicando si se alcanzó el quorum
  """
  def quorum_alcanzado?(votos, total_nodos, f) do
    Enum.any?(votos, fn {_hash, emisores} ->
      emisores_unicos = Enum.uniq(emisores)
      length(emisores_unicos) >= (total_nodos - f - 1)
    end)
  end

  @doc """
  Rota el líder en función de la vista actual.
  ## Parámetros
  - vista: Vista actual del sistema
  - total_nodos: Número total de nodos
  ## Retorna
  - Identificador del nuevo nodo líder
  """
  def rotar_lider(vista, total_nodos), do: rem(vista, total_nodos) + 1
end

defmodule NetworkManager do
  @moduledoc """
  Gestiona las conexiones de red y comunicación entre nodos.
  Permite la conexión y el envío de mensajes entre los pares.
  """
  defstruct [id_nodo: nil, peer: %{}]

  @doc """
  Inicializa un NetworkManager para un nodo específico.
  ## Parámetros
  - id_nodo: Identificador del nodo
  - id_peer: Lista de identificadores de pares
  ## Retorna
  - Una estructura de NetworkManager inicializada
  """
  def inicial(id_nodo, id_peer) do
    %NetworkManager{id_nodo: id_nodo, peer: Map.new(id_peer, fn id -> {id, nil} end)}
  end

  @doc """
  Conecta un nuevo par al NetworkManager.
  ## Parámetros
  - network: NetworkManager actual
  - peer_id: Identificador del par
  - pid: Identificador de proceso del par
  ## Retorna
  - NetworkManager actualizado con el nuevo par conectado
  """
  def conectar_peer(%NetworkManager{} = network, peer_id, pid) do
    %{network | peer: Map.put(network.peer, peer_id, pid)}
  end

  @doc """
  Envía un mensaje a un nodo específico.
  ## Parámetros
  - network: NetworkManager actual
  - id_destinatario: Identificador del nodo destinatario
  - mensaje: Mensaje a enviar
  ## Retorna
  - NetworkManager posiblemente modificado
  """
  def enviar_mensaje(%NetworkManager{} = network, id_destinatario, mensaje) do
    case Map.get(network.peer, id_destinatario) do
      nil ->
        IO.puts("Nodo #{id_destinatario} desconectado. Mensaje perdido.")
        network
      pid ->
        send(pid, mensaje)
        network
    end
  end
end

defmodule NodoPBFT do
  @moduledoc """
  Este módulo define la estructura y el comportamiento de un nodo en el sistema PBFT (Practical Byzantine Fault Tolerance).
  Un nodo puede ser honesto o bizantino, y maneja mensajes relacionados con las fases de consenso: `Pre-Prepare`, `Prepare` y `Commit`.
  ## Estructura
  - `id`: Identificador único del nodo.
  - `blockchain`: Instancia de la blockchain manejada por el nodo.
  - `consensus_manager`: Estado del consenso del nodo, manejado por el módulo `ConsensusManager`.
  - `network_manager`: Instancia del administrador de red para gestionar comunicación entre nodos.
  - `es_bizantino`: Booleano que indica si el nodo es bizantino o no.
  """
  defstruct [id: nil, blockchain: nil, consensus_manager: nil, network_manager: nil, es_bizantino: false
  ]

  @doc """
  Inicializa un nuevo nodo PBFT con configuración específica.
  ## Parámetros
  - id: Identificador único del nodo
  - total_nodos: Número total de nodos en la red
  - f: Número máximo de nodos bizantinos tolerados
  - es_bizantino: Bandera para indicar si el nodo es bizantino
  ## Retorna
  Una estructura de nodo PBFT completamente inicializada
  """
  def inicial(id, total_nodos, f, es_bizantino \\ false) do
    %NodoPBFT{
      id: id,
      blockchain: Blockchain.new(),
      consensus_manager: ConsensusManager.inicial(id, total_nodos, f),
      network_manager: NetworkManager.inicial(id, Enum.to_list(1..total_nodos)),
      es_bizantino: es_bizantino
    }
  end

  @doc """
  Procesa un mensaje entrante en un nodo honesto.
  ## Parámetros
  - nodo: Nodo PBFT actual
  - mensaje: Mensaje a procesar (puede ser :pre_preparado, :preparado, :comprometido)
  ## Retorna
  El nodo PBFT actualizado después de procesar el mensaje
  """
  def procesar_mensaje(%NodoPBFT{es_bizantino: false} = nodo, mensaje) do
    manejar_mensaje_normal(nodo, mensaje)
  end

  @doc """
  Procesa un mensaje entrante en un nodo bizantino.
  ## Parámetros
  - nodo: Nodo PBFT bizantino
  - mensaje: Mensaje a procesar (puede ser :pre_preparado, :preparado, :comprometido)
  ## Retorna
  El nodo PBFT bizantino posiblemente modificado
  """
  def procesar_mensaje(%NodoPBFT{es_bizantino: true} = nodo, mensaje) do
    manejar_mensaje_bizantino(nodo, mensaje)
  end

  @doc """
  Maneja mensajes de pre-preparación para nodos honestos en el protocolo PBFT.
  ## Parámetros
  - `nodo`: Estructura del nodo actual
  - `{:pre_preparado, block}`: Mensaje de pre-preparación con el bloque a procesar
  ## Retorna
  Nodo actualizado con el estado de consenso modificado
  """
  defp manejar_mensaje_normal(nodo, {:pre_preparado, block}) do
    # Inicia el consenso para el bloque
    consenso_actualizado = ConsensusManager.iniciar_consenso(nodo.consensus_manager, block)
    nodo_actualizado = %{nodo | consensus_manager: consenso_actualizado}

    # Difunde mensajes de preparación a todos los nodos excepto a sí mismo
    Enum.reduce(1..nodo.consensus_manager.total_nodos, nodo_actualizado, fn emisor_id, acc ->
      if emisor_id != nodo.id do
        procesar_mensaje(acc, {:preparado, block, emisor_id})
      else
        acc
      end
    end)
  end

  @doc """
  Maneja mensajes de preparación para nodos honestos en el protocolo PBFT.
  ## Parámetros
  - `nodo`: Estructura del nodo actual
  - `{:preparado, block, emisor}`: Mensaje de preparación con bloque y ID de emisor
  ## Retorna
  Nodo actualizado con el estado de consenso modificado
  """
  defp manejar_mensaje_normal(nodo, {:preparado, block, emisor}) do
    # Maneja los votos de preparación
    consenso_actualizado = ConsensusManager.manejar_voto_preparacion(nodo.consensus_manager, block, emisor)
    nodo_actualizado = %{nodo | consensus_manager: consenso_actualizado}

    # Si se alcanza el quorum de preparación, avanza a la fase de compromiso
    if consenso_actualizado.estado == :preparado do
      Enum.reduce(1..nodo.consensus_manager.total_nodos, nodo_actualizado, fn emisor_compromiso, acc ->
        if emisor_compromiso != nodo.id do
          procesar_mensaje(acc, {:comprometido, block, emisor_compromiso})
        else
          acc
        end
      end)
    else
      nodo_actualizado
    end
  end

  @doc """
  Maneja mensajes de compromiso para nodos honestos en el protocolo PBFT.
  ## Parámetros
  - `nodo`: Estructura del nodo actual
  - `{:comprometido, block, emisor}`: Mensaje de compromiso con bloque y ID de emisor
  ## Retorna
  Nodo actualizado con blockchain y estado de consenso modificados
  """
  defp manejar_mensaje_normal(nodo, {:comprometido, block, emisor}) do
    # Maneja los votos de compromiso
    consenso_actualizado = ConsensusManager.manejar_voto_compromiso(nodo.consensus_manager, block, emisor)
    nodo_actualizado = %{nodo | consensus_manager: consenso_actualizado}

    # Si se alcanza el quorum de compromiso, inserta el bloque en la blockchain
    if consenso_actualizado.estado == :comprometido do
      if not Enum.any?(nodo.blockchain.blocks, fn b -> b.hash == block.hash end) do
        %{nodo_actualizado |
          blockchain: Blockchain.insert(nodo.blockchain, block.data),
          consensus_manager: %{consenso_actualizado | estado: :comprometido}
        }
      else
        %{nodo_actualizado | consensus_manager: %{consenso_actualizado | estado: :comprometido}}
      end
    else
      nodo_actualizado
    end
  end

  @doc """
  Maneja mensajes de pre-preparación para nodos bizantinos en el protocolo PBFT.
  ## Parámetros
  - `nodo`: Estructura del nodo bizantino
  - `{:pre_preparado, block}`: Mensaje de pre-preparación con bloque original
  ## Retorna
  Nodo bizantino con múltiples consensos iniciados para bloques maliciosos
  """
  defp manejar_mensaje_bizantino(nodo, {:pre_preparado, block}) do
    # Genera bloques maliciosos para un nodo bizantino
    bloque_malicioso = Enum.map(1..3, fn i ->
      Block.new("Bloque Malicioso - Nodo #{nodo.id}", block.prev_hash)
    end)

    Enum.reduce(bloque_malicioso, nodo, fn mal_block, acc ->
      consenso_actualizado = ConsensusManager.iniciar_consenso(acc.consensus_manager, mal_block)
      %{acc | consensus_manager: consenso_actualizado}
    end)
  end

  @doc """
  Maneja mensajes de preparación para nodos bizantinos.
  ## Retorna
  El mismo nodo sin modificaciones
  """
  defp manejar_mensaje_bizantino(nodo, {:preparado, _block, _emisor}), do: nodo

  @doc """
  Maneja mensajes de compromiso para nodos bizantinos.
  ## Retorna
  El mismo nodo sin modificaciones
  """
  defp manejar_mensaje_bizantino(nodo, {:comprometido, _block, _emisor}), do: nodo

  @doc """
  Simula un comportamiento malicioso con diferentes estrategias.
  ## Parámetros
  - nodo: Nodo PBFT
  - block: Bloque original
  - emisor: Identificador del emisor
  - tipo: Tipo de mensaje
  ## Retorna
  El nodo PBFT posiblemente modificado según la estrategia elegida
  """
  defp comportamiento_malicioso(nodo, block, emisor, tipo) do
    case :rand.uniform(3) do
      1 -> manejar_mensaje_normal(%{nodo | es_bizantino: false}, {tipo, block, emisor})
      2 ->
        bloque_malicioso = Block.new("Bloque Malicioso - Nodo #{nodo.id}", block.prev_hash)
        %{nodo | consensus_manager: ConsensusManager.manejar_voto_preparacion(nodo.consensus_manager, bloque_malicioso, emisor)}
      3 -> nodo
    end
  end
end
