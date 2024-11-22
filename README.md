# Blockchain en Elixir
Flores Linares Oscar Daniel y Márquez Corona Danna Lizette

Este proyecto consiste en desarrollar una **blockchain** funcional para un sistema de criptomonedas, implementada en **Elixir**. 

El sistema puede manejar múltiples procesos que representan a los usuarios. Entre sus funcionalidades principales se incluyen: 
- Envío de mensajes entre usuarios.
- Alcance de un consenso distribuido.
- Detección y eliminación de procesos maliciosos que intenten alterar la blockchain.

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

4. **Main**
   - Módulo manejador que simula una red de nodos.
   - Permite configurar:
     - `n`: Número de nodos.
     - `f`: Número de procesos bizantinos.

## Ejemplo de Uso

```elixir
# Inicializa una blockchain
iex> blockchain = Blockchain.new()

# Inserta una transacción
iex> blockchain = Blockchain.insert(blockchain, "Transacción 1")

# Valida la blockchain
iex> Blockchain.valid?(blockchain)
true

# Simula una red con 10 nodos y 2 procesos bizantinos
iex> Main.run(10, 2)
Creando red con 10 nodos y 2 procesos bizantinos...
