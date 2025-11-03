defmodule Paypal.Webhook do
  @moduledoc """
  PayPal webhook management for receiving real-time notifications about payment events.

  Webhooks allow your application to be notified when events happen, such as:
  - Payment captures completed
  - Orders approved
  - Refunds processed
  - Disputes opened

  ## Usage

  ### Creating a Webhook
  ```elixir
  {:ok, webhook} = Paypal.Webhook.create(%{
    url: "https://myapp.com/webhooks/paypal",
    event_types: ["PAYMENT.CAPTURE.COMPLETED", "CHECKOUT.ORDER.APPROVED"]
  })
  ```

  ### Listing Webhooks
  ```elixir
  {:ok, webhooks} = Paypal.Webhook.list()
  ```

  ### Verifying Webhook Signatures
  ```elixir
  # In your Phoenix controller
  def handle_webhook(conn, params) do
    headers = Enum.into(conn.req_headers, %{})
    case Paypal.Webhook.verify_signature(params, headers) do
      {:ok, :verified} ->
        # Process the webhook
        handle_event(params)
        send_resp(conn, 200, "OK")
      {:error, reason} ->
        send_resp(conn, 400, "Invalid signature")
    end
  end
  ```
  """

  require Logger

  alias Paypal.Auth
  alias Paypal.Common.Error, as: WebhookError
  alias Paypal.Webhook.Create
  alias Paypal.Webhook.Info
  alias Paypal.Webhook.Event
  alias Paypal.Webhook.Verification

  defp client do
    Tesla.client(middleware(), adapter())
  end

  defp middleware do
    [
      {Tesla.Middleware.Logger,
       format: "$method /v1/notifications$url ===> $status / time=$time", log_level: :debug},
      {Tesla.Middleware.BaseUrl, Application.get_env(:paypal, :url) <> "/v1/notifications"},
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
  defp post(uri, body), do: Tesla.post(client(), uri, body)
  defp patch(uri, body), do: Tesla.patch(client(), uri, body)
  defp delete_request(uri), do: Tesla.delete(client(), uri)

  @doc """
  Create a new webhook.

  ## Parameters
  - `params` - Map containing:
    - `url` (required): HTTPS URL for webhook notifications
    - `event_types` (required): List of event types to subscribe to

  ## Examples
  ```elixir
  Paypal.Webhook.create(%{
    url: "https://myapp.com/webhooks/paypal",
    event_types: ["PAYMENT.CAPTURE.COMPLETED"]
  })
  ```
  """
  @spec create(map()) :: {:ok, Info.t()} | {:error, WebhookError.t() | Ecto.Changeset.t()}
  def create(params) do
    with {:ok, validated_params} <-
           Create.changeset(%Create{}, params) |> Ecto.Changeset.apply_action(:insert),
         {:ok, %_{status: code, body: response}} when code in 200..299 <-
           post("/webhooks", Map.from_struct(validated_params)) do
      {:ok, Info.cast(response)}
    else
      {:error, changeset} ->
        {:error, changeset}

      {:ok, %_{body: response}} ->
        {:error, WebhookError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  List all webhooks for the application.
  """
  @spec list() :: {:ok, [Info.t()]} | {:error, WebhookError.t()}
  def list do
    case get("/webhooks") do
      {:ok, %_{status: 200, body: %{"webhooks" => webhooks}}} ->
        {:ok, Enum.map(webhooks, &Info.cast/1)}

      {:ok, %_{body: response}} ->
        {:error, WebhookError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Get details for a specific webhook.
  """
  @spec show(String.t()) :: {:ok, Info.t()} | {:error, WebhookError.t()}
  def show(webhook_id) do
    case get("/webhooks/#{webhook_id}") do
      {:ok, %_{status: 200, body: response}} ->
        {:ok, Info.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, WebhookError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Update a webhook.

  ## Parameters
  - `webhook_id` - The ID of the webhook to update
  - `params` - Map containing fields to update (url, event_types, status)
  """
  @spec update(String.t(), map()) ::
          {:ok, Info.t()} | {:error, WebhookError.t() | Ecto.Changeset.t()}
  def update(webhook_id, params) do
    # Basic validation - allow updating url, event_types, or status
    allowed_fields = [:url, :event_types, :status]
    filtered_params = Map.take(params, allowed_fields)

    if filtered_params == %{} do
      {:error, "No valid fields to update"}
    else
      case patch("/webhooks/#{webhook_id}", filtered_params) do
        {:ok, %_{status: code, body: response}} when code in 200..299 ->
          {:ok, Info.cast(response)}

        {:ok, %_{body: response}} ->
          {:error, WebhookError.cast(response)}

        {:error, _} = error ->
          error
      end
    end
  end

  @doc """
  Delete a webhook.
  """
  @spec delete(String.t()) :: :ok | {:error, WebhookError.t()}
  def delete(webhook_id) do
    case delete_request("/webhooks/#{webhook_id}") do
      {:ok, %_{status: 204}} ->
        :ok

      {:ok, %_{status: code, body: response}} when code in 200..299 ->
        :ok

      {:ok, %_{body: response}} ->
        {:error, WebhookError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Verify a webhook signature to ensure authenticity.

  This function takes the webhook payload and signature headers from PayPal
  and verifies that the webhook is genuine.

  ## Parameters
  - `webhook_body` - The raw webhook payload
  - `signature_headers` - Map of headers containing signature information:
    - `paypal-auth-algo`
    - `paypal-cert-url`
    - `paypal-transmission-id`
    - `paypal-transmission-sig`
    - `paypal-transmission-time`

  ## Examples
  ```elixir
  headers = %{
    "paypal-auth-algo" => "SHA256withRSA",
    "paypal-cert-url" => "https://api.paypal.com/v1/notifications/certs/...",
    "paypal-transmission-id" => "transmission-id",
    "paypal-transmission-sig" => "signature",
    "paypal-transmission-time" => "timestamp"
  }

  case Paypal.Webhook.verify_signature(webhook_body, headers) do
    {:ok, :verified} -> # Valid webhook
    {:error, reason} -> # Invalid webhook
  end
  ```
  """
  @spec verify_signature(map(), map()) :: {:ok, :verified} | {:error, term()}
  def verify_signature(webhook_body, headers) do
    # Extract signature components from headers
    verification_request = %{
      auth_algo: headers["paypal-auth-algo"],
      cert_url: headers["paypal-cert-url"],
      transmission_id: headers["paypal-transmission-id"],
      transmission_sig: headers["paypal-transmission-sig"],
      transmission_time: headers["paypal-transmission-time"],
      webhook_id: headers["paypal-webhook-id"],
      webhook_event: webhook_body
    }

    case Verification.Request.changeset(%Verification.Request{}, verification_request)
         |> Ecto.Changeset.apply_action(:insert) do
      {:ok, validated_request} ->
        case post("/verify-webhook-signature", Map.from_struct(validated_request)) do
          {:ok, %_{status: 200, body: %{"verification_status" => "SUCCESS"}}} ->
            {:ok, :verified}

          {:ok, %_{status: 200, body: %{"verification_status" => "FAILURE"}}} ->
            {:error, :invalid_signature}

          {:ok, %_{body: response}} ->
            {:error, WebhookError.cast(response)}

          {:error, _} = error ->
            error
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Parse a webhook event from raw parameters.

  This is a convenience function that wraps `Paypal.Webhook.Event.parse/1`.
  """
  @spec parse_event(map()) :: {:ok, Event.t()} | {:error, term()}
  def parse_event(params) do
    Event.parse(params)
  end
end
