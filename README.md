# MiniD3fl[Work in Progress]

MiniD3flは、非中央集権型連合学習のシミュレーションを行うElixirベースのプロジェクトです。このプロジェクトは現在進行中です。

## 概要

MiniD3flは、以下の４つの観点を満たす非中央集権型連合学習のシミュレーターです。：

- スケーラビリティ（クライアント数）
- 通信品質の反映（帯域幅、パケットロスなど）
- クライアントの可用性
- 非同期な学習

## TODO
コード内に'#TODO'と書かれている部分を参照のこと。
- [ ] **Mock（サンプル例）を簡単に描けるようにする（keyがnodeid であるchannel pidの辞書をexecutorに作成、イベント指定の時間指定の重複をなくす）**
- [ ] **サンプルを高度化（ノードが一列、ランダム、スター、リング）**
- [ ] **Supervised Treeの追加**

### バグ修正

- （動作検証段階であり、今後追加予定）

## インストール

このプロジェクトをローカルにインストールするには、以下の手順に従ってください：

1. **リポジトリをクローン**：

   ```bash
   git clone https://github.com/your_username/mini_d3fl.git
   cd mini_d3fl

  
2. **Elixirなどのインストール**
    - install [elixir](https://elixir-lang.org/install.html)
    - ```bash
      mix deps.get
      ```

3. **Run the Simulator Sample [WIP]:**
   - ```bash
      mix test test/mini_d3fl/job_executor_test.exs
      ```
   
