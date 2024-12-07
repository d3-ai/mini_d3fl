defmodule MiniD3fl.JobExecutorTest do
  use ExUnit.Case
  use MiniD3fl.Aliases

  def setup_job_controller(channel_pid) do
      # キューの初期化
      queue = EventQueue.init_queue()

      # コマンドを挿入
      queue = EventQueue.insert_command(queue,%Event{time: 5, event_name: :train, args: %TrainArgs{node_id: 10}})
      queue = EventQueue.insert_command(queue,%Event{time: 10, event_name: :send, args: %SendArgs{from_node_id: 10,
                                                                                          to_node_id: 20,
                                                                                          channel_pid: channel_pid,
                                                                                          time: 10}})
      queue = EventQueue.insert_command(queue,%Event{time: 7, event_name: :train, args: %TrainArgs{node_id: 20}})

      job_controller_id = 0
      {:ok, _pid} = JobController.start_link(
        %{job_controller_id: job_controller_id,
        init_event_queue: queue})
      %{job_controller_id: job_controller_id, queue: queue}
  end

  def setup_job_controller_precise(channel_pid) do
    # キューの初期化
    queue = EventQueue.init_queue()

    # コマンドを挿入
    queue = EventQueue.insert_command(queue,%Event{time: 5, event_name: :train, args: %TrainArgs{node_id: 10}})
    queue = EventQueue.insert_command(queue,%Event{time: 10, event_name: :send, args: %SendArgs{from_node_id: 10,
                                                                                        to_node_id: 20,
                                                                                        channel_pid: channel_pid,
                                                                                        time: 10}})
    queue = EventQueue.insert_command(queue,%Event{time: 11, event_name: :send, args: %SendArgs{from_node_id: 10,
                                                                                        to_node_id: 20,
                                                                                        channel_pid: channel_pid,
                                                                                        time: 11}})
    queue = EventQueue.insert_command(queue,%Event{time: 12, event_name: :send, args: %SendArgs{from_node_id: 10,
                                                                                        to_node_id: 20,
                                                                                        channel_pid: channel_pid,
                                                                                        time: 12}})
    queue = EventQueue.insert_command(queue,%Event{time: 7, event_name: :train, args: %TrainArgs{node_id: 20}})

    job_controller_id = 0
    {:ok, _pid} = JobController.start_link(
      %{job_controller_id: job_controller_id,
      init_event_queue: queue})
    %{job_controller_id: job_controller_id, queue: queue}
end

  def setup_compute_node(node_id) do
    args = %InitArgs{node_id: node_id,
                      data: nil,
                      availability: true
                    }

    {:ok, _pid}  = ComputeNode.start_link(args)
    %{node_id: node_id}
  end

  def setup_channel(bandwidth \\ 100) do
    # Channelの初期設定

    input_qos = %Channel.QoS{bandwidth: bandwidth,
                      packetloss: 0,
                      capacity: 100}

    init_args = %Channel.ChannelArgs{channel_id: 1,
                  from_cn_id: 10,
                  to_cn_id: 20,
                  QoS: input_qos}

    {:ok, _channel_pid} = Channel.start_link(init_args)
  end

  def setup_rough(bandwidth \\ 100) do
    setup_compute_node(10)
    setup_compute_node(20)
    {:ok, channel_pid} = setup_channel(bandwidth)
    setup_job_controller(channel_pid)
  end

  def setup_precise(bandwidth \\ 1) do
    setup_compute_node(10)
    setup_compute_node(20)
    {:ok, channel_pid} = setup_channel(bandwidth)
    setup_job_controller_precise(channel_pid)
  end

  test "should exec JobExecutor" do
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
  end

  test "should exec JobExecutor with precise latency" do
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
  end
end
