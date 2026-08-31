defmodule Paypal.Vault do
  @moduledoc """
  PayPal Vault API (v1): create and delete payment tokens.

  Payment tokens let you charge a customer later without re-collecting their
  payment details. See https://developer.paypal.com/docs/vault/.
  """

  alias Paypal.Auth
  alias Paypal.Common.Error, as: VaultError

  defp client do
    Tesla.client(middleware(), adapter())
  end

  defp middleware do
    [
      {Tesla.Middleware.Logger,
       format: "$method /v1/vault$url ===> $status / time=$time", log_level: :debug},
      {Tesla.Middleware.BaseUrl, Application.get_env(:paypal, :url) <> "/v1/vault"},
      {Tesla.Middleware.Headers,
       [
         {"content-type", "application/json"},
         {"accept-language", "en_US"},
         {"authorization", "bearer #{Auth.get_token!()}"}
       ]},
      Tesla.Middleware.JSON
    ]
  end

  defp adapter do
    {Tesla.Adapter.Finch, name: Paypal.Finch}
  end

  @doc """
  Creates a payment token from a payment source.

  The `payment_source` shape is defined by the caller (card, PayPal account, or
  a previously approved token). Pass a `request_id` for idempotency.
  """
  @spec create_payment_token(map(), String.t() | nil) ::
          {:ok, map()} | {:error, VaultError.t() | String.t()}
  def create_payment_token(payment_source, request_id \\ nil) do
    body = %{"payment_source" => payment_source}

    case post("/payment-tokens", body, request_id) do
      {:ok, %_{status: code, body: response}} when code in 200..299 ->
        {:ok, response}

      {:ok, %_{body: response}} ->
        {:error, VaultError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Deletes a payment token by id.
  """
  @spec delete_payment_token(String.t(), String.t() | nil) ::
          :ok | {:error, VaultError.t() | String.t()}
  def delete_payment_token(id, request_id \\ nil) do
    case delete("/payment-tokens/#{id}", request_id) do
      {:ok, %_{status: code}} when code in 200..299 ->
        :ok

      {:ok, %_{body: response}} ->
        {:error, VaultError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  defp post(uri, body, request_id) do
    headers = maybe_request_id(request_id)
    Tesla.post(client(), uri, body, headers: headers)
  end

  defp delete(uri, request_id) do
    headers = maybe_request_id(request_id)
    Tesla.delete(client(), uri, headers: headers)
  end

  defp maybe_request_id(nil), do: []
  defp maybe_request_id(request_id), do: [{"PayPal-Request-Id", request_id}]
end
