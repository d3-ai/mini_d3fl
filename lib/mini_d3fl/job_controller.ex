defmodule MiniD3fl.JobController do
  use GenServer
  require Logger

  defmodule State do
    defstruct job_controller_id: nil,
              event_queue: :queue.new,
              now_time: nil
  end

  defmodule MiniD3fl.JobController.Event do
    defstruct start_time: nil,
              compute_node_id: nil,
              message: nil
  end

  # TODO: Have a dictonary which stores key: CN_name or Channel_name, value: pid


  def start_link(%{node_id: node_id} = arg_map) do
    GenServer.start_link(
      __MODULE__,
      arg_map,
      name: Utils.get_process_name(__MODULE__, node_id)
    )
  end

  def init(%{job_controller_id: node_id, init_event_queue: init_event_queue} = _arg_map) do
    {:ok,
    %State{
      job_controller_id: node_id,
      event_queue: init_event_queue
    }}
  end

  def event_execute() do

  end
end
