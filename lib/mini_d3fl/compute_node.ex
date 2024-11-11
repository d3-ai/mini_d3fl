defmodule MiniD3fl.ComputeNode do
  require Logger
  use GenServer

  defmodule State do
    defstruct node_id: nil,
              model: %{}
  end

  def start_link(%{node_id: node_id} = args_tuple) do
    GenServer.start_link(
      __MODULE__,
      args_tuple,
      name: Utils.get_process_name(__MODULE__, node_id)
    )
  end

  def init(%{
    node_id: node_id,
    model: model,
    data: data
    }) do

    {:ok,
    %State{
      node_id: node_id,
      model: model
    }}
  end

  #def send_model(send_node_id, recv_node_id) do
  #  GenServer.call(
  #    Utils.get_process_name(__MODULE__, send_node_id),
  #    {:send_model, recv_node_id}
  #    )
  #end

end
