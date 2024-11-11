defmodule MiniD3fl.Channel do
  use GenServer
  alias MiniD3fl.Utils
  alias MiniD3fl.ComputeNode

  defmodule State do
    defstruct channel_id: 0,
              queue: nil
  end

  # def start_link(arg_tuples) do
  #   GenServer.start_link(
  #     __MODULE__,
  #     arg_tuples,
  #     name: Utils.get_process_name_from_to(__MODULE__, from_id, to_id)
  #     )
  # end
#
  # def init(init_arg) do
  #   queue = :queue.new
  #   {
  #     :ok, %State{
  #       channel_id: channel_id,
  #       queue: queue
  #     }
  #   }
  # end
#
  # def recv_model_at_channel(from_node_id, to_node_id, channel_pid, sending_model) do
  #   GenServer.call(
  #     channel_pid,
  #     {:transfer_model, from_node_id, to_node_id, sending_model}
  #   )
  # end
end
