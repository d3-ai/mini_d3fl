defmodule MiniD3fl.ComputeNode do
  require Logger
  use GenServer
  alias MiniD3fl.Utils

  defmodule State do
    defstruct node_id: nil,
              now_model: nil,
              future_model: nil,
              data: nil
  end

  defmodule InitArgs do
    defstruct node_id: nil,
              model: nil,
              data: nil
  end

  defmodule TrainArgs do
    defstruct node_id: nil
  end

  defmodule SendArgs do
    defstruct from_node_id: nil,
              to_node_id: nil,
              channel_pid: nil
  end

  defmodule RenewModelArgs do
    defstruct node_id: nil
  end

  def start_link(%InitArgs{node_id: node_id} = args_tuple) do
    GenServer.start_link(
      __MODULE__,
      args_tuple,
      name: Utils.get_process_name(__MODULE__, node_id)
    )
  end

  def init(
    %InitArgs{
      node_id: node_id,
      model: model,
      data: data
    }) do

    {:ok,
    %State{
      node_id: node_id,
      now_model: model,
      future_model: nil,
      data: data
    }}
  end

  #def send_model(send_node_id, recv_node_id) do
  #  GenServer.call(
  #    Utils.get_process_name(__MODULE__, send_node_id),
  #    {:send_model, recv_node_id}
  #    )
  #end

end
