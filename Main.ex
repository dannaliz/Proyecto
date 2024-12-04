defmodule Main do
  @doc """
  Ejecuta una simulación del algoritmo PBFT.
  ## Parámetros
  - `n`: Número total de nodos en la red
  - `f`: Número de nodos bizantinos tolerados
  ## Restricciones
  - Lanza un error si `n` no es mayor que `3 * f`
  ## Proceso de simulación
  1. Crea nodos initial con identificadores únicos
   - Marca los primeros `f` nodos como nodos bizantinos
  2. Simula el proceso de consenso con los nodos creados
   - Conecta todos los nodos entre sí
   - Procesa un bloque inicial a través de las fases PBFT:
     * Pre-Prepare
     * Prepare
     * Commit
  3. Imprime el estado final de consenso de todos los nodos
  """
  def run(n, f) do
    if n <= 3 * f, do: raise "n debe ser mayor que 3f"

    nodos = Enum.map(1..n, fn id -> NodoPBFT.inicial(id, n, f, id <= f) end)
    nodos = simular_consenso(nodos, f)

    print_consenso_final(nodos)
  end

  @doc """
  Simula el proceso de consenso PBFT para un conjunto de nodos.
  ## Fases de consenso
  1. Pre-Prepare: Distribución inicial del bloque
  2. Prepare: Verificación y preparación del bloque
   - Solo nodos honestos muestran mensajes de preparación
  3. Commit: Compromiso final con el bloque
  ## Retorna
  Lista de nodos después de completar el proceso de consenso
  """
  defp simular_consenso(nodos, f) do
    # Conectar todos los nodos entre sí (simulación)
    nodos = Enum.map(nodos, fn nodo ->
      peer = Enum.filter(nodos, fn peer -> peer.id != nodo.id end)
      peer_pids = Enum.map(peer, fn peer -> {peer.id, self()} end)

      network_actualizado = Enum.reduce(peer_pids, nodo.network_manager, fn {peer_id, pid}, network ->
        NetworkManager.conectar_peer(network, peer_id, pid)
      end)

      %{nodo | network_manager: network_actualizado}
    end)

    lista_bloques = ["Bloque 1"]

    Enum.reduce(lista_bloques, nodos, fn datos_bloque, nodos_actuales ->
      # Usar el hash del último bloque de la blockchain como prev_hash
      prev_hash = nodos_actuales
        |> Enum.at(0)
        |> Map.get(:blockchain)
        |> Map.get(:blocks)
        |> List.last()
        |> Map.get(:hash)

      bloque_inicial = Block.new(datos_bloque, prev_hash)

      # Separar nodos bizantinos y honestos
      nodos_bizantinos = Enum.filter(nodos_actuales, &(&1.es_bizantino))
      nodos_honestos = Enum.reject(nodos_actuales, &(&1.es_bizantino))

      # Imprimir información sobre nodos bizantinos
      IO.puts(IO.ANSI.yellow() <> "\n--- Información de Nodos Bizantinos ---" <> IO.ANSI.reset())
      Enum.each(nodos_actuales, fn nodo ->
        if nodo.es_bizantino do
          IO.puts(IO.ANSI.red() <> "Nodo #{nodo.id} es un nodo bizantino." <> IO.ANSI.reset())
        else
          IO.puts("Nodo #{nodo.id} es un nodo honesto.")
        end
      end)

      # Fase de Pre-Prepare
      IO.puts(IO.ANSI.green() <> "\n-----------------------------------" <> IO.ANSI.reset())
      IO.puts(IO.ANSI.green() <> "-- Fase de Pre-Prepare: #{datos_bloque} --" <> IO.ANSI.reset())
      IO.puts(IO.ANSI.green() <> "-----------------------------------" <> IO.ANSI.reset())

      # Imprimir recepción del bloque por cada nodo (independientemente de su tipo)
      Enum.each(nodos_actuales, fn nodo ->
        IO.puts("Nodo #{nodo.id} recibe el bloque: #{datos_bloque}")
      end)

      # Procesar nodos bizantinos con bloques maliciosos
      bizantino_procesado = Enum.map(nodos_bizantinos, fn nodo ->
        # Crear múltiples bloques maliciosos potencialmente
        bloque_malicioso = Enum.map(1..3, fn i ->
          Block.new("Bloque Malicioso - Nodo #{nodo.id}", prev_hash)
        end)

        # Procesar cada bloque malicioso
        Enum.reduce(bloque_malicioso, nodo, fn mal_block, acc ->
          nodo_procesado = NodoPBFT.procesar_mensaje(%{acc | es_bizantino: true}, {:pre_preparado, mal_block})
          # Asegurar que el nodo siga siendo bizantino
          %{nodo_procesado | es_bizantino: true}
        end)
      end)

      # Procesar nodos honestos normalmente
      honesto_procesado = Enum.map(nodos_honestos, fn nodo ->
        nodo_procesado = NodoPBFT.procesar_mensaje(nodo, {:pre_preparado, bloque_inicial})
        nodo_procesado
      end)

      # Combinar nodos procesados, con bizantinos primero
      pre_preparacion_nodos = bizantino_procesado ++ honesto_procesado

      # Fase de Prepare
      IO.puts(IO.ANSI.blue() <> "\n--------------------------" <> IO.ANSI.reset())
      IO.puts(IO.ANSI.blue() <> "-- Fase de Preparación: --" <> IO.ANSI.reset())
      IO.puts(IO.ANSI.blue() <> "--------------------------" <> IO.ANSI.reset())

      # Filtrar solo nodos honestos para impresión de preparación
      nodos_honestos_ids = Enum.reject(nodos_actuales, &(&1.es_bizantino)) |> Enum.map(& &1.id)

      nodos_preparacion = Enum.map(pre_preparacion_nodos, fn nodo ->
        # Solo imprimir para nodos honestos
        if nodo.id in nodos_honestos_ids do
          IO.puts("Nodo #{nodo.id} procesando mensajes de preparación")
        end

        estado_nodo_preparado = Enum.reduce(1..nodo.consensus_manager.total_nodos, nodo, fn emisor_id, acc ->
          if emisor_id != nodo.id do
            nodo_procesado = NodoPBFT.procesar_mensaje(acc, {:preparado, bloque_inicial, emisor_id})
            # Restaurar el estado bizantino original si es un nodo bizantino
            if acc.es_bizantino do
              %{nodo_procesado | es_bizantino: true}
            else
              nodo_procesado
            end
          else
            acc
          end
        end)
        estado_nodo_preparado
      end)

      # Fase de Commit
      IO.puts(IO.ANSI.magenta() <> "\n-------------------------" <> IO.ANSI.reset())
      IO.puts(IO.ANSI.magenta() <> "-- Fase de Compromiso: --" <> IO.ANSI.reset())
      IO.puts(IO.ANSI.magenta() <> "-------------------------" <> IO.ANSI.reset())

      nodos_compromiso = Enum.map(nodos_preparacion, fn nodo ->
        # Solo imprimir para nodos honestos
        if nodo.id in nodos_honestos_ids do
          IO.puts("Nodo #{nodo.id} procesando mensajes de commit")
        end

        estado_nodo_comprometido = Enum.reduce(1..nodo.consensus_manager.total_nodos, nodo, fn emisor_id, acc ->
          if emisor_id != nodo.id do
            nodo_procesado = NodoPBFT.procesar_mensaje(acc, {:comprometido, bloque_inicial, emisor_id})
            # Restaurar el estado bizantino original
            if acc.es_bizantino do
              %{nodo_procesado | es_bizantino: true}
            else
              nodo_procesado
            end
          else
            acc
          end
        end)
        estado_nodo_comprometido
      end)

      # Devolver los nodos procesados
      nodos_compromiso
    end)
  end

  @doc """
  Imprime el estado final de consenso para cada nodo.
  ## Características
  - Muestra información detallada de cada nodo
  - Utiliza color para resaltar información clave:
   - Verde para consensus_manager
   - Azul para network_manager
   - Rojo para es_bizantino
  ## Formato de salida
  - Imprime estado completo de cada nodo
  - Resalta nodos bizantinos y honestos
  """
  defp print_consenso_final(nodos) do
    IO.puts(IO.ANSI.cyan() <> "\n---------------------------------" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.cyan() <> "-- Comprobando consenso final: --" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.cyan() <> "---------------------------------" <> IO.ANSI.reset())

    nodos_unicos = Enum.uniq_by(nodos, fn nodo -> nodo.id end)

    Enum.each(nodos_unicos, fn nodo ->
      IO.puts(IO.ANSI.magenta() <> "\n-------------" <> IO.ANSI.reset())
      IO.puts(IO.ANSI.magenta() <> "-- Nodo #{nodo.id}: --" <> IO.ANSI.reset())
      IO.puts(IO.ANSI.magenta() <> "-------------" <> IO.ANSI.reset())

      # Personalizar la impresión de las palabras clave
      color_estado =
        inspect(nodo, pretty: true)
        |> String.replace("consensus_manager", IO.ANSI.green() <> "consensus_manager" <> IO.ANSI.reset())
        |> String.replace("network_manager", IO.ANSI.blue() <> "network_manager" <> IO.ANSI.reset())
        |> String.replace("es_bizantino", IO.ANSI.red() <> "es_bizantino" <> IO.ANSI.reset())

      IO.puts(color_estado)
    end)
  end
end
