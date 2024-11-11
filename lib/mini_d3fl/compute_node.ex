defmodule MiniD3fl.ComputeNode do
  require Logger
  use GenServer
  alias MiniD3fl.Utils
  alias MiniD3fl.Channel

  defmodule Model do
    defstruct size: nil,
              plain_model: nil
  end

  defmodule State do
    defstruct node_id: nil,
              now_model: %Model{},
              future_model: %Model{},
              data: nil,
              cn_id_channel_pid_dict: %{}
  end

  defmodule InitArgs do
    defstruct node_id: nil,
              model: %Model{},
              data: nil,
              cn_id_channel_pid_dict: %{}
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
      data: data,
      cn_id_channel_pid_dict: cn_id_channel_pid_dict
    }) do

    {:ok,
    %State{
      node_id: node_id,
      now_model: model,
      future_model: nil,
      data: data,
      cn_id_channel_pid_dict: cn_id_channel_pid_dict
    }}
  end

  def train(%TrainArgs{node_id: node_id} = args) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:train, args}
    )
  end

  def send_to_channel(%SendArgs{from_node_id: from_node_id} = send_args) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, from_node_id),
      {:send_to_channel, send_args}
      )
  end

  def handle_call({:train,
                    args},
                  _from,
                  %State{node_id: node_id} = state) do
    IO.puts "Node id: #{node_id} in TRAIN"
    # TODO: Trainに書き換える
    new_model = nil
    train_results = :train_results
    # TODO: Trainした時の結果に書き換える
    {:reply, train_results, %State{state | future_model: new_model}}
  end

  def handle_call({:send_to_channel,
                    %SendArgs{
                      channel_pid: channel_pid
                    }} = _send_args,
                    _from,
                    %State{now_model: now_model} = state) do

    Channel.recv_model_at_channel(channel_pid, now_model)
    IO.puts "sent to channel pid #{channel_pid}"
    {:reply, nil, state}
  end

end
