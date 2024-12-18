defmodule NumMock do
  use MiniD3fl.Aliases

  def prepare_data_directory!(node_counts, name) do
    data_directory_path =
      Application.get_env(:mini_d3fl, :data_directory_path) ||
        raise """
        You have to configure :data_directory_path in config.exs
        ex) config :mini_d3fl, :data_directory_path, "path/to/directory"
        """

    dt_string = Data.datetime_to_string(DateTime.utc_now())
    directory_name = "date_#{dt_string}_#{name}_CalculatorNodeNum_#{node_counts}"
    data_directory_path = Path.join(data_directory_path, directory_name)

    File.mkdir_p!(data_directory_path)
    data_directory_path
  end

  def measure(node_num, name \\ :mnist) when is_atom(name) do
    start = System.monotonic_time(:second)
    data_directory_path = prepare_data_directory!(node_num, name)
    # Mockのスタート

    inner_start(data_directory_path, node_num, name)


    last_time = System.monotonic_time(:second)
    IO.inspect(last_time - start)
    time_file_path = Path.join(data_directory_path, "exec_time.csv")
    {:ok, fp} = File.open(time_file_path, [:append, :utf8])
    IO.write(fp, "#{last_time - start} in sec\n")
    File.close fp
  end

  def inner_start(data_directory_path, node_num, name) do
    %{job_controller_id: job_controller_id, queue: queue} = setup_num(node_num, data_directory_path, name)
    job_executor_id = 0
    JobExecutor.start_link(%JobExcInitArgs{
      job_executor_id: job_executor_id,
      job_controller_id: job_controller_id,
      init_event_queue: queue,
      data_dir_path: data_directory_path
      })
    sample_rate = 0.3
    DataLoader.start_link(
        %DataLoader.DataLoaderInitArgs{
          data_name: name,
          client_num: node_num,
          sample_rate: sample_rate}
        )

    _history = JobExecutor.simulate_execute(0)
  end

  def setup_num(num, data_dir_path, name) do
    setup_compute_node(num, num, data_dir_path, name)
    queue = setup_queue_last(EventQueue.init_queue(), num)
    queue = for i <- 1..(num-1), reduce: queue do
      acc_queue ->
        setup_compute_node(i, num, data_dir_path, name)
        {:ok, _channel_pid} = setup_channel(i, i+1)
        {:ok, _channel_pid} = setup_channel(i+1, i)
        setup_queue_num(acc_queue, i)
    end


    job_controller_id = 0
    {:ok, _pid} = JobController.start_link(
      %{job_controller_id: job_controller_id,
      init_event_queue: queue})
    %{job_controller_id: job_controller_id, queue: queue}
  end

  def setup_queue_last(queue, node_id) do
    queue = Enum.reduce(0..10, queue, fn count, acc_queue ->
      acc_queue
      |> EventQueue.insert_command(%Event{
        time: 5 + 20 * count,
        event_name: :train,
        args: %TrainArgs{node_id: node_id}
      })
      |> EventQueue.insert_command(%Event{
        time: 15 + 20 * count,
        event_name: :train,
        args: %TrainArgs{node_id: node_id}
      })
    end)
    queue
  end

  def setup_queue_num(queue, node_id) do
    # コマンドを挿入
    queue = Enum.reduce(0..10, queue, fn count, acc_queue ->
      acc_queue
      |> EventQueue.insert_command(%Event{
        time: 5 + 20 * count,
        event_name: :train,
        args: %TrainArgs{node_id: node_id}
      })
      |> EventQueue.insert_command(%Event{
        time: 10 + 20 * count,
        event_name: :send,
        args: %SendArgs{
          from_node_id: node_id,
          to_node_id: node_id + 1,
          time: 10 + 20 * count
        }
      })
      |> EventQueue.insert_command(%Event{
        time: 15 + 20 * count,
        event_name: :train,
        args: %TrainArgs{node_id: node_id}
      })
      |> EventQueue.insert_command(%Event{
        time: 20 + 20 * count,
        event_name: :send,
        args: %SendArgs{
          from_node_id: node_id + 1,
          to_node_id: node_id,
          time: 20 + 20 * count
        }
      })
    end)
    queue
  end

  def setup_compute_node(node_id, total_num, data_dir_path, data_name) do
    args = %InitArgs{node_id: node_id,
                      node_num: total_num,
                      data: nil,
                      availability: true,
                      model: %Model{size: 100, plain_model: nil},
                      data_folder: data_dir_path,
                      data_name: data_name
                    }

    {:ok, _pid}  = ComputeNode.start_link(args)
    %{node_id: node_id}
  end

  def setup_channel(from_id, to_id, bandwidth \\ 100) do
    # Channelの初期設定

    input_qos = %Channel.QoS{bandwidth: bandwidth,
                      packetloss: 1,
                      capacity: 10000}

    init_args = %Channel.ChannelArgs{
                  from_cn_id: from_id,
                  to_cn_id: to_id,
                  QoS: input_qos}

    {:ok, _channel_pid} = Channel.start_link(init_args)
  end
end
