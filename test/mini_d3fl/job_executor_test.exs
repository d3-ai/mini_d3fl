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
      {:ok, pid} = JobController.start_link(
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

  def setup_channel() do
    # Channelの初期設定
    # TODO: 関数化して切り出す（channel_testの中の共通部分も）

    input_qos = %Channel.QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}

    init_args = %Channel.ChannelArgs{channel_id: 1,
                  from_cn_id: 10,
                  to_cn_id: 20,
                  QoS: input_qos}

    {:ok, channel_pid} = Channel.start_link(init_args)
  end

  setup do
    setup_compute_node(10)
    setup_compute_node(20)
    {:ok, channel_pid} = setup_channel()
    setup_job_controller(channel_pid)
  end

  test "should exec JobExecutor", %{job_controller_id: job_controller_id, queue: queue} do
    job_executor_id = 0
    JobExecutor.start_link(%JobExcInitArgs{job_executor_id: job_executor_id, job_controller_id: job_controller_id, init_event_queue: queue})

    JobExecutor.simulate_execute(0)

  end
end
