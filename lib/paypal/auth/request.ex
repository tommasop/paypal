defmodule Paypal.Auth.Request do
  @moduledoc """
  Paypal requires to have an authenticated token to interact. This module
  helps to generate a token time to time (before it's expired) and ensure
  we have always the correct one.

  Uses lazy config reading - config is read at request time, not at startup,
  allowing runtime configuration.
  """
  require Logger

  defp client do
    Tesla.client(middleware(), adapter())
  end

  defp middleware do
    [
      {Tesla.Middleware.Logger,
       format: "$method $url ===> $status / time=$time", log_level: :debug},
      {Tesla.Middleware.BaseUrl, get_config_url()},
      {Tesla.Middleware.Headers,
       [
         {"content-type", "application/x-www-form-urlencoded"},
         {"accept-language", "en_US"}
       ]},
      {Tesla.Middleware.BasicAuth,
       username: get_config_client_id(), password: get_config_secret()},
      Tesla.Middleware.DecodeJson
    ]
  end

  defp adapter do
    {Tesla.Adapter.Finch, name: Paypal.Finch}
  end

  defp post(uri, body), do: Tesla.post(client(), uri, body)

  @doc """
  Perform the authorization and retrieve the response.

  Only 2xx responses are treated as successful. For any other status the
  raw HTTP status and body are returned as an error so callers can surface
  the real reason (e.g. `invalid_client`) instead of a misleading
  "blank fields" validation error.
  """
  def auth do
    case post("/v1/oauth2/token", "grant_type=client_credentials") do
      {:ok, %_{status: status, body: response}} when status in 200..299 ->
        {:ok, response}

      {:ok, %_{status: status, body: response}} ->
        {:error, %{status: status, body: response}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ============================================================================
  # Lazy Config Reading (like stripity_stripe pattern)
  # ============================================================================
  defp get_config_url do
    Application.get_env(:paypal, :url) ||
      raise ArgumentError, "PayPal URL not configured. Set :url in :paypal config."
  end

  defp get_config_client_id do
    Application.get_env(:paypal, :client_id) ||
      raise ArgumentError, "PayPal client_id not configured. Set :client_id in :paypal config."
  end

  defp get_config_secret do
    Application.get_env(:paypal, :secret) ||
      raise ArgumentError, "PayPal secret not configured. Set :secret in :paypal config."
  end
end
