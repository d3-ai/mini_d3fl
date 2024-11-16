defmodule MiniD3fl.JobExecutor do
  use GenServer
  require Logger
  alias MiniD3fl.JobController
  alias MiniD3fl.ComputeNode.TrainArgs
  alias MiniD3fl.ComputeNode
  alias MiniD3fl.Channel
  alias MiniD3fl.JobController.EventQueue.Event
  alias MiniD3fl.Utils

  defmodule State do
    defstruct job_executor_id: 0,
              job_controller_id: 0,
              now_time: nil,
              CNs_to_Channel_pid_dict: nil,
              pid_to_CN_dict: nil,
              pid_to_Channel_dict: nil
  end

  defmodule JobExcInitArgs do
    @moduledoc """
    - job_executor_id: int
    - job_controller_id: int
    - event_queue: JobController.EventQueue
    """
    defstruct [:job_executor_id, :job_controller_id, :init_event_queue]
  end

  def start_link(%JobExcInitArgs{job_executor_id: job_executor_id} = arg_map) do
    # TODO: Controller を supervise する？
    GenServer.start_link(
      __MODULE__,
      arg_map,
      name: Utils.get_process_name(__MODULE__, job_executor_id)
    )
  end

  def init(%JobExcInitArgs{job_executor_id: exec_node_id, job_controller_id: contr_node_id} = _arg_map) do
    {:ok,
    %State{
      job_executor_id: exec_node_id,
      job_controller_id: contr_node_id
    }}
  end

  def get_event(job_controller_id) do
    GenServer.call(
      Utils.get_process_name(JobController, job_controller_id),
      {:get_event}
      )
  end

  def add_event(job_controller_id, %Event{} = event) do
    GenServer.call(
      Utils.get_process_name(JobController, job_controller_id),
      {:add_event, event}
    )
  end

  # def add_event_recv_model_at_cn(job_controller_id, channel_pid, now_time, recv_time) do
  #   GenServer.call(
  #     MiniD3fl.JobController,
  #     {:add_event, },
  #     name: Utils.get_process_name(MiniD3fl.JobController, job_controller_id))
  # end

  # def add_event_train_complete(job_controller_id, node_id, now_time, end_time) do
  #   GenServer.call(
  #     Utils.get_process_name(__MODULE__, job_controller_id),
  #     {:train_complete, node_id, now_time, end_time}
  #   )
  # end

  def ask_required_time() do

  end

  def simulate_execute(job_executor_id) do
    GenServer.call(
      Utils.get_process_name(__MODULE__, job_executor_id),
      {:simulate_execute}
    )
  end

  # def handle_call({:train_complete, node_id, now_time, end_time}, _from, %State{event_queue: event_queue} = state) do
  #   if now_time < end_time do
  #     event_queue =EventQueue.insert_command(event_queue, %Event{time: end_time, event_name: :complete_train, args: node_id})
  #     {:reply, :ok, %State{state | event_queue: event_queue}}
  #   else
  #     raise "ERROR: TIME reversed"
  #   end
  # end

  # def handle_call({:recv_model_at_cn, channel_pid, now_time, recv_time}, _from, %State{event_queue: event_queue} = state) do
  #   if now_time < recv_time do
  #     event_queue =EventQueue.insert_command(event_queue, %Event{time: recv_time, event_name: :recv, args: channel_pid})
  #     {:reply, :ok, %State{state | event_queue: event_queue}}
  #   else
  #     raise "ERROR: TIME reversed"
  #   end
  # end

  def handle_call({:simulate_execute}, _from, %State{job_controller_id: controller_id} = state) do
    event_loop(controller_id)
    {:reply, :ok, state}
  end

  def event_loop(job_controller_id) do
    case GenServer.call(Utils.get_process_name(MiniD3fl.JobController, job_controller_id), {:get_event}) do
      {:ok, event} ->
        event_execute(job_controller_id, event)
        event_loop(job_controller_id)
      {:empty, _} -> IO.puts "Event Queue is Empty"
      _ -> raise "ERROR"
    end
  end

  def event_execute(job_controller_id, event) do
    case event do
      %Event{time: time, event_name: :train, args: %TrainArgs{node_id: node_id} = args} ->
        ComputeNode.train(args)
        # train終了のイベントを入れる
        train_duration = ComputeNode.get_train_duration(node_id)
        end_time = time + train_duration
        event = %Event{time: end_time, event_name: :complete_train, args: node_id}
        add_event(job_controller_id, event)

        IO.puts "time #{time}: train @node_#{node_id}"

      %Event{time: time, event_name: :send, args: %ComputeNode.SendArgs{from_node_id: from_id, to_node_id: to_id} = args} ->
        ComputeNode.send_to_channel(args)
        # DONE: Channel側からrecv_eventの追加をする。
        # TODO:? 後ほど非同期にするために、JobControllerからrecv_eventの追加をする?
        # TODO: SendArgs が 現時刻 を持っていないように直す

        IO.puts "time #{time}: send from node_#{from_id} to node_#{to_id}"

      %Event{time: time, event_name: :recv, args: channel_pid} ->
        Channel.send_model_from_channel(channel_pid)

        IO.puts "time #{time}: receive @channel"
        IO.inspect channel_pid

      %Event{time: time, event_name: :complete_train, args: node_id} ->
        ComputeNode.complete_train(node_id)

        IO.puts "time #{time}: complete train @node_#{node_id}"

      %Event{event_name: :available, args: node_id} ->
        ComputeNode.become_available(node_id)

      %Event{event_name: :unavailable, args: node_id} ->
        ComputeNode.become_unavailable(node_id)

      :empty ->
        IO.puts "=====SIMULATION END====="
        raise "END"
     end
  end
end