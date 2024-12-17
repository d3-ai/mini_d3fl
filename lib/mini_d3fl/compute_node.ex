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
              node_num: nil,
              now_model: %Model{},
              future_model: %Model{},
              receive_model: nil, #TODO: あとで dict 化 or queue 化
              train_duration: 4, #TODO: あとで、CNごとに変化させる
              data: nil,
              in_train: false,
              availability: nil,
              future_matrix: nil,
              data_path: nil
  end

  defmodule InitArgs do
    @moduledoc """
    - node_id: nil,
    - node_num: nil,
    - model: %Model{},
    - data: nil,
    - availability: nil,
    - data_folder: nil
    """
    defstruct node_id: nil,
              node_num: nil,
              model: %Model{},
              data: nil,
              availability: nil,
              data_folder: nil
  end

  defmodule TrainArgs do
    @moduledoc """
    - node_id: int
    """
    defstruct node_id: nil
  end

  defmodule SendArgs do
    @moduledoc """
    - from_node_id: int,
    - to_node_id: int,
    - time: int
    """
    defstruct from_node_id: nil,
              to_node_id: nil,
              time: nil
  end

  defmodule RecvArgs do
    @moduledoc """
    - from_node_id: int,
    - to_node_id: int,
    - model: MiniD3fl.ComputeNode.Model
    """
    defstruct from_node_id: nil,
              to_node_id: nil,
              model: nil
  end

  defmodule RenewModelArgs do
  @moduledoc """
  - node_id: int
  """
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
      node_num: node_num,
      model: model,
      data: data,
      availability: avail,
      data_folder: folder
    } = _init_args) do
    IO.puts "New model #{model.size}"

    path = case folder do
      nil -> nil
      _ -> Path.join(folder, "CaluculatorNode_#{node_id}.csv")
    end

    {:ok,
    %State{
      node_id: node_id,
      node_num: node_num,
      now_model: model,
      future_model: nil,
      data: data,
      availability: avail,
      data_path: path
    }}
  end

  def train(%TrainArgs{node_id: node_id} = args) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:train, args},
      :infinity
    )
  end

  def complete_train(node_id, time) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, node_id),
      {:complete_train, time}
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
                  %State{
                    node_id: node_id,
                    node_num: node_num,
                    in_train: _in_train,
                    now_model: now_model_state,
                    data_path: _file_path
                    } = state) do
    IO.puts "Node id: #{node_id} in TRAIN"
    #TODO: if in_train == false の条件を入れる？
    sample_rate = 0.3 #TODO: 再考する
    {:end_train, new_model_state_data, metrix} = MiniD3fl.ComputeNode.AiCore.run(now_model_state, node_id, node_num, sample_rate)
    new_model = %Model{size: now_model_state.size, plain_model: new_model_state_data}
    train_results = metrix

    # TODO: Trainした時の結果に書き換える
    {:reply, train_results, %State{state | future_model: new_model, in_train: true, future_matrix: metrix}}
  end

  def handle_call({:complete_train, time}, _from,
                  %State{future_model: future_model, in_train: in_train, data_path: file_path, future_matrix: metrix} =state) do
    if in_train == false do
      raise "ERROR: complete train when not training!!!"
    end

    if file_path do
      {:ok, fp} = File.open(file_path, [:append, :utf8])
      IO.write(fp, "#{time}, #{metrix}\n")
      File.close fp
    end

    {:reply, :ok, %State{state | now_model: future_model, future_model: nil, in_train: false}}
  end

  def handle_call({:send_to_channel,
                    %SendArgs{
                      from_node_id: from_node_id,
                      to_node_id: to_node_id,
                      time: time
                    }} = _send_args,
                    _from,
                    %State{now_model: now_model} = state) do

    #TODO: Channel.recv_model_at_channel/3
    Channel.recv_model_at_channel(from_node_id, to_node_id, now_model, time)
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
