defmodule Absinthe.Extra.Plug.RelaySignedQueryDocumentProvider do
  @moduledoc """
  Implementation details should be referred to `Absinthe.Plug.DocumentProvider.Compiled`.

  ## Usage

  in `config.ex`, add decoder module

  ```elixir
  config :absinthe_extra, joken: YourJoken
  ```

  in `router.ex`, add this document provider to the pipeline

  ```elixir
  scope "/graphql" do
    forward "/",
            Absinthe.Plug,
            schema: YourSchema,
            document_providers: Absinthe.Extra.Plug.RelaySignedQueryDocumentProvider
  end
  ```
  """

  @behaviour Absinthe.Plug.DocumentProvider

  @compilation_pipeline nil
                        |> Absinthe.Pipeline.for_document(jump_phases: false)
                        |> Absinthe.Pipeline.before(
                          Absinthe.Phase.Document.Variables
                        )
                        |> Absinthe.Pipeline.without(Absinthe.Phase.Telemetry)

  def compilation_pipeline do
    case List.last(@compilation_pipeline) do
      {mod, _} -> mod
      mod -> mod
    end
  end

  @doc false
  @spec pipeline(Absinthe.Plug.Request.Query.t()) :: Absinthe.Pipeline.t()
  def pipeline(%{pipeline: as_configured}) do
    remaining_pipeline_marker = compilation_pipeline()

    telemetry_phase =
      {Absinthe.Phase.Telemetry, event: [:execute, :operation, :start]}

    as_configured
    |> Absinthe.Pipeline.from(remaining_pipeline_marker)
    |> Absinthe.Pipeline.insert_before(
      remaining_pipeline_marker,
      telemetry_phase
    )
  end

  @doc false
  @spec process(Absinthe.Plug.Request.Query.t(), Keyword.t()) ::
          Absinthe.Plug.DocumentProvider.result()
  def process(%{document: _} = request, _) do
    do_process(request)
  end

  defp do_process(%{params: %{"doc_id" => document_key}} = request) do
    joken = Application.fetch_env!(:absinthe_extra, :joken)

    case joken.verify_and_validate(document_key) do
      {:error, _error} ->
        {:cont, request}

      {:ok, %{"query" => document_text}} ->
        case Absinthe.Pipeline.run(document_text, @compilation_pipeline) do
          {:ok, document, _} ->
            {:halt,
             %{
               request
               | document: document,
                 document_provider_key: document_key
             }}

          {:error, _message, _} ->
            {:cont, request}
        end
    end
  end

  defp do_process(request) do
    {:cont, request}
  end
end
