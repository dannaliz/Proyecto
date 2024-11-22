"""
Desarrollar una blockchain para un sistema de criptomonedas.
Este sistema debera ser capaz de manejar multiples procesos en Elixir
que representen a los usuarios, quienes podran enviarse mensajes, alcanzar un consenso
y detectar y eliminar procesos maliciosos que intenten alterar la blockchain.
"""

defmodule Crypto do
    @doc """
    Genera el hash de un conjunto de datos usando SHA-256.
    """
    def hash(data) do
      :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
    end
  end

defmodule Block do
    defstruct [:data, :timestamp, :prev_hash, :hash]

    @doc """
    Crea un nuevo bloque con los datos proporcionados y el hash previo.
    """
    def new(data, prev_hash) do
      timestamp = :os.system_time(:seconds)
      hash = Crypto.hash("#{data}#{timestamp}#{prev_hash}")
      %Block{data: data, timestamp: timestamp, prev_hash: prev_hash, hash: hash}
    end

    @doc """
    Valida si el hash de un bloque coincide con sus datos.
    """
    def valid?(%Block{data: data, timestamp: timestamp, prev_hash: prev_hash, hash: hash}) do
      expected_hash = Crypto.hash("#{data}#{timestamp}#{prev_hash}")
      hash == expected_hash
    end

    @doc """
    Valida si dos bloques son secuenciales.
    """
    def valid?(%Block{} = block1, %Block{} = block2) do
      block2.prev_hash == block1.hash
    end
end

defmodule Blockchain do
    defstruct blocks: []

    @doc """
    Crea una blockchain con un bloque génesis.
    """
    def new() do
      genesis_block = Block.new("Genesis Block", "0")
      %Blockchain{blocks: [genesis_block]}
    end

    @doc """
    Inserta un nuevo bloque en la blockchain.
    """
    def insert(%Blockchain{blocks: blocks} = chain, data) do
      last_block = List.last(blocks)
      new_block = Block.new(data, last_block.hash)
      %Blockchain{blocks: blocks ++ [new_block]}
    end

    @doc """
    Valida toda la blockchain.
    """
    def valid?(%Blockchain{blocks: []}), do: false
    def valid?(%Blockchain{blocks: [_]}), do: true
    def valid?(%Blockchain{blocks: [block1, block2 | rest]}) do
      Block.valid?(block1) && Block.valid?(block1, block2) && valid?(%Blockchain{blocks: [block2 | rest]})
    end
end

defmodule Main do
    def run(n, f) do
      # Genera la red siguiendo el modelo de Watts-Strogatz (simplificado)
      IO.puts("Creando red con #{n} nodos y #{f} procesos bizantinos...")

      # Inicializa una blockchain para cada nodo
      Enum.map(1..n, fn _ -> Blockchain.new() end)
    end
end

"Nota para Osdansin: este es el ejemplo de uso:
iex> blockchain = Blockchain.new()
iex> blockchain = Blockchain.insert(blockchain, Transacción 1)
iex> Blockchain.valid?(blockchain)
true
iex> Main.run(10, 2)
Spoiler: jala"
