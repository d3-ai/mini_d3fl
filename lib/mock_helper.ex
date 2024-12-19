defmodule MockHelper do
  use MiniD3fl.Aliases

  def prepare_data_directory!(node_counts, name, method \\ nil) do
    data_directory_path =
      Application.get_env(:mini_d3fl, :data_directory_path) ||
        raise """
        You have to configure :data_directory_path in config.exs
        ex) config :mini_d3fl, :data_directory_path, "path/to/directory"
        """

    dt_string = Data.datetime_to_string(DateTime.utc_now())
    directory_name = "#{method}_date_#{dt_string}_#{name}_CN_Num_#{node_counts}"
    data_directory_path = Path.join(data_directory_path, directory_name)

    File.mkdir_p!(data_directory_path)
    data_directory_path
  end
end
