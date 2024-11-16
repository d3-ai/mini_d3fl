defmodule MiniD3fl.JobController do
  use GenServer
  require Logger
  alias MiniD3fl.JobController.EventQueue
  alias MiniD3fl.JobController.EventQueue.Event
  alias MiniD3fl.Utils

  defmodule State do
    defstruct job_executor_id: 0,
              job_controller_id: 0,
              event_queue: EventQueue.init_queue
  end

  defmodule JobContrlInitArgs do
    @moduledoc """
    - job_executor_id: int
    - job_controller_id: int
    - event_queue: JobController.EventQueue
    """
    defstruct [:job_executor_id, :job_controller_id, :init_event_queue]
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

  def get_event(job_controller_id) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, job_controller_id),
      {:get_event}
    )
  end

  def add_event(job_controller_id, %Event{} = event) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, job_controller_id),
      {:add_event, event}
    )
  end

  def handle_call({:get_event}, _from, %State{event_queue: queue} = state) do
    {value, event, queue} = EventQueue.pop_command(queue)
    {:reply, {value, event}, %State{state | event_queue: queue}}
  end

  def handle_call({:add_event, %Event{} = event}, _from, %State{event_queue: queue} = state) do
    queue = EventQueue.insert_command(queue, event)
    {:reply, :ok, %State{state | event_queue: queue}}
  end
end
