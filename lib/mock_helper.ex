defmodule MockHelper do
  use MiniD3fl.Aliases

  def cn_setup(node_id) do
    args = %InitArgs{node_id: node_id,
                      model: %Model{size: 50, plain_model: "sample_plain_model#{node_id}"},
                      data: nil,
                      availability: true
                    }

    {:ok, _pid}  = ComputeNode.start_link(args)
    %{node_id: node_id}
  end

  def channel_setup(from_node_id, to_node_id, channel_id) do
    input_qos = %QoS{bandwidth: 100,
                      packetloss: 0.5,
                      capacity: 100}

    init_args = %ChannelArgs{channel_id: channel_id,
                  from_cn_id: from_node_id,
                  to_cn_id: to_node_id,
                  QoS: input_qos}

    {:ok, pid} = Channel.start_link(init_args)

    pid
  end

  def mock() do
    # ComputeNode の初期化
    cn_setup(10)
    cn_setup(20)

    # Channel の初期化
    channel_pid_10_20 = channel_setup(10, 20, 1)
    channel_pid_20_10 = channel_setup(20, 10, 2)

    # EventQueue の初期化
    event_queue = EventQueue.init_queue()
    event_queue = EventQueue.insert_command(event_queue, %Event{time: 10, event_name: :train, args: %TrainArgs{node_id: 10}})
    event_queue = EventQueue.insert_command(event_queue, %Event{time: 20, event_name: :train, args: %TrainArgs{node_id: 20}})
    event_queue = EventQueue.insert_command(event_queue, %Event{time: 30, event_name: :send, args: %SendArgs{from_node_id: 10, to_node_id: 20, channel_pid: channel_pid_10_20}})
    event_queue = EventQueue.insert_command(event_queue, %Event{time: 40, event_name: :send, args: %SendArgs{from_node_id: 20, to_node_id: 10, channel_pid: channel_pid_20_10}})

    # JobController の初期化
    job_controller_id = 0
    JobController.start_link(
      %{job_controller_id: job_controller_id,
      init_event_queue: event_queue})

    JobController.event_execute(job_controller_id)
  end
end
