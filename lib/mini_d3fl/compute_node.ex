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
              receive_model: nil, #TODO: あとで dict 化 or queue 化
              train_duration: 10, #TODO: あとで、CNごとに変化させる
              data: nil,
              cn_id_channel_pid_dict: %{},
              in_train: false,
              availability: nil
  end

  defmodule InitArgs do
    defstruct node_id: nil,
              model: %Model{},
              data: nil,
              cn_id_channel_pid_dict: %{},
              availability: nil
  end

  defmodule TrainArgs do
    defstruct node_id: nil
  end

  defmodule SendArgs do
    defstruct from_node_id: nil,
              to_node_id: nil,
              channel_pid: nil
  end

  defmodule RecvArgs do
    defstruct from_node_id: nil,
              to_node_id: nil,
              model: nil
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
      cn_id_channel_pid_dict: cn_id_channel_pid_dict,
      availability: avail
    } = _init_args) do

    {:ok,
    %State{
      node_id: node_id,
      now_model: model,
      future_model: nil,
      data: data,
      cn_id_channel_pid_dict: cn_id_channel_pid_dict,
      availability: avail
    }}
  end

  def train(%TrainArgs{node_id: node_id} = args) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:train, args}
    )
  end

  def complete_train(node_id) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:complete_train}
    )
  end

  def send_to_channel(%SendArgs{from_node_id: from_node_id} = send_args) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, from_node_id),
      {:send_to_channel, send_args}
      )
  end

  def recv_model(%RecvArgs{to_node_id: to_node_id} = recv_args) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, to_node_id),
      {:recv_model, recv_args}
      )
  end

  def become_available(node_id) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:become_available}
      )
  end

  def become_unavailable(node_id) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:become_unavailable}
      )
  end

  def is_available(node_id) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:is_available}
      )
  end

  def get_train_duration(node_id) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:get_train_duration}
      )
  end

  def get_state(node_id) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:get_state}
      )
  end

  def handle_call({:train,
                    _args},
                  _from,
                  %State{node_id: node_id, in_train: in_train} = state) do
    IO.puts "Node id: #{node_id} in TRAIN"
    # TODO: if in_train == false: Train に書き換える.
    new_model = nil
    train_results = :train_results
    # TODO: Trainした時の結果に書き換える
    {:reply, train_results, %State{state | future_model: new_model, in_train: true}}
  end

  def handle_call({:complete_train}, _from,
                  %State{future_model: future_model, in_train: in_train} =state) do
    if in_train == false do
      raise "ERROR: complete train when not training!!!"
    end
    {:reply, :ok, %State{state | now_model: future_model, future_model: nil, in_train: false}}
  end

  def handle_call({:send_to_channel,
                    %SendArgs{
                      channel_pid: channel_pid
                    }} = _send_args,
                    _from,
                    %State{now_model: now_model} = state) do

    Channel.recv_model_at_channel(channel_pid, now_model)
    IO.puts "sent to channel pid #{channel_pid}"
    {:reply, :ok, state}
  end

  def handle_call({:recv_model, %RecvArgs{model: model}},
                  _from,
                  state) do
    {:reply, :ok, %State{state | receive_model: model}}
    #TODO: もらってきたモデルはどこに置くか？ receive_modelを作った。後ほどdict化する？
  end

  def handle_call({:become_available}, _from, state) do
    {:reply, :ok, %State{state | availability: true}}
  end

  def handle_call({:become_unavailable}, _from, state) do
    {:reply, :ok, %State{state | availability: false}}
  end

  def handle_call({:is_available}, _from, %State{availability: avail} = state) do
    {:reply, avail == true, state}
  end

  def handle_call({:get_train_duration}, _from, %State{train_duration: train_duration} = state) do
    {:reply, train_duration, state}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end
end
