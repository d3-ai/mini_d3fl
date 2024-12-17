defmodule MiniD3fl.DataLoader do
  use GenServer
  require Logger
  alias MiniD3fl.ComputeNode.AiCore
  alias MiniD3fl.JobController
  alias MiniD3fl.ComputeNode.TrainArgs
  alias MiniD3fl.ComputeNode
  alias MiniD3fl.Channel
  alias MiniD3fl.JobController.EventQueue.Event
  alias MiniD3fl.Utils

  defmodule MlData do
    defstruct locals_train: nil,
              locals_valid: nil,
              global_test: nil
  end

  defmodule State do
    defstruct ml_data: %MlData{}
  end

  defmodule DataLoaderInitArgs do
    defstruct data_name: nil,
              client_num: nil,
              sample_rate: nil
  end

  def start_link(%DataLoaderInitArgs{} = arg_map) do
    GenServer.start_link(
      __MODULE__,
      arg_map,
      name: __MODULE__
    )
  end

  def init(%DataLoaderInitArgs{
      data_name: name,
      client_num: client_num,
      sample_rate: sample_rate} = _arg_map) when is_atom(name) do


      ml_data = AiCore.data_download(name, client_num, sample_rate)
      IO.puts "Init DataLoader"
    {:ok,
    %State{
      ml_data: ml_data
    }}
  end

  def get_data(client_id) when is_integer(client_id) do
    GenServer.call(
      __MODULE__,
      {:get_data, client_id},
      :infinity
    )
  end

  def handle_call({:get_data, client_id},
                  _from,
                  %State{ml_data: %MlData{
                    locals_train: locals_train,
                    locals_valid: locals_valid,
                    global_test: global_test}} = state) do

    #TODO: DataLoader(training_data, batch_size=64, shuffle=True)みたいに？
    {:reply, {Enum.at(locals_train, client_id), Enum.at(locals_valid, client_id), global_test}, state}
  end

end
