defmodule Paypal.Webhook.Event do
  @moduledoc """
  Schema for PayPal webhook events.

  This module defines the structure for webhook event payloads sent by PayPal.
  Events contain information about what happened (event_type) and the resource
  that was affected.
  """
  use TypedEctoSchema

  alias Paypal.Common.Link

  @primary_key false

  @typedoc """
  The information for a webhook event:

  - `id` is the unique identifier for the event
  - `create_time` is when the event occurred
  - `resource_type` indicates the type of resource (order, payment, etc.)
  - `event_type` specifies what happened (e.g., "PAYMENT.CAPTURE.COMPLETED")
  - `summary` is a human-readable description of the event
  - `resource` contains the actual data for the affected resource
  - `links` are HATEOAS links related to the event
  """
  typed_embedded_schema do
    field(:id, :string)
    field(:create_time, :utc_datetime)
    field(:resource_type, :string)
    field(:event_type, :string)
    field(:summary, :string)
    # Dynamic based on event type
    field(:resource, :map)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  @doc """
  Parses a webhook event from raw parameters.

  This function takes the raw webhook payload and converts it into
  a structured Event.
  """
  @spec parse(map()) :: {:ok, t()} | {:error, term()}
  def parse(params) when is_map(params) do
    # Validate that this looks like a webhook event
    cond do
      Map.has_key?(params, "event_type") ->
        try do
          {:ok, cast(params)}
        rescue
          e -> {:error, e}
        end

      true ->
        {:error, :invalid_webhook_event}
    end
  end

  def parse(_), do: {:error, :invalid_input}

  @doc """
  Returns true if the event is related to payments.
  """
  @spec payment_event?(t()) :: boolean()
  def payment_event?(%__MODULE__{event_type: event_type}) do
    String.starts_with?(event_type, "PAYMENT.")
  end

  @doc """
  Returns true if the event is related to orders.
  """
  @spec order_event?(t()) :: boolean()
  def order_event?(%__MODULE__{event_type: event_type}) do
    String.starts_with?(event_type, "CHECKOUT.ORDER.")
  end

  @doc """
  Returns true if the event is related to disputes.
  """
  @spec dispute_event?(t()) :: boolean()
  def dispute_event?(%__MODULE__{event_type: event_type}) do
    String.starts_with?(event_type, "CUSTOMER.DISPUTE.")
  end

  @doc """
  Returns true if the event is related to subscriptions.
  """
  @spec subscription_event?(t()) :: boolean()
  def subscription_event?(%__MODULE__{event_type: event_type}) do
    String.starts_with?(event_type, "BILLING.SUBSCRIPTION.")
  end

  @doc """
  Returns true if the event is related to payouts.
  """
  @spec payout_event?(t()) :: boolean()
  def payout_event?(%__MODULE__{event_type: event_type}) do
    String.starts_with?(event_type, "PAYMENT.PAYOUTS")
  end
end
