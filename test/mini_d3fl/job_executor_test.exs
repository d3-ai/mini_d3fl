defmodule MiniD3fl.JobExecutorTest do
  use ExUnit.Case
  use MiniD3fl.Aliases

  def setup_job_controller(_channel_pid) do
      # キューの初期化
      queue = EventQueue.init_queue()

      # コマンドを挿入
      queue = EventQueue.insert_command(queue,%Event{time: 5, event_name: :train, args: %TrainArgs{node_id: 10}})
      queue = EventQueue.insert_command(queue,%Event{time: 10, event_name: :send, args: %SendArgs{from_node_id: 10,
                                                                                          to_node_id: 20,
                                                                                          time: 10}})
      queue = EventQueue.insert_command(queue,%Event{time: 7, event_name: :train, args: %TrainArgs{node_id: 20}})

      job_controller_id = 0
      {:ok, _pid} = JobController.start_link(
        %{job_controller_id: job_controller_id,
        init_event_queue: queue})
      %{job_controller_id: job_controller_id, queue: queue}
  end

  def setup_job_controller_precise(_channel_pid) do
    # キューの初期化
    queue = EventQueue.init_queue()

    # コマンドを挿入
    queue = EventQueue.insert_command(queue,%Event{time: 5, event_name: :train, args: %TrainArgs{node_id: 10}})
    queue = EventQueue.insert_command(queue,%Event{time: 10, event_name: :send, args: %SendArgs{from_node_id: 10,
                                                                                        to_node_id: 20,
                                                                                        time: 10}})
    queue = EventQueue.insert_command(queue,%Event{time: 11, event_name: :send, args: %SendArgs{from_node_id: 10,
                                                                                        to_node_id: 20,
                                                                                        time: 11}})
    queue = EventQueue.insert_command(queue,%Event{time: 12, event_name: :send, args: %SendArgs{from_node_id: 10,
                                                                                        to_node_id: 20,
                                                                                        time: 12}})
    queue = EventQueue.insert_command(queue,%Event{time: 7, event_name: :train, args: %TrainArgs{node_id: 20}})

    job_controller_id = 0
    {:ok, _pid} = JobController.start_link(
      %{job_controller_id: job_controller_id,
      init_event_queue: queue})
    %{job_controller_id: job_controller_id, queue: queue}
  end

  def setup_compute_node(node_id, node_num) do
    args = %InitArgs{node_id: node_id,
                      data: nil,
                      availability: true,
                      model: %Model{size: 10, plain_model: %{}},
                      node_num: node_num
                    }

    {:ok, _pid}  = ComputeNode.start_link(args)
    %{node_id: node_id}
  end

  def setup_channel(bandwidth \\ 100) do
    # Channelの初期設定

    input_qos = %Channel.QoS{bandwidth: bandwidth,
                      packetloss: 0,
                      capacity: 100}

    init_args = %Channel.ChannelArgs{
                  from_cn_id: 10,
                  to_cn_id: 20,
                  QoS: input_qos}

    {:ok, _channel_pid} = Channel.start_link(init_args)
  end

  def setup_rough(bandwidth \\ 100) do
    setup_compute_node(10, 20)
    setup_compute_node(20, 20)
    {:ok, channel_pid} = setup_channel(bandwidth)
    setup_job_controller(channel_pid)
  end

  def setup_precise(bandwidth \\ 1) do
    setup_compute_node(10, 20)
    setup_compute_node(20, 20)
    {:ok, channel_pid} = setup_channel(bandwidth)
    setup_job_controller_precise(channel_pid)
  end

  def kill_dataloader() do
    case Process.whereis(DataLoader) do
      nil -> nil
      _ -> GenServer.stop(DataLoader, :normal, :infinity)
    end
  end

  @tag timeout: :infinity
  test "should exec JobExecutor" do
    kill_dataloader()
    %{job_controller_id: job_controller_id, queue: queue} = setup_rough()
    job_executor_id = 0
    JobExecutor.start_link(%JobExcInitArgs{job_executor_id: job_executor_id, job_controller_id: job_controller_id, init_event_queue: queue})

    history = JobExecutor.simulate_execute(0)
    #TODO: ADD test (timeline, inner state)

    desired_history = [
      %{time: 11, event_name: :complete_train},
      %{time: 10.1, event_name: :recv},
      %{time: 10, event_name: :send},
      %{time: 9, event_name: :complete_train},
      %{time: 7, event_name: :train},
      %{time: 5, event_name: :train}
    ]

    assert history == desired_history
    GenServer.stop(Utils.get_process_name(JobController, 0), :normal, :infinity)
    GenServer.stop(Utils.get_process_name(ComputeNode, 10), :normal, :infinity)
    GenServer.stop(Utils.get_process_name(ComputeNode, 20), :normal, :infinity)
    GenServer.stop(Utils.get_channel_name(10, 20), :normal, :infinity)
    GenServer.stop(DataLoader, :normal, :infinity)
  end

  @tag timeout: :infinity
  test "should exec JobExecutor with precise latency" do
    kill_dataloader()
    # GenServer.stop(DataLoader, :normal, :infinity)
    %{job_controller_id: job_controller_id, queue: queue} = setup_precise()
    job_executor_id = 0
    JobExecutor.start_link(%JobExcInitArgs{job_executor_id: job_executor_id, job_controller_id: job_controller_id, init_event_queue: queue})

    history = JobExecutor.simulate_execute(0)
    #TODO: ADD test (timeline, inner state)

    desired_history = [
      %{time: 40.0, event_name: :recv},
      %{time: 30.0, event_name: :recv},
      %{time: 20.0, event_name: :recv},
      %{time: 12, event_name: :send},
      %{time: 11, event_name: :send},
      %{event_name: :complete_train, time: 11},
      %{event_name: :send, time: 10},
      %{event_name: :complete_train, time: 9},
      %{event_name: :train, time: 7},
      %{event_name: :train, time: 5}
    ]

    assert history == desired_history
    GenServer.stop(Utils.get_process_name(JobController, 0), :normal, :infinity)
    GenServer.stop(Utils.get_process_name(ComputeNode, 10), :normal, :infinity)
    GenServer.stop(Utils.get_process_name(ComputeNode, 20), :normal, :infinity)
    GenServer.stop(Utils.get_channel_name(10, 20), :normal, :infinity)
    GenServer.stop(DataLoader, :normal, :infinity)
  end
end
