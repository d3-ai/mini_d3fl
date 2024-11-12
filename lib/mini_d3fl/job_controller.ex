defmodule MiniD3fl.JobController do
  use GenServer
  require Logger
  alias MiniD3fl.JobController.EventQueue

  defmodule State do
    defstruct job_controller_id: nil,
              event_queue: EventQueue.init_queue,
              now_time: nil,
              CNs_to_Channel_pid_dict: nil,
              pid_to_CN_dict: nil,
              pid_to_Channel_dict: nil
  end

  def start_link(%{job_controller_id: job_controller_id} = arg_map) do
    GenServer.start_link(
      __MODULE__,
      arg_map,
      name: Utils.get_process_name(__MODULE__, job_controller_id)
    )
  end

  def init(%{job_controller_id: node_id, init_event_queue: init_event_queue} = _arg_map) do
    {:ok,
    %State{
      job_controller_id: node_id,
      event_queue: init_event_queue
    }}
  end

  def add_event_resv_model_at_cn() do

  end

  def ask_required_time() do

  end
  def event_execute() do

  end
end
