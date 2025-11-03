defmodule Paypal.Payment do
  @moduledoc """
  Perform payment actions for Paypal. The payments are authorized orders.
  You can see further information via `Paypal.Order`.
  """
  require Logger

  alias Paypal.Auth
  alias Paypal.Common.Error, as: PaymentError
  alias Paypal.Payment.Captured
  alias Paypal.Payment.CaptureRequest
  alias Paypal.Payment.Info
  alias Paypal.Payment.ReauthorizeRequest
  alias Paypal.Payment.Refund
  alias Paypal.Payment.RefundRequest

  defp client do
    Tesla.client(middleware(), adapter())
  end

  defp middleware do
    [
      {Tesla.Middleware.Logger,
       format: "$method /v2/payments$url ===> $status / time=$time", log_level: :debug},
      {Tesla.Middleware.BaseUrl, Application.get_env(:paypal, :url) <> "/v2/payments"},
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

  defp get(uri), do: Tesla.get(client(), uri)
  defp post(uri, body, opts \\ []), do: Tesla.post(client(), uri, body, opts)

  @doc """
  Show information about the authorized order.
  """
  def show(id) do
    case get("/authorizations/#{id}") do
      {:ok, %_{status: 200, body: response}} ->
        {:ok, Info.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Void the authorized order. It's a way for cancel or return the blocked
  or authorized fonds.
  """
  def void(id) do
    case post("/authorizations/#{id}/void", "") do
      {:ok, %_{status: code, body: ""}} when code in 200..299 ->
        :ok

      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Capture the authorized order. It's the final step to perform a payment with
  an authorized order.

  ## Arguments

    - `id` - The authorization ID.
    - `body` - The request body with optional parameters.
    - `headers` - Additional headers to send with the request.

  ## Optional Parameters

    - `invoice_id` - The API caller-provided external invoice number for this order.
    - `note_to_payer` - An informational note about this settlement.
    - `final_capture` - Indicates whether you can make additional captures against the authorized payment.
    - `payment_instruction` - Any additional payment instructions to be consider during payment processing.
    - `soft_descriptor` - The payment descriptor on the payer's account statement.
    - `amount` - The amount to capture. If not specified, the full authorized amount is captured.

  ## Optional Headers

    - `PayPal-Request-Id` - A unique ID for the request.
    - `Prefer` - Indicates the preferred response format.
    - `PayPal-Auth-Assertion` - An assertion for the request.
  """
  def capture(id, body \\ %{}, headers \\ []) do
    with {:ok, data} <- CaptureRequest.changeset(body) do
      case post("/authorizations/#{id}/capture", data, headers: headers) do
        {:ok, %_{status: code, body: response}} when code in 200..299 ->
          {:ok, Captured.cast(response)}

        {:ok, %_{body: response}} ->
          {:error, PaymentError.cast(response)}

        {:error, _} = error ->
          error
      end
    end
  end

  @doc """
  Performs a refund of the capture that was captured previously.
  """
  def refund(id, body \\ %{}) do
    with {:ok, data} <- RefundRequest.changeset(body),
         {:ok, %_{status: code, body: response}} when code in 200..299 <-
           post("/captures/#{id}/refund", data) do
      {:ok, Refund.cast(response)}
    else
      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Reauthorizes an authorized payment, by ID. To ensure that funds are still available,
  reauthorize a payment after its initial three-day honor period expires.
  """
  def reauthorize(id, body \\ %{}) do
    with {:ok, data} <- ReauthorizeRequest.changeset(body),
         {:ok, %_{status: code, body: response}} when code in 200..299 <-
           post("/authorizations/#{id}/reauthorize", data) do
      {:ok, Info.cast(response)}
    else
      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Shows details for a captured payment, by ID.
  """
  def show_capture(id) do
    case get("/captures/#{id}") do
      {:ok, %_{status: 200, body: response}} ->
        {:ok, Captured.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Shows details for a refund, by ID.
  """
  def show_refund(id) do
    case get("/refunds/#{id}") do
      {:ok, %_{status: 200, body: response}} ->
        {:ok, Refund.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
