defmodule Paypal.Webhook.Create do
  @moduledoc """
  Schema for creating a new PayPal webhook.

  This module defines the structure for webhook creation requests,
  including the URL and event types to subscribe to.
  """
  use TypedEctoSchema

  @primary_key false

  @typedoc """
  The information required to create a webhook:

  - `url` is the HTTPS URL where PayPal will send webhook notifications
  - `event_types` is a list of event types the webhook should subscribe to
  """
  typed_embedded_schema do
    field(:url, :string)
    field(:event_types, {:array, :string})
  end

  @doc false
  def changeset(struct, params) do
    struct
    |> Ecto.Changeset.cast(params, [:url, :event_types])
    |> Ecto.Changeset.validate_required([:url, :event_types])
    |> Ecto.Changeset.validate_format(:url, ~r/^https:\/\//,
      message: "webhook URL must use HTTPS"
    )
    |> Ecto.Changeset.validate_length(:event_types,
      min: 1,
      message: "at least one event type is required"
    )
  end
end
